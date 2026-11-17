"""Meaningful acceptance tests for laboratory grouping (no measured timings)."""
import importlib.util
import os
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("s06lab", Path(__file__).resolve().parents[1] / "scripts/sprint06_lab.py")
lab = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lab)


def group(variant="baseline", scale=1):
    return [dict(version="test", variant=variant, n=3, workers=1, repetition=rep,
                 status="OK", total_s=(10000 if rep == 0 else rep * scale),
                 kernel_s=(10000 if rep == 0 else rep * scale),
                 peak_rss_bytes=4096, wall_s=1)
            for rep in range(6)]


class SummaryTests(unittest.TestCase):
    def test_warmup_exclusion_quartiles_and_before_after(self):
        base, candidate = lab.summarize(group() + group("candidate", 0.5))
        self.assertEqual(base["total_s_median"], 3)
        self.assertEqual(base["total_s_iqr"], 2)
        self.assertEqual(base["total_s_min"], 1)
        self.assertEqual(base["total_s_max"], 5)
        self.assertEqual(candidate["total_reduction_percent"], 50)

    def test_failed_measure_missing_measure_and_duplicate_are_incomplete(self):
        failed = group()
        failed[3]["status"] = "TIMEOUT"
        duplicate = group()
        duplicate[5]["repetition"] = 4
        for rows in (failed, group()[:-1], duplicate, group()[1:]):
            with self.subTest(rows=rows):
                result = lab.summarize(rows)[0]
                self.assertEqual(result["status"], "INCOMPLETE")
                self.assertNotIn("total_s_median", result)
                self.assertNotIn("total_reduction_percent", result)

    def test_no_matching_baseline_no_reduction(self):
        other = group("candidate")
        for row in other:
            row["n"] = 7
        summary = lab.summarize(group() + other)
        self.assertNotIn("total_reduction_percent", summary[1])


@unittest.skipUnless(Path("/usr/bin/time").exists(), "requires GNU time")
class ProcessTests(unittest.TestCase):
    def observation(self, body, timeout=5):
        with tempfile.TemporaryDirectory(prefix="s06-process-") as temp:
            directory = Path(temp)
            executable = directory / "child"
            executable.write_text("#!/usr/bin/env python3\n" + body)
            executable.chmod(0o700)
            return lab.observe(dict(version="go_secuencial", variant="baseline", n=3, workers=1),
                               1, 1, executable, directory, os.environ.copy(), timeout)

    def test_success_preserves_stdout_and_measures_peak(self):
        row = self.observation('''import json, os
from pathlib import Path
Path(os.environ['S06_OUTPUT']).write_text(json.dumps(dict(schema='s06-laboratory-v1',
version='go_secuencial', variant='baseline', n=3, workers=1,
validation_status='OK', kernel_s=0.1, total_s=0.2)))
print('controlled child')
''')
        self.assertEqual(row["status"], "OK")
        self.assertGreater(row["peak_rss_bytes"], 0)
        self.assertIn("controlled child", row["raw_stdout"])

    def test_nonzero_exit_never_creates_accepted_measurement(self):
        row = self.observation("import sys\nprint('controlled failure', file=sys.stderr)\nsys.exit(2)\n")
        self.assertEqual(row["status"], "ERROR")
        self.assertEqual(row["exit_code"], 2)
        self.assertNotIn("total_s", row)
        self.assertIn("controlled failure", row["raw_stderr"])

    def test_timeout_terminates_own_process_group(self):
        row = self.observation("import time\ntime.sleep(30)\n", timeout=0.05)
        self.assertEqual(row["status"], "TIMEOUT")
        self.assertLess(row["wall_s"], 5)
        self.assertNotIn("total_s", row)


if __name__ == "__main__":
    unittest.main()
