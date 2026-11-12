"""Checks for S6 grouping: incomplete/failed data must never become a result."""
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('s06windows', Path(__file__).resolve().parents[1] / 'scripts/sprint06_windows.py')
lab = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lab)


class SummaryTests(unittest.TestCase):
    def rows(self):
        return [dict(kind='laboratory', version='c_secuencial', variant='baseline',
                     n=256, workers=1, repetition=r, status='OK', kernel_s=100 if r == 0 else r,
                     total_s=100 if r == 0 else r, wall_s=100 if r == 0 else r) for r in range(6)]

    def test_warmup_excluded_and_inclusive_iqr(self):
        result = lab.summarize(self.rows())[0]
        self.assertEqual(result['status'], 'COMPLETE')
        self.assertEqual(result['total_s_median'], 3)
        self.assertEqual(result['total_s_iqr'], 2)
        self.assertEqual(result['total_s_max'], 5)

    def test_duplicate_cannot_replace_missing_round(self):
        rows = self.rows(); rows[-1]['repetition'] = 4
        self.assertEqual(lab.summarize(rows)[0]['status'], 'INCOMPLETE')

    def test_failure_not_silently_dropped(self):
        rows = self.rows(); rows[-1]['status'] = 'ERROR'
        result = lab.summarize(rows)[0]
        self.assertEqual(result['status'], 'INCOMPLETE')
        self.assertNotIn('total_s_median', result)

    def test_platform_resources_not_merged(self):
        rows = self.rows() + [r | dict(processes=2,threads=1) for r in self.rows()]
        self.assertEqual(len(lab.summarize(rows)), 2)


if __name__ == '__main__': unittest.main()
