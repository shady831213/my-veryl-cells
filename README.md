# my-veryl-cells

Reusable Veryl cells and their observable contracts. Native projects:

- `common_cell`: typed slices, bounded selection, age ordering, RAM contracts
  and provider wrappers, acknowledged CDC mailboxes and asynchronous queues.
- `tech_cell/generic`: behavioral RAM providers implementing those contracts.
- `common_cell/tests`: independent native tests selecting the generic providers.

Each cell owns its tests and any instance-scoped constraints or passive checkers.
The integrating design owns clocks, reset/drain policy, IO budgets, technology
selection, instance bindings and physical qualification. Loading a constraint
package does not apply exceptions or waive findings. Optional resource declarations
do not require a particular project flow or the `my-veryl` repository.

Use a compatible Veryl compiler on PATH. For the initial imported baseline,
the tested compiler recipes are documented in [qualification](QUALIFICATION.md).
The library does not download a compiler or change its consumer's toolchain.

```sh
cd common_cell/tests
VERYL_DUT_REUSE=0 veryl test
cd ../../tech_cell/generic
VERYL_DUT_REUSE=0 veryl test
```

Sources and unit tests retain native project discovery and dependencies. No
generated project manifests, copied test source trees or custom RTL filelists.
See [cell contracts](common_cell/README.md), [generic providers](tech_cell/generic/README.md)
and [provenance](PROVENANCE.md). Reuse is explicit and versioned, never an automatic
sync from a consumer checkout. Generic RAM simulation or synthesis is not macro PPA.

Project-authored material is MIT OR Apache-2.0; imported notices remain applicable.
No vendor RTL, proprietary memory macro, technology library or deployment settings
are included. Future proprietary providers belong in appropriately controlled
repositories and implement the same public contracts.
