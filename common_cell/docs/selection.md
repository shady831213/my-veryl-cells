# Bounded Selection

Both packages require `ENTRIES >= 1`. `Mask` is `logic<ENTRIES>` and `Index` is
`logic<max(1,clog2(ENTRIES))>`. Inputs must be known binary values at the use point;
there is no sanitization contract for X/Z.

`BoundedIndex::<ENTRIES>` provides:

- `to_onehot(index) -> Mask`: one bit for an in-range index; zero for an unused
  encoding in a non-power-of-two width. For ENTRIES=1, index 1 is out of range.
- `encode_onehot(mask) -> Index`: pure OR encoding, requiring the caller to prove
  zero/one-hot. Zero returns zero. Multi-hot has no promised index; this is not
  a priority encoder. Do not use it on arbitrary request masks.
- `decode(mask) -> Decoded {valid,index}`: checked exactly-one-hot decoding.
  Zero and multi-hot both return `{0,0}`. This check adds mask/subtraction logic;
  use it where the input contract actually needs validation.

`RoundRobin::<ENTRIES>::select(eligible, cursor) -> Mask` returns zero when no
candidate is eligible, otherwise the first set bit at/above the inclusive cursor,
wrapping to the first set bit. An unused cursor encoding starts at zero. The
result is always zero/one-hot and can feed `encode_onehot` without the checked
decoder. The caller retains the valid flag (`mask != 0`), advances the cursor on
the actual grant handshake, wraps at ENTRIES, and freezes held ownership as its
protocol requires. Eligible flags, cursor registers, admission/fairness policy,
allocation/release and all ATS table state remain outside these functions.

### Is This Round Robin?

Yes: the function is the **combinational selector for round-robin arbitration**,
not a complete stateful arbiter. For cursor `c`, it searches in cyclic order
`c, c+1, ..., ENTRIES-1, 0, ..., c-1`. A priority encoder implements each search
segment; the rotating starting point makes the resulting policy round robin,
not fixed lowest-index priority. The existing `RoundRobin::select` name denotes
this policy; it does not promise an internally stored cursor.

For ENTRIES=4 and continuously eligible indices {0,2,3}:

```text
selection opportunity     0       1       2       3       4
cursor                    1       3       3       0       1
selected index            2       3       3       0       2
grant accepted            yes     no      yes     yes     yes
cursor after edge         3       3       0       1       3
```

The owner updates to `(accepted_index + 1) modulo ENTRIES` only on irrevocable
grant acceptance; no grant leaves the cursor unchanged. A held public offer
must also retain its owner until acceptance. The selector alone does not freeze
changing eligibility or guarantee progress. With the owner obeying these rules,
a continuously eligible requester waits at most ENTRIES-1 *other accepted grants*;
this is not a clock bound when the consumer stalls.

The integrating owner defines its own irreversible grant point and held-offer
state. The library does not prescribe a transaction table or bus scheduler.

The selector uses parallel prefix masks to isolate the first eligible bit,
with cyclic search controlled by the caller's cursor. Function
reuse is source reuse, not physical arbitration/storage sharing. Timing and area
depend on the caller's geometry, fanout and mapped implementation.

## Insertion Age

`AgeOrder::<ENTRIES>` stores one bit for each unordered pair of rows, for
`ENTRIES*(ENTRIES-1)/2` flip-flops. Its `insert` input must be zero/one-hot;
inserting a physical row makes it newer than every other row. `older[i][j]`
means row j was inserted before row i. The reverse is a wire complement, not
another stored bit. Reset establishes ascending numerical order.

Liveness remains caller-owned. `AgeSelect::oldest/newest(candidates, older)`
returns a zero/one-hot choice after masking dead rows. Multiple selection
purposes share one history, rather than instantiating duplicate age matrices.
Results use the old history at the sampling edge; insertion changes the next
cycle's order. There is no queue storage, allocation or lifecycle policy here.
Different consumers can select the newest matching member or the oldest eligible
member over the same history without duplicating storage.

The native timestamp oracle checks all 256 subsets of eight rows after reset
and 32 nonnumeric/reused insertions. This is functional selection evidence,
not evidence that quadratic relation logic scales without timing tradeoffs.
