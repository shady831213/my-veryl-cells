# my-veryl-cells

Reusable Veryl cells and their observable contracts. Native projects:

- `common_cell`: typed slices, bounded selection, age ordering, RAM contracts
  and provider wrappers, CDC mailboxes, asynchronous queues and
  [AXI register and memory endpoints](common_cell/docs/bus.md).
- `tech_cell/generic`: behavioral RAM providers implementing those contracts.
- `common_cell/tests`: independent native tests selecting the generic providers.

Each cell owns its tests and any instance-scoped constraints or passive checkers.
The integrating design owns clocks, reset/drain policy, IO budgets, technology
selection, instance bindings and physical qualification. Loading a constraint
package does not apply exceptions or waive findings. Optional resource declarations
do not require a particular project flow or the `my-veryl` repository.

Use a compatible Veryl compiler on PATH. Local development of the RAM contracts and providers
uses native root dependency overrides and currently requires the temporary
`0.22.1-generic-wide-struct-override` recipe from
[my-veryl](https://github.com/shady831213/my-veryl), or an upstream compiler with
the corresponding fix. Published consumption does not use those local overrides
and keeps each project's qualified compiler. See [qualification](QUALIFICATION.md).
The library does not download a compiler or change its consumer's toolchain.

```sh
cd common_cell/tests
VERYL_DUT_REUSE=0 veryl test
cd ../../tech_cell/generic
VERYL_DUT_REUSE=0 veryl test
```

Sources and unit tests retain native project discovery and dependencies. No
generated project manifests, copied test source trees or custom RTL filelists.
Consumers use the native published versions and commit their generated lockfile:

```toml
[dependencies]
common_cell = {git = "https://github.com/shady831213/my-veryl-cells", version = "=0.1.0"}
tech_cell_generic = {git = "https://github.com/shady831213/my-veryl-cells", version = "=0.1.0"}
```

The common-cell test project explicitly overrides both packages to this checkout,
using Veryl's native root-only development override. Published consumers do not
inherit those local paths. Providers depend on the published common contract;
`Veryl.pub` records release commits. Global registry registration is disabled.
See [cell contracts](common_cell/README.md), [generic providers](tech_cell/generic/README.md)
and [provenance](PROVENANCE.md). Reuse is explicit and versioned, never an automatic
sync from a consumer checkout. Generic RAM simulation or synthesis is not macro PPA.

Project-authored material is MIT OR Apache-2.0; imported notices remain applicable.
No vendor RTL, proprietary memory macro, technology library or deployment settings
are included. Future proprietary providers belong in appropriately controlled
repositories and implement the same public contracts.
