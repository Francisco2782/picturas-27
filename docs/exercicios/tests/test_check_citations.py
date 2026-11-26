import importlib.util
import unittest
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "check_citations.py"
SPEC = importlib.util.spec_from_file_location("check_citations", SCRIPT)
checker = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(checker)


class CitationRangeTests(unittest.TestCase):
    def test_accepts_single_and_multiple_valid_ranges(self):
        self.assertEqual(checker.range_errors("1, 3-5,8", 8), [])

    def test_rejects_range_outside_file(self):
        self.assertEqual(checker.range_errors("2-6", 5), ["range 2-6 outside 1-5"])

    def test_rejects_reversed_range(self):
        self.assertEqual(checker.range_errors("5-3", 8), ["range 5-3 outside 1-8"])


if __name__ == "__main__":
    unittest.main()
