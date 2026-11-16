# Ready/Valid Slice

`ReadyValidSlice #(TYPE, MODE)` accepts any packed payload type. `MODE` has type
`ReadyValid::SliceMode`: `Bypass`, `Forward`, `Reverse`, or `Full`.
Ports: `clk`, `rst_n`, source `s_valid/s_ready/s_data`, destination
`m_valid/m_ready/m_data`, and `occupied` (any stored payload, not a count).
Transfer occurs on a rising clock edge with VALID and READY both asserted.
An offered payload and VALID must remain stable until accepted. READY need not
wait for VALID. All endpoints use the same clock and coordinated reset.

| Mode | Forward VALID/data path | Reverse READY path | Stored capacity | Empty-path latency | Unstalled rate |
| --- | --- | --- | --- | --- | --- |
| Bypass | combinational | combinational | 0 | 0 cycles | 1 beat/cycle |
| Forward | registered | combinational from m_ready | 1 | 1 cycle | 1 beat/cycle |
| Reverse | combinational when empty; stored while occupied | registered occupancy only | 1 | 0 cycles | 1 beat/cycle |
| Full | registered | registered occupancy only | 2 | 1 cycle | 1 beat/cycle |

Latency is from source acceptance to the earliest destination acceptance, with
continuous destination READY. Backpressure adds variable delay. These are logic
boundaries and functional rates, not mapped timing/area or physical signoff.
No arbitrary stage-count parameter or half-bandwidth mode is exposed.

### Design Reference

The four modes follow the forward/reverse register-cut classification used in
the SMMU implementation. This is a reference for observable interface behavior,
not a copy of its cells or a claim of identical internal storage/placement.
Our Full mode delegates to the pinned Veryl standard-library slicer; the other
three modes are expressed directly in `src/ready_valid_slice.veryl`.

### Timing Examples

Each column is the signal value **immediately before** rising edge E0..E5.
The slice starts empty, reset has been released, and the source offers beats
A, B, C in order, advancing only after its handshake. `s_offer`/`m_offer` combine
VALID and data: A/B/C means VALID=1 with that beat; `-` means VALID=0 (data ignored).
`s_fire`/`m_fire` name the beat accepted at that edge, not a later notification.
`occupied` is the stored-valid indication before the edge, not the number of rows.
The consumer stalls at E1 and E2 in all four examples.

```text
Bypass: both directions combinational, no custody in the slice
edge       E0  E1  E2  E3  E4  E5
s_offer     A   B   B   B   C   -
s_ready     1   0   0   1   1   1
m_offer     A   B   B   B   C   -
m_ready     1   0   0   1   1   1
s_fire      A   -   -   B   C   -
m_fire      A   -   -   B   C   -
occupied    0   0   0   0   0   0

Forward: one stored beat, READY can respond combinationally to m_ready
edge       E0  E1  E2  E3  E4  E5
s_offer     A   B   B   B   C   -
s_ready     1   0   0   1   1   1
m_offer     -   A   A   A   B   C
m_ready     1   0   0   1   1   1
s_fire      A   -   -   B   C   -
m_fire      -   -   -   A   B   C
occupied    0   1   1   1   1   1

Reverse: empty forward path passes through, one spill beat cuts READY
edge       E0  E1  E2  E3  E4  E5
s_offer     A   B   C   C   C   -
s_ready     1   1   0   0   1   1
m_offer     A   B   B   B   C   -
m_ready     1   0   0   1   1   1
s_fire      A   B   -   -   C   -
m_fire      A   -   -   B   C   -
occupied    0   0   1   1   0   0

Full: registered forward path, head + spill cut READY
edge       E0  E1  E2  E3  E4  E5
s_offer     A   B   C   C   C   -
s_ready     1   1   0   0   1   1
m_offer     -   A   A   A   B   C
m_ready     1   0   0   1   1   1
s_fire      A   B   -   -   C   -
m_fire      -   -   -   A   B   C
occupied    0   1   1   1   1   1
```

At E3, Forward consumes A and replaces it with B on the same edge. Reverse
instead consumes stored B but cannot accept C until E4: its READY must not
depend on current destination READY. Full drains A at E3 and promotes B from
spill to head; C is accepted at E4 while B is consumed. Neither Reverse nor
Full inserts a required destination bubble after this stall. With no stall,
all modes accept/emit one beat per cycle after their 0/1-cycle initial latency.
After E5 all examples are empty. Reset is not shown; its discard and external
fencing requirements are described below.

These are RTL-derived edge traces, not captured simulator waveforms. Native
`tests/src/slice_matrix.veryl` separately checks exact capacity/latency, same-edge
replacement, registered-READY recovery, sustained II1 and pressure/reset behavior.

### Storage And Simultaneous Events

- Bypass has no storage. `occupied=0` even during a stalled live source offer.
- Forward stores one valid bit and one payload. `s_ready=!stored || m_ready`.
  With READY, a source handshake writes the payload and sets valid. A simultaneous
  destination handshake replaces the old payload; without a source offer it
  clears valid. A stalled stored payload is unchanged. Payload FFs are not reset.
- Reverse stores one valid bit and one payload. `s_ready=!stored`, with no
  combinational path from either input VALID or destination READY. When empty,
  VALID/data pass directly; source acceptance while destination stalls captures
  the payload and sets stored. When occupied, output selects the stored payload,
  not the current source offer. A destination handshake clears stored; source
  READY remains low on that edge, so there is no same-edge replacement. READY
  rises after that edge. A following source offer can pass through immediately:
  there is a one-edge source-acceptance pause on spill drain, not a required
  destination bubble. This mode does not register the forward path.
- Full uses the pinned `$std::slicer` with `STAGES=1`, `FULL_BANDWIDTH=true`.
  Its head and spill payload rows each have valid state. Output is the head;
  source READY is `!spill_valid`. A stall with a valid head captures an accepted
  second beat into spill. On drain, spill moves to head before any new input;
  when spill was full, source READY was low, so no replacement was accepted on
  that edge. With no spill, an accepted input replaces a consumed head, sustaining
  one beat/cycle. Spill-valid implies head-valid, so `occupied=m_valid` covers
  both one-row and two-row occupancy without duplicating an occupancy counter.

Reset clears valid state, discarding stored custody with priority over transfer.
Payload bits while invalid are unspecified and need not reset. Bypass/Reverse
can still expose a live source VALID during reset; the slice does not fence
either external endpoint. `occupied=0` is therefore not proof of quiescence,
remote drain, Close completion, or permission to reset. Those obligations belong
to the protocol owner. `rst_n` explicitly uses `reset_async_low`; the integrator
must synchronize deassertion to this clock and qualify reset distribution.

The std half-bandwidth slicer is not Forward: it refuses replacement while full
and transfers at most one beat every two clocks. The std full-bandwidth slicer
already implements Full; it is reused, not copied. Its stage count expresses
cascades rather than the separate Forward/Reverse semantic modes needed here.
