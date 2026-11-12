"""Additional S6 diagnostics; run AFTER the sequential performance batch."""
import csv
import io
import json
import os
from pathlib import Path
import sys

import sprint06_windows as lab


def main():
    out = (lab.ROOT / sys.argv[1] / 'verification').resolve()
    out.mkdir(parents=True, exist_ok=True)
    mpi = Path(os.environ['ProgramFiles']) / 'Microsoft MPI/Bin/mpiexec.exe'
    exe = lab.ROOT / 'c_paralelo/build/Release/c_paralelo.exe'
    results = []
    for name,n,p,t,mode in [('remainder',3,2,2,'success'),('empty-rank',2,3,1,'success'),
                             ('invalid-openmp',3,2,2,'error'),('native-timeout',1024,2,2,'timeout'),
                             ('external-timeout',1024,2,2,'external-timeout')]:
        directory = out / name; directory.mkdir(exist_ok=True)
        env = os.environ.copy() | dict(OMP_NUM_THREADS=str(t),OMP_DYNAMIC='FALSE',
            MPIEXEC_AFFINITY='0',MPIEXEC_TIMEOUT='1' if mode=='timeout' else '30',S06_DIAGNOSTICS=str(directory))
        if mode=='error': env['OMP_DYNAMIC']='TRUE'
        command = [str(mpi),'-affinity_layout','0','-n',str(p),str(exe),'--n',str(n),'--seed','42']
        memory = lab.profile(command,exe,env,directory,timeout=.75 if mode=='external-timeout' else 40)
        text = (directory/'stdout.txt').read_text(encoding='utf-8',errors='replace')
        diagnostics = [json.loads(f.read_text()) for f in directory.glob('rank-*.json')]
        if mode=='success':
            rows = list(csv.DictReader(io.StringIO(text)))
            ok = memory['exit_code']==0 and len(rows)==1 and rows[0]['validation_status']=='OK'
            ok = ok and len(diagnostics)==p and sum(r['rows'] for r in diagnostics)==n
            for rank in diagnostics:
                expected_rows=n//p+(rank['rank']<n%p)
                ok = ok and rank['rows']==expected_rows
                ok = ok and rank['timed_observed_threads']==(t if expected_rows else 0)
                ok = ok and (expected_rows!=0 or rank['kernel_s']==0)
                ok = ok and rank['process_affinity_mask'].bit_count()>=t
        else:
            ok = memory['exit_code']!=0 and 'validation_status' not in text and not diagnostics
            if mode=='external-timeout': ok = ok and memory['timed_out']
        ok = ok and not memory['remaining_pids']
        results.append(dict(name=name,status='PASS' if ok else 'FAIL',exit_code=memory['exit_code'],
                            remaining_pids=memory['remaining_pids'],ranks=diagnostics))
        lab.dump(out/'checks.json',results)
        if not ok: raise RuntimeError('Diagnostic failed: '+name)
        print('PASS '+name,flush=True)
    for version in ('go_secuencial','go_paralelo'):
        # These diagnostics are not performance observations. Missing cgo is
        # recorded explicitly; the existing Linux race evidence is retained.
        result=lab.command(['go','test','-race','-count=1','./...'],cwd=lab.ROOT/version)
        lab.dump(out/(version+'-race.json'),result)
        result=lab.checked(['go','test','-count=3','-timeout=120s','./...'],out/(version+'-stability.json'),lab.ROOT/version)
    result=lab.checked(['go','test','-count=1','-v','-run','^TestPreciseClockResolution$','.'],out/'clock-resolution.json',lab.ROOT/'go_paralelo')
    env=os.environ.copy() | dict(GO_GRANULARITY_N='17',GO_GRANULARITY_W='1,2',GO_GRANULARITY_REPETITIONS='5',GO_GRANULARITY_CSV=str(out/'granularity-corrected.csv'))
    result=lab.command(['go','test','-count=1','-v','-run','^TestGranularityExperiment$','.'],cwd=lab.ROOT/'go_paralelo',env=env)
    lab.dump(out/'granularity-corrected-process.json',result)
    if result['exit_code']: raise RuntimeError('Corrected granularity experiment failed')
    corrected=list(csv.DictReader((out/'granularity-corrected.csv').open()))
    if len(corrected)!=72 or any(not 0<=float(r['kernel_s'])<=float(r['total_s']) for r in corrected):
        raise RuntimeError('Corrected granularity CSV violates timing invariants')
    original=list(csv.DictReader((lab.ROOT/'resultados/experimentos/granularidad_go/granularidad_go.csv').open()))
    lab.dump(out/'granularity-historical-audit.json',dict(rows=len(original),
        kernel_over_total=sum(float(r['kernel_s'])>float(r['total_s']) for r in original),
        source_sha256=lab.digest(lab.ROOT/'resultados/experimentos/granularidad_go/granularidad_go.csv'),
        policy='Preserved unmodified; mixed clocks, not valid contractual observations',
        corrected_rows=len(corrected),corrected_kernel_over_total=0))
    result=lab.checked(['python',str(lab.ROOT/'tests/sprint06_windows_test.py')],out/'runner-tests.json')
    build=lab.ROOT/'.cache/s06-windows-build'
    for version,variants in [('c_secuencial',('baseline','restrict_c')),('c_openmp_local',('baseline','static1'))]:
        for n in (1,3,7,17,65):
            for variant in variants:
                result=lab.checked([build/(version+'.exe'),str(n),variant],out/f'{version}-{n}-{variant}.json')
                if json.loads(result['stdout'])['validation_status']!='OK': raise RuntimeError('C candidate validation failed')
    print('Additional S6 verification complete',flush=True)


if __name__=='__main__': main()
