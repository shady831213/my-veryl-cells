# Extraction qualification

Initial source extraction was verified on 2026-11-16. Shared source/test bodies
match their recorded originals. Fresh native executions discovered exactly the
expected tests, with zero failed or ignored cases:

| Compiler recipe | Backend requested | Common cells | Generic providers |
| --- | --- | --- | --- |
| 0.22.1-generic-wide | CC | 11 PASS | 3 PASS |
| 0.22.1-generic-wide | Cranelift | 11 PASS | 3 PASS |
| 0.22.1-generic-wide-struct | CC | 11 PASS | 3 PASS |
| 0.22.1-generic-wide-struct | Cranelift | 11 PASS | 3 PASS |

Both used `--backend-validate 1` and `VERYL_DUT_REUSE=0`. A requested backend
can use its documented fallback; this is not a claim of two independent native
engines for every four-state operation. Compiler executables were verified cached
artifacts, not rebuilt for those initial tests. They ran before replacing the
provider's relative dependency with a published Git dependency.

## Published and development graphs

The published provider's native Git dependency passed its three tests. Isolated
consumer migrations passed PCIe51 and PDMA20 native tests, with zero fail/ignore.
PCIe also passed17 exact runtime assertion gates; all81 emitted implementation
SV files were byte-identical to the pre-extraction frozen candidate. PDMA's nine
resource-transport tests and actual package-resource snapshot generation passed.
These are migration checks, not new physical implementation qualifications.

The mixed local/Git development graph exposed upstream identity bug
[#3709](https://github.com/veryl-lang/veryl/issues/3709). The native Git+path override
form panicked on existing tools; keeping pure local paths instead produced
incompatible duplicate contract identities. Neither failure was accepted or
hidden with generated manifests or copied test sources.

The explicit four-patch development recipe in my-veryl fixes this graph while
leaving published consumers' compiler choices unchanged. It passed all11 common
tests and3 generic tests on each requested CC/Cranelift backend, plus the compiler
regressions. Metadata confirmed the two actual local package paths and coherent
edges. Each developer must use a compiler supporting that native override form;
an older consumer recipe is not automatically sufficient for library development.

Run ordinary native tests from `common_cell/tests` and `tech_cell/generic` with
explicit `VERYL_DUT_REUSE=0`. Test the two existing compiler recipes independently;
do not silently switch a consuming project to the three-patch recipe. Shared
constraints and checkers still require an integrating project's actual objects,
clocks and reset policy. No new physical CDC/RDC, macro timing, synthesis, power
or complete Port/DMA qualification is claimed by library tests.
