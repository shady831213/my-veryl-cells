# Reusable hardware library

- Preserve native Veryl project/dependency/test discovery. Keep module contracts
  and observable latency, capacity, reset and collision semantics explicit.
- common_cell owns contracts and generic behavior; technology providers depend
  on it, never the reverse. Tests may select providers without a production cycle.
- Constraints/checkers belong with cells; platform clocks, budgets, reset/drain,
  instance bindings, structural waivers and signoff belong to the integrator.
- Native unit tests first. Functional PASS is not physical CDC/RDC or SRAM PPA.
- Explain actual storage/access ports and timing before adding an abstraction.
- Do not add device scheduling, Function/PASID lifecycle or application-specific
  policies. A caller owns arbitration state and protocol obligations.
- No compiler installer or project flow here. Consumers independently choose a
  compatible compiler; my-veryl is temporary and must not become a dependency.
- Public repository: no proprietary sources, libraries or machine deployment.
