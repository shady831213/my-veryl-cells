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
artifacts, not rebuilt for extraction. Published Git dependency resolution and
consumer integration are separate gates still to be completed.

Run ordinary native tests from `common_cell/tests` and `tech_cell/generic` with
explicit `VERYL_DUT_REUSE=0`. Test the two existing compiler recipes independently;
do not silently switch a consuming project to the three-patch recipe. Shared
constraints and checkers still require an integrating project's actual objects,
clocks and reset policy. No new physical CDC/RDC, macro timing, synthesis, power
or complete Port/DMA qualification is claimed by library tests.
