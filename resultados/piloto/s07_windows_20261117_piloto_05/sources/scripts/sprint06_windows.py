"""Exploratory S6 Windows evidence only; does not implement the S7 campaign.

Standard library + MSVC/MS-MPI/Go. Performance runs have no memory sampler;
separate profiling runs use Windows process counters at a requested 20 ms.
Original stdout/stderr, plans, hashes, failures and source snapshots survive.
"""
import argparse
import csv
import ctypes as C
from ctypes import wintypes as W
from datetime import datetime, timezone
import hashlib
import io
import json
import math
import os
from pathlib import Path
import shutil
import subprocess as S
import time

ROOT = Path(__file__).resolve().parents[1]
VERSIONS = ('c_secuencial', 'c_paralelo', 'go_secuencial', 'go_paralelo')


def dump(path, data):
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def command(args, cwd=ROOT, env=None, timeout=600):
    p = S.run(list(map(str, args)), cwd=cwd, env=env, capture_output=True, timeout=timeout)
    return dict(command=list(map(str, args)), exit_code=p.returncode,
                stdout=p.stdout.decode('utf-8', errors='replace'),
                stderr=p.stderr.decode('utf-8', errors='replace'))


def checked(args, log, cwd=ROOT):
    result = command(args, cwd)
    dump(log, result)
    if result['exit_code']:
        raise RuntimeError(f'Build/check failed: {log}')
    return result


class Memory:
    """Handles retained until after exit preserve OS PeakWorkingSetSize."""
    def __init__(self):
        self.k = C.WinDLL('kernel32', use_last_error=True)
        self.p = C.WinDLL('psapi', use_last_error=True)
        self.k.OpenProcess.argtypes = [W.DWORD, W.BOOL, W.DWORD]
        self.k.OpenProcess.restype = W.HANDLE
        self.k.CloseHandle.argtypes = [W.HANDLE]
        self.k.CreateToolhelp32Snapshot.argtypes = [W.DWORD, W.DWORD]
        self.k.CreateToolhelp32Snapshot.restype = W.HANDLE
        self.k.QueryFullProcessImageNameW.argtypes = [W.HANDLE, W.DWORD, W.LPWSTR, C.POINTER(W.DWORD)]
        self.k.GetProcessAffinityMask.argtypes = [W.HANDLE, C.POINTER(C.c_size_t), C.POINTER(C.c_size_t)]
        class Entry(C.Structure):
            _fields_ = [('size',W.DWORD),('usage',W.DWORD),('pid',W.DWORD),
                        ('heap',C.c_size_t),('module',W.DWORD),('threads',W.DWORD),
                        ('parent',W.DWORD),('priority',W.LONG),('flags',W.DWORD),('exe',W.WCHAR*260)]
        class Counters(C.Structure):
            _fields_ = [('cb',W.DWORD),('faults',W.DWORD)] + [(name,C.c_size_t) for name in
                ('peak_ws','ws','peak_paged','paged','peak_nonpaged','nonpaged','pagefile','peak_pagefile','private')]
        self.Entry, self.Counters = Entry, Counters
        self.k.Process32FirstW.argtypes = [W.HANDLE, C.POINTER(Entry)]
        self.k.Process32NextW.argtypes = [W.HANDLE, C.POINTER(Entry)]
        self.p.GetProcessMemoryInfo.argtypes = [W.HANDLE,C.POINTER(Counters),W.DWORD]

    def processes(self, executable):
        snap = self.k.CreateToolhelp32Snapshot(2,0)
        if snap == C.c_void_p(-1).value:
            raise C.WinError(C.get_last_error())
        entry = self.Entry(); entry.size = C.sizeof(entry)
        found = []
        try:
            ok = self.k.Process32FirstW(snap,C.byref(entry))
            while ok:
                if entry.exe.lower() == executable.name.lower():
                    handle = self.k.OpenProcess(0x410,False,entry.pid)
                    if handle:
                        buf = C.create_unicode_buffer(32768); length = W.DWORD(len(buf))
                        if self.k.QueryFullProcessImageNameW(handle,0,buf,C.byref(length)) and Path(buf.value) == executable:
                            found.append(entry.pid)
                        self.k.CloseHandle(handle)
                ok = self.k.Process32NextW(snap,C.byref(entry))
        finally:
            self.k.CloseHandle(snap)
        return found

    def sample(self, pid, handle):
        counters = self.Counters(); counters.cb = C.sizeof(counters)
        if not self.p.GetProcessMemoryInfo(handle,C.byref(counters),counters.cb):
            return None
        mask, system = C.c_size_t(), C.c_size_t()
        self.k.GetProcessAffinityMask(handle,C.byref(mask),C.byref(system))
        return dict(pid=pid,working_set_bytes=counters.ws,peak_working_set_bytes=counters.peak_ws,
                    private_bytes=counters.private,process_affinity_mask=mask.value,
                    system_affinity_mask=system.value)


def profile(args, executable, env, directory, timeout=180):
    sampler = Memory()
    if sampler.processes(executable):
        raise RuntimeError('Another instance is running; memory profile requires isolation')
    handles, peaks, samples = {}, {}, []
    started = time.monotonic()
    with (directory/'stdout.txt').open('wb') as out, (directory/'stderr.txt').open('wb') as err:
        process = S.Popen(list(map(str,args)),cwd=ROOT,env=env,stdout=out,stderr=err)
        timed_out = False
        try:
            while process.poll() is None:
                live_pids = sampler.processes(executable)
                for pid in live_pids:
                    if pid not in handles:
                        handle = sampler.k.OpenProcess(0x410,False,pid)
                        if handle:
                            handles[pid] = handle
                current = []
                for pid,handle in handles.items():
                    if pid not in live_pids:
                        continue
                    value = sampler.sample(pid,handle)
                    if value:
                        current.append(value)
                        previous = peaks.get(pid,dict(peak_working_set_bytes=0,private_bytes_sampled_max=0))
                        peaks[pid] = value | dict(peak_working_set_bytes=max(previous['peak_working_set_bytes'],value['peak_working_set_bytes']),
                            private_bytes_sampled_max=max(previous['private_bytes_sampled_max'],value['private_bytes']))
                samples.append(dict(elapsed_s=time.monotonic()-started,processes=current,
                                    simultaneous_working_set_bytes=sum(v['working_set_bytes'] for v in current),
                                    simultaneous_private_bytes=sum(v['private_bytes'] for v in current)))
                if time.monotonic()-started > timeout:
                    timed_out = True
                    command(['taskkill','/PID',process.pid,'/T','/F'])
                    for pid in sampler.processes(executable):
                        command(['taskkill','/PID',pid,'/T','/F'])
                    break
                time.sleep(.02)
            process.wait(timeout=10)
            for pid,handle in handles.items():
                value = sampler.sample(pid,handle)
                if value and pid in peaks:
                    peaks[pid]['peak_working_set_bytes'] = max(peaks[pid]['peak_working_set_bytes'],value['peak_working_set_bytes'])
        finally:
            if process.poll() is None:
                command(['taskkill','/PID',process.pid,'/T','/F'])
            for handle in handles.values():
                sampler.k.CloseHandle(handle)
    dump(directory/'samples.json',samples)
    result = dict(command=list(map(str,args)),exit_code=process.returncode,timed_out=timed_out,
                  wall_s=time.monotonic()-started,processes=list(peaks.values()),
                  max_simultaneous_working_set_bytes=max((s['simultaneous_working_set_bytes'] for s in samples),default=0),
                  max_simultaneous_private_bytes=max((s['simultaneous_private_bytes'] for s in samples),default=0),
                  remaining_pids=sampler.processes(executable),sample_count=len(samples),
                  maximum_sample_gap_s=max((b['elapsed_s']-a['elapsed_s'] for a,b in zip(samples,samples[1:])),default=0))
    dump(directory/'memory.json',result)
    return result


def build(out):
    binaries = {}
    work = ROOT/'.cache/s06-windows-build'; work.mkdir(parents=True,exist_ok=True)
    for version,module,extra in [('c_secuencial','c_secuencial',[]),('c_openmp_local','c_paralelo',['/openmp','/DS06_OPENMP'])]:
        binary = work/(version+'.exe')
        args = ['cl','/nologo','/TC','/std:c11','/O2','/MD','/fp:precise','/W4',*extra,
                '/I'+str(ROOT/module/'include'),str(ROOT/'tests/sprint06_kernel_bench.c'),
                str(ROOT/'tests/sprint06_candidates.c'),str(ROOT/module/'src/matrix.c'),
                str(ROOT/module/'src/input.c'),'/Fe:'+str(binary),'/link','/MACHINE:X64']
        checked(args,out/(version+'-build.json'),work)
        binaries[version] = str(binary)
    for version in VERSIONS[2:]:
        binary = work/(version+'.test.exe')
        checked(['go','test','-c','-o',binary,'.'],out/(version+'-build.json'),ROOT/version)
        binaries[version] = str(binary)
    dump(out/'laboratory-binaries.json',{k:dict(path=v,sha256=digest(Path(v))) for k,v in binaries.items()})
    return binaries


def summarize(rows):
    groups = {}
    for row in rows:
        key = (row['kind'],row['version'],row['variant'],row['n'],row['workers'],row.get('processes',1),row.get('threads',1))
        groups.setdefault(key,[]).append(row)
    summary=[]
    for key,group in groups.items():
        item = dict(zip(('kind','version','variant','n','workers','processes','threads'),key))
        complete = len(group)==6 and sorted(r['repetition'] for r in group)==list(range(6)) and all(r['status']=='OK' for r in group)
        item['status']='COMPLETE' if complete else 'INCOMPLETE'
        if complete:
            for field in ('kernel_s','total_s','wall_s'):
                values=sorted(r[field] for r in group if r['repetition'])
                item.update({field+'_median':values[2],field+'_iqr':values[3]-values[1],field+'_min':values[0],field+'_max':values[4]})
        summary.append(item)
    return summary


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--output',required=True)
    parser.add_argument('--run',action='store_true')
    args=parser.parse_args()
    if os.name!='nt': raise SystemExit('Native Windows required')
    out=(ROOT/args.output).resolve()
    out.mkdir(parents=True,exist_ok=True)
    if (out/'observations.jsonl').exists(): raise SystemExit('Existing observations: choose a fresh output directory')
    environment=command(['powershell','-NoProfile','-Command',
        "$cpu=Get-CimInstance Win32_Processor; $os=Get-CimInstance Win32_OperatingSystem; [ordered]@{cpu=$cpu.Name;physical_cores=($cpu|Measure-Object NumberOfCores -Sum).Sum;logical_processors=($cpu|Measure-Object NumberOfLogicalProcessors -Sum).Sum;os=$os.Caption;build=$os.Version;ram_visible_bytes=[long]$os.TotalVisibleMemorySize*1024;ram_available_bytes=[long]$os.FreePhysicalMemory*1024;power_plan=(powercfg /getactivescheme);battery=@(Get-CimInstance Win32_Battery|Select-Object BatteryStatus,EstimatedChargeRemaining)}|ConvertTo-Json -Depth 5"])
    hardware=json.loads(environment['stdout'])
    budgets=[w for w in (1,2,4) if w<=hardware['physical_cores']]
    if budgets != [1,2,4]: raise RuntimeError('Review the plan for this smaller CPU')
    git=command(['git','rev-parse','HEAD'])['stdout'].strip()
    snapshot={}
    for directory in (*VERSIONS,'tests','scripts'):
        for source in (ROOT/directory).rglob('*'):
            if source.is_file() and source.suffix in ('.go','.mod','.c','.h','.py','.ps1') and not any(x in source.parts for x in ('build','__pycache__')):
                relative=source.relative_to(ROOT); destination=out/'sources'/relative
                destination.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(source,destination)
                snapshot[str(relative).replace('\\','/')]=digest(source)
    dump(out/'source-hashes.json',snapshot)
    dump(out/'tracked-diff.json',command(['git','diff','HEAD']))
    manifest=dict(protocol_version='1.3',phase='S6 exploratory Windows, not S7/S8',started_at_utc=datetime.now(timezone.utc).isoformat(),
                  git_commit=git,git_status=command(['git','status','--short'])['stdout'],hardware=hardware,
                  tools={name:command(cmd) for name,cmd in [('msvc',['cl']),('go',['go','version']),('mpi',[str(Path(os.environ['ProgramFiles'])/'Microsoft MPI/Bin/mpiexec.exe'),'-help']),('git',['git','--version'])]},
                  windows_sdk=os.getenv('WindowsSDKVersion'),msvc_tools=os.getenv('VCToolsVersion'),
                  power_source='Battery query recorded; desktop AC inferred if no battery, not directly instrumented',
                  thermal_load='Desktop active; no thermal sensor/background-load control; exploratory only',
                  configuration='Release x64',sampling='Separate profiles: GetProcessMemoryInfo, bytes, requested interval 20 ms; individual OS peak WS, sampled private maxima and simultaneous sums; actual maximum gap recorded',
                  timeout_seconds=180,machine_budget_seconds=7200,excluded=['W=8 exceeds 6 physical cores','N=2048/4096 excluded from exploratory repetitions: independent O(N^3) reference wall-time budget; RAM model assessed separately'])
    dump(out/'environment.json',manifest)
    cases=[]
    for n in (256,512,1024):
        for version,variants,ws in [('c_secuencial',('baseline','restrict_c'),[1]),('c_openmp_local',('baseline','static1'),budgets),('go_secuencial',('baseline','row_slices'),[1]),('go_paralelo',('baseline','block16','unbuffered'),budgets)]:
            for w in ws:
                for variant in variants:
                    cases.append(dict(kind='laboratory',version=version,variant=variant,n=n,workers=w))
        for version in VERSIONS:
            configs=[(1,1,1)]
            if version=='go_paralelo': configs=[(1,1,w) for w in budgets]
            if version=='c_paralelo': configs=[(1,1,1),(1,2,2),(2,1,2),(1,4,4),(2,2,4),(4,1,4)]
            for p,t,w in configs:
                cases.append(dict(kind='program',version=version,variant='baseline',n=n,workers=w,processes=p,threads=t))
    plan=[case|dict(repetition=r,execution_order=i) for i,(r,case) in enumerate(((r,c) for r in range(6) for c in (cases if r%2 else list(reversed(cases)))),1)]
    dump(out/'plan.json',plan)
    (out/'bitacora.txt').write_text('Plan saved before measurement. One warmup and five alternating rounds. No concurrent benchmark. Performance has no memory sampler.\n',encoding='utf-8')
    if not args.run:
        print(f'Plan: {len(plan)} runs; {out}',flush=True); return
    binaries=build(out)
    mpiexec=str(Path(os.environ['ProgramFiles'])/'Microsoft MPI/Bin/mpiexec.exe')
    program={v:str(ROOT/v/'build/Release'/(v+'.exe')) for v in VERSIONS}
    dump(out/'program-binaries.json',{v:dict(path=p,sha256=digest(Path(p))) for v,p in program.items()})
    rows=[]; start=time.monotonic()
    for case in plan:
        if time.monotonic()-start>7200: raise RuntimeError('Machine budget exceeded; partial evidence retained')
        order=case['execution_order']; run=out/'runs'/f'{order:04d}'; run.mkdir(parents=True)
        version=case['version']; w=case['workers']; r=case['repetition']
        env=os.environ.copy()|dict(OMP_NUM_THREADS=str(case.get('threads',w)),OMP_DYNAMIC='FALSE',GOMAXPROCS=str(w),MPIEXEC_TIMEOUT='180',MPIEXEC_AFFINITY='0',
            S06_N=str(case['n']),S06_WORKERS=str(w),S06_VARIANT=case['variant'],S06_OUTPUT=str(run/'observation.json'))
        env.pop('S06_DIAGNOSTICS',None)
        if case['kind']=='laboratory':
            cmd=[binaries[version],'-test.run=^TestSprint06Observation$','-test.count=1'] if version.startswith('go_') else [binaries[version],str(case['n']),case['variant']]
        else:
            cmd=[program[version],'--n',str(case['n']),'--seed','42','--repetition',str(r)]
            if version=='go_paralelo': cmd+=['--workers',str(w)]
            if version=='c_paralelo': cmd=[mpiexec,'-affinity_layout','0','-n',str(case['processes']),*cmd]
        row=case|dict(status='ERROR',seed=42)
        before=time.monotonic()
        try:
            result=command(cmd,env=env,timeout=190)
            dump(run/'process.json',result)
            (run/'stdout.txt').write_text(result['stdout'],encoding='utf-8')
            (run/'stderr.txt').write_text(result['stderr'],encoding='utf-8')
            row.update(exit_code=result['exit_code'],wall_s=time.monotonic()-before)
            if result['exit_code']: raise ValueError('nonzero exit')
            if case['kind']=='laboratory':
                data=json.loads((run/'observation.json').read_text()) if version.startswith('go_') else json.loads(result['stdout'])
                if data['schema']!='s06-laboratory-v1' or any(data[k]!=case[k] for k in ('version','variant','n','workers')): raise ValueError('identity/schema mismatch')
            else:
                data=list(csv.DictReader(io.StringIO(result['stdout'])))
                if len(data)!=1 or len(data[0])!=20: raise ValueError('CSV shape')
                data=data[0]
                if data['version']!=version or int(data['n'])!=case['n'] or int(data['repetition'])!=r or data['is_warmup']!=str(r==0).lower() or data['commit']!=git: raise ValueError('CSV metadata')
                if version=='go_paralelo' and (int(data['gomaxprocs'])!=w or int(data['workers'])!=w): raise ValueError('workers mismatch')
                if version=='c_paralelo' and (int(data['processes'])!=case['processes'] or int(data['threads'])!=case['threads'] or int(data['observed_threads'])!=case['threads']): raise ValueError('MPI resource mismatch')
            kernel,total=float(data['kernel_s']),float(data['total_s'])
            if data['validation_status']!='OK' or not all(math.isfinite(v) for v in (kernel,total)) or not 0<=kernel<=total: raise ValueError('invalid validation/times')
            row.update(status='OK',kernel_s=kernel,total_s=total,observation=data)
        except (ValueError,OSError,S.TimeoutExpired) as error:
            row.update(reason=str(error),wall_s=time.monotonic()-before)
        rows.append(row)
        with (out/'observations.jsonl').open('a',encoding='utf-8') as f: f.write(json.dumps(row)+'\n')
        if order%10==0 or row['status']!='OK': print(f'{order}/{len(plan)} {version} N={case["n"]} {row["status"]}',flush=True)
    summary=summarize(rows); dump(out/'summary.json',summary)
    fields=sorted(set().union(*(r.keys() for r in summary)))
    with (out/'summary.csv').open('w',newline='',encoding='utf-8') as f:
        writer=csv.DictWriter(f,fields); writer.writeheader(); writer.writerows(summary)
    for case in [c for c in cases if c['kind']=='program']:
        name=f'{case["version"]}_N{case["n"]}_P{case["processes"]}_T{case["threads"]}_W{case["workers"]}'
        directory=out/'memory'/name; directory.mkdir(parents=True)
        env=os.environ.copy()|dict(OMP_NUM_THREADS=str(case['threads']),OMP_DYNAMIC='FALSE',GOMAXPROCS=str(case['workers']),MPIEXEC_TIMEOUT='180',MPIEXEC_AFFINITY='0')
        cmd=[program[case['version']],'--n',str(case['n']),'--seed','42']
        if case['version']=='go_paralelo': cmd+=['--workers',str(case['workers'])]
        if case['version']=='c_paralelo':
            env['S06_DIAGNOSTICS']=str(directory)
            cmd=[mpiexec,'-affinity_layout','0','-n',str(case['processes']),*cmd]
        result=profile(cmd,Path(program[case['version']]),env,directory)
        if result['exit_code'] or result['remaining_pids'] or len(result['processes'])!=case['processes']: raise RuntimeError(f'Invalid memory profile: {name}')
        print('Memory '+name,flush=True)
    dump(out/'completion.json',dict(finished_at_utc=datetime.now(timezone.utc).isoformat(),runs=len(rows),failed=sum(r['status']!='OK' for r in rows),groups=len(summary),incomplete_groups=sum(g['status']!='COMPLETE' for g in summary),wall_s=time.monotonic()-start))
    if any(r['status']!='OK' for r in rows): raise SystemExit(1)


if __name__=='__main__': main()
