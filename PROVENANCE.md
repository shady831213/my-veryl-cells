# Source provenance

Initial extraction, 2026-11-16:

- Cell implementations, tests, package constraints/checkers and documentation from
  [pdma 34aaccff](https://github.com/shady831213/pdma/tree/34aaccff/rtl).
  The original imported base is recorded in `common_cell/upstream.sha256` and
  `common_cell/README.md`; it predates PDMA's added CDC cells.
- `common_cell/src/age_order.veryl` and its native test from
  [pcie_modeling 1bfc188](https://github.com/shady831213/pcie_modeling/tree/1bfc188/rtl/common_cell).

The shared twelve common-cell implementation files, eight common test/support
files and seven generic-provider implementation/test files had identical bytes
in both source projects. The extraction preserves all cell RTL/test bodies and
all PDMA instance-scoped Tcl/checker bodies. Only ownership documentation and
native publishing/dependency metadata are adjusted.

`common_cell/upstream.sha256` is a historical import record relative to the
original `rtl` directory, not a complete hash of this repository's current files.
No external checkout is needed to build the library. New qualification results
are recorded separately; inherited downstream signoff is not transferred here.
