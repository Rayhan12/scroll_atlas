# scroll_atlas tooling

## check_coverage.dart

Parses an LCOV report (`coverage/lcov.info` from `flutter test --coverage`) and enforces a minimum line coverage percentage for files whose `SF:` path contains a given prefix.

```bash
dart run tool/check_coverage.dart coverage/lcov.info lib/src/core 100
```

The script sums `LF` (lines found) and `LH` (lines hit) across matching records, prints the percentage, and exits with code `1` if coverage is below the threshold or if no files match the prefix.

CI uses it to require 100% line coverage on `lib/src/core`.
