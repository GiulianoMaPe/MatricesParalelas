#!/usr/bin/env python3
"""S6 Linux kernel diagnostics, NOT the Windows benchmark or S7 campaign.

Builds isolated candidates, alternates rounds, validates every cell in the
child harness, captures GNU time's peak RSS, and preserves failed attempts.
Only Python's standard library is required, besides Go/GCC/GNU time.
"""
import argparse
import csv
import hashlib
import json
import math
import os
from pathlib import Path
import platform
import shutil
import signal
import subprocess
import sys
import time
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[1]


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run_checked(command, cwd, env, log):
    result = subprocess.run(command, cwd=cwd, env=env, capture_output=True, text=True)
    log.write_text(result.stdout + result.stderr, encoding="utf-8")
    if result.returncode:
        raise RuntimeError(f"command failed ({result.returncode}): {command}; see {log}")
    return result.stdout.strip()


def physical_cores():
    allowed = os.sched_getaffinity(0)
    pairs = set()
    for cpu in allowed:
        directory = Path(f"/sys/devices/system/cpu/cpu{cpu}/topology")
        pairs.add(((directory / "physical_package_id").read_text().strip(),
                   (directory / "core_id").read_text().strip()))
    return len(pairs)


def memory_available():
    return {line.split(":")[0]: int(line.split()[1]) * 1024
            for line in Path("/proc/meminfo").read_text().splitlines()
            if line.startswith(("MemTotal:", "MemAvailable:"))}


def summarize(rows):
    groups = {}
    for row in rows:
        key = (row["version"], row["variant"], row["n"], row["workers"])
        groups.setdefault(key, []).append(row)
    output = []
    for key, group in groups.items():
        measured = [r for r in group if r["repetition"] != 0 and r["status"] == "OK"]
        complete = (len(group) == 6 and all(r["status"] == "OK" for r in group)
                    and sorted(r["repetition"] for r in group) == list(range(6)))
        item = dict(zip(("version", "variant", "n", "workers"), key))
        item.update(status="COMPLETE" if complete else "INCOMPLETE", valid_measures=len(measured))
        if complete:
            for field in ("kernel_s", "total_s", "peak_rss_bytes", "wall_s"):
                values = sorted(r[field] for r in measured)
                item.update({field + "_median": values[2], field + "_min": values[0],
                             field + "_max": values[4], field + "_iqr": values[3] - values[1]})
        output.append(item)
    for item in output:
        baseline = next((b for b in output if b["variant"] == "baseline" and
                         all(b[k] == item[k] for k in ("version", "n", "workers"))), None)
        if item["status"] == "COMPLETE" and baseline and baseline["status"] == "COMPLETE":
            before = baseline["total_s_median"]
            item["total_reduction_percent"] = 100 * (before-item["total_s_median"]) / before if before else None
    return output


def build_tools(go, gcc, directory, env, versions):
    binaries = {}
    commands = []
    for version, module, extra in (("c_secuencial", "c_secuencial", []),
                                    ("c_openmp_local", "c_paralelo", ["-fopenmp", "-DS06_OPENMP"])):
        if version not in versions:
            continue
        executable = directory / version
        command = [gcc, "-std=c11", "-O2", "-ffp-contract=off", "-Wall", "-Wextra", "-Werror",
                   *extra, "-I", str(ROOT / module / "include"),
                   str(ROOT / "tests/sprint06_kernel_bench.c"), str(ROOT / "tests/sprint06_candidates.c"),
                   str(ROOT / module / "src/matrix.c"), str(ROOT / module / "src/input.c"),
                   "-lm", "-o", str(executable)]
        run_checked(command, ROOT, env, directory / (version + "_build.txt"))
        binaries[version] = executable
        commands.append(command)
    for module in ("go_secuencial", "go_paralelo"):
        if module not in versions:
            continue
        executable = directory / (module + ".test")
        command = [go, "test", "-c", "-o", str(executable), "."]
        run_checked(command, ROOT / module, env, directory / (module + "_build.txt"))
        binaries[module] = executable
        commands.append(command)
    return binaries, commands


def observe(case, repetition, order, executable, directory, env, timeout):
    stem = f"{order:04d}_{case['version']}_{case['variant']}_n{case['n']}_w{case['workers']}_r{repetition}"
    observation = directory / (stem + ".json")
    peak = directory / (stem + ".rss.txt")
    child_env = env | {"GOMAXPROCS": str(case["workers"]), "OMP_NUM_THREADS": str(case["workers"]),
                       "OMP_DYNAMIC": "FALSE", "S06_N": str(case["n"]),
                       "S06_WORKERS": str(case["workers"]), "S06_VARIANT": case["variant"],
                       "S06_OUTPUT": str(observation)}
    if case["version"].startswith("go_"):
        command = [str(executable), "-test.run=^TestSprint06Observation$", "-test.count=1"]
        cwd = ROOT / case["version"]
    else:
        command = [str(executable), str(case["n"]), case["variant"]]
        cwd = ROOT
    command = ["/usr/bin/time", "-f", "%M", "-o", str(peak), *command]
    started = time.monotonic()
    row = case | {"repetition": repetition, "is_warmup": repetition == 0,
                  "execution_order": order, "status": "ERROR", "seed": 42}
    with (directory / (stem + ".stdout.txt")).open("w") as stdout, (directory / (stem + ".stderr.txt")).open("w") as stderr:
        process = subprocess.Popen(command, cwd=cwd, env=child_env, stdout=stdout, stderr=stderr,
                                   start_new_session=True)
        try:
            process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()
            row["status"] = "TIMEOUT"
        except BaseException:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()
            raise
    row.update(wall_s=time.monotonic()-started, exit_code=process.returncode)
    row["raw_stdout"] = (directory / (stem + ".stdout.txt")).read_text()
    row["raw_stderr"] = (directory / (stem + ".stderr.txt")).read_text()
    row["raw_peak_rss_kib"] = peak.read_text() if peak.exists() else ""
    try:
        if row["status"] == "TIMEOUT" or process.returncode != 0:
            raise ValueError("timeout or nonzero exit")
        if not case["version"].startswith("go_"):
            observation.write_text((directory / (stem + ".stdout.txt")).read_text(), encoding="utf-8")
        data = json.loads(observation.read_text())
        for field in ("version", "variant", "n", "workers"):
            if data[field] != case[field]:
                raise ValueError(f"unexpected {field}")
        if data["schema"] != "s06-laboratory-v1" or data["validation_status"] != "OK":
            raise ValueError("invalid schema or validation")
        kernel, total = data["kernel_s"], data["total_s"]
        if not all(math.isfinite(v) for v in (kernel, total)) or not 0 <= kernel <= total:
            raise ValueError("invalid durations")
        rss = int(peak.read_text().strip()) * 1024
        row.update(data, status="OK", peak_rss_bytes=rss)
    except (ValueError, OSError, KeyError, TypeError) as error:
        row["reason"] = str(error)
    row["command"] = command
    return row


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--go", default="go")
    parser.add_argument("--gcc", default="gcc")
    parser.add_argument("--sizes", type=int, nargs="+", default=[256, 512, 1024])
    parser.add_argument("--workers", type=int, nargs="+", default=[1, 2, 4])
    parser.add_argument("--versions", nargs="+", choices=["c_secuencial", "c_openmp_local", "go_secuencial", "go_paralelo"],
                        default=["c_secuencial", "c_openmp_local", "go_secuencial", "go_paralelo"])
    parser.add_argument("--timeout", type=int, default=180)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if sys.platform != "linux":
        parser.error("this lab requires Linux; use the project's native scripts for Windows")
    if not Path("/usr/bin/time").is_file():
        parser.error("GNU time is required for peak RSS")
    if args.timeout < 1 or any(n < 1 or n > 4096 for n in args.sizes):
        parser.error("invalid timeout or dimension (expected 1..4096)")
    cores = physical_cores()
    if any(w < 1 or w > min(cores, 1024) for w in args.workers):
        parser.error("workers exceed available physical cores or supported range")
    args.sizes, args.workers = sorted(set(args.sizes)), sorted(set(args.workers))
    if 1 not in args.workers:
        parser.error("include --workers 1 to retain the baseline")
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    directory = (args.output or ROOT / "resultados/diagnostico/s06" / (stamp + "_" + platform.node())).resolve()
    if directory.exists():
        parser.error("output already exists; preserve attempts and choose a new directory")
    # Conservative extra space for test runtime and compiler activity.
    available = memory_available()
    if 4 * 8 * max(args.sizes)**2 > available["MemAvailable"] // 2:
        parser.error("matrix buffers exceed 50% of currently available RAM")
    lock_path = ROOT / ".cache/s06-laboratory.lock"
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        lock = lock_path.open("x")
    except FileExistsError:
        parser.error(f"laboratory already active; inspect {lock_path}")
    rows = []
    try:
        lock.write(str(os.getpid())); lock.flush()
        directory.mkdir(parents=True)
        build = directory / "build"
        build.mkdir()
        env = os.environ | {"GOCACHE": str(ROOT / ".cache/go-build"),
                            "GOMODCACHE": str(ROOT / ".cache/go-mod"), "GOTOOLCHAIN": "local"}
        go, gcc = shutil.which(args.go), shutil.which(args.gcc)
        if not go or not gcc:
            raise RuntimeError("Go and GCC are required")
        binaries, commands = build_tools(go, gcc, build, env, args.versions)
        commit = run_checked(["git", "rev-parse", "HEAD"], ROOT, env, directory / "revision.txt")
        run_checked(["git", "diff", "--no-ext-diff"], ROOT, env, directory / "tracked.patch")
        sources = [ROOT / "tests/sprint06_kernel_bench.c", ROOT / "tests/sprint06_candidates.c", Path(__file__).resolve()]
        for module in ("c_secuencial", "c_paralelo"):
            sources += sorted((ROOT / module / "src").glob("*.c"))
            sources += sorted((ROOT / module / "include").glob("*.h"))
        for module in ("go_secuencial", "go_paralelo"):
            sources += sorted((ROOT / module).glob("*.go"))
            sources += [ROOT / module / "go.mod"]
        hashes = {}
        for source in sources:
            relative = source.relative_to(ROOT)
            target = directory / "sources" / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target)
            hashes[str(relative)] = sha256(source)
        cases = []
        for n in args.sizes:
            for variant in ("baseline", "restrict_c"):
                cases.append(dict(version="c_secuencial", variant=variant, n=n, workers=1))
            for w in args.workers:
                for variant in ("baseline", "static1"):
                    cases.append(dict(version="c_openmp_local", variant=variant, n=n, workers=w))
            for variant in ("baseline", "row_slices"):
                cases.append(dict(version="go_secuencial", variant=variant, n=n, workers=1))
            for w in args.workers:
                for variant in ("baseline", "block16", "unbuffered"):
                    cases.append(dict(version="go_paralelo", variant=variant, n=n, workers=w))
        cases = [case for case in cases if case["version"] in args.versions]
        plan = [(rep, case) for rep in range(6) for case in (list(reversed(cases)) if rep and rep % 2 == 0 else cases)]
        metadata = {"schema": "s06-laboratory-v1", "phase": "linux-diagnostic-not-windows-campaign",
                    "started_utc": stamp, "hostname": platform.node(), "platform": platform.platform(),
                    "physical_cores_available": cores, "logical_cpus_available": len(os.sched_getaffinity(0)),
                    "memory_at_start": available, "commit": commit, "source_sha256": hashes,
                    "cpuinfo": Path("/proc/cpuinfo").read_text().split("\n\n")[0],
                    "go": subprocess.check_output([go, "version"], text=True).strip(),
                    "gcc": subprocess.check_output([gcc, "--version"], text=True).splitlines()[0],
                    "build_commands": commands, "binaries_sha256": {k: sha256(v) for k, v in binaries.items()},
                    "sizes": args.sizes, "workers": args.workers, "versions": args.versions, "timeout_s": args.timeout,
                    "memory_method": "GNU time %M, process peak RSS in KiB converted to bytes; includes reference and diagnostics",
                    "warmups": 1, "measures": 5, "status": "RUNNING"}
        write_json(directory / "entorno.json", metadata)
        write_json(directory / "plan.json", [case | {"repetition": rep, "execution_order": i}
                                               for i, (rep, case) in enumerate(plan, 1)])
        runs = build / "runs"
        runs.mkdir()
        for order, (rep, case) in enumerate(plan, 1):
            row = observe(case, rep, order, binaries[case["version"]], runs, env, args.timeout)
            rows.append(row)
            with (directory / "observaciones.jsonl").open("a", encoding="utf-8") as output:
                output.write(json.dumps(row, ensure_ascii=False) + "\n")
            print(f"{order}/{len(plan)} {case} r{rep}: {row['status']}", flush=True)
        summary = summarize(rows)
        write_json(directory / "resumen.json", summary)
        fields = list(dict.fromkeys(k for row in summary for k in row))
        with (directory / "resumen.csv").open("w", newline="", encoding="utf-8") as output:
            writer = csv.DictWriter(output, fieldnames=fields)
            writer.writeheader(); writer.writerows(summary)
        metadata["status"] = "COMPLETE" if all(r["status"] == "OK" for r in rows) else "INCOMPLETE"
        metadata["ended_utc"] = datetime.now(timezone.utc).isoformat()
        write_json(directory / "entorno.json", metadata)
        print(directory)
        return 0 if metadata["status"] == "COMPLETE" else 1
    except BaseException as error:
        if directory.exists():
            write_json(directory / "failure.json", {"error": str(error), "type": type(error).__name__,
                       "completed_observations": len(rows), "status": "INCOMPLETE"})
            environment_path = directory / "entorno.json"
            if environment_path.exists():
                current = json.loads(environment_path.read_text())
                current["status"] = "INCOMPLETE"
                write_json(environment_path, current)
        raise
    finally:
        lock.close()
        lock_path.unlink()


if __name__ == "__main__":
    sys.exit(main())
