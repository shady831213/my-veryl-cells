# Synchronous bus endpoints

The package adapts AXI to two ready/valid ports. A transfer takes place on a rising clock edge with valid and ready asserted. The source holds valid and the complete payload across stalls. Reset clears outstanding state. Integrators coordinate reset with both peers and drain live transactions before a warm reset.

## Register access

`AxiLiteRegisterFrontend::<B>` connects a 32- or 64-bit AXI4-Lite slave to `RegisterPort`. AW, W and AR each have a one-entry slice. A write becomes eligible after both beats arrive. Complete writes and reads share one internal request/response credit and alternate preference when both are eligible. B and R each retain their direction’s credit until consumed.

The request carries the byte address, write flag, 64 data bits, eight byte enables and a wide flag indicating a 64-bit host interface. A 32-bit access uses the low four lanes. The default port uses a 32-bit address. For other widths instantiate the port with `REQUEST: RegisterBus::<B::ADDRESS_WIDTH>::Request`. The frontend checks that the address widths agree. The register owner applies byte enables and side effects on acceptance and returns data and status. The frontend propagates success, access error and unmapped status to AXI. Another frontend can drive the same port and reuse the register target.

## Burst access

`AxiMemoryMaster::<B, BURST_BEATS, TAG_BITS, ATTR_BITS>` consumes `BurstPort::<B::ADDRESS_WIDTH, B::DATA_WIDTH_BYTES, BURST_BEATS, TAG_BITS, ATTR_BITS>`. Its AXI master issues ordinary, aligned INCR transfers using ID zero. These channels also carry ordinary AXI5 traffic with atomic requests disabled at the system boundary. Read and write outstanding capacities are independent instance parameters.

- Submit a byte address, log2(bytes per beat), beats minus one, a tag and packed address attributes. Pack write data densely starting at bit zero. Choose 1..256 beats per retained burst and supply requests within that bound, the bus beat width and a single 4 KiB region. Use a power-of-two bus width of 2..128 bytes. Address attributes map to ARUSER/AWUSER; select sufficient USER width to preserve meaningful bits.
- Each accepted request produces one terminal receipt with the original tag. Reads return dense bytes in address order. Writes reserve separate address, data and response tracking together. Reads and writes can finish independently. The receipt merge retains a selected result under backpressure. The caller retains tag ownership until receipt acceptance.
- Supply combinational `read_attributes` and `write_attributes` from the current R and B signals. Tie both inputs to zero for an ordinary target without a response-sideband policy. The master samples a classification only on its response beat. A non-OKAY response sets `failed`; `retryable` is true when every failing beat is classified retryable. Unexpected ID, EXOKAY, a length/RLAST mismatch or a caller-classified invalid encoding sets `protocol_error`. Read retirement follows an accepted RLAST. A missing terminal response requires system-level recovery.

### Transfer order and buffering

One request handshake issues one AXI burst. The caller splits a longer transfer at burst and 4 KiB boundaries before admission. One receipt handshake returns the tag, status and, for reads, the complete burst payload.

All AR transactions use ID zero. Several reads can be outstanding; one tracker FIFO records their tags and geometry. The R lane assembles one burst at a time into a full-burst accumulator and pops the tracker at the accepted RLAST. It cannot interleave data from different transactions. A nonzero RID sets `protocol_error`. A completed read may occupy the read receipt slice and then the shared output slice while the caller is stalled.

Each accepted write enqueues one full burst in a data FIFO of depth `WRITE_OUTSTANDING`. Its head drives W beat by beat and is released at the accepted WLAST. The separate address and response queues retain AW attributes and the completion tag for their own lifetimes. All AW transactions also use ID zero and B responses retire in AW order. Read and write receipts share a round-robin output and may overtake one another across directions. The caller owns any storage needed across transactions, such as a copy buffer retained for replay.

The endpoints and their storage run in a single clock domain. The package exports the passive `common_cell_ready_valid_properties::held_until_accepted` assertion for individual request or receipt channels. The integrating design binds it at its clock/reset and owns CDC, identity mapping, fairness across clients and lifecycle policy.

Run `veryl test` in `common_cell/tests` for independent address/data backpressure, byte-lane packing, opaque tag and USER propagation, and mixed-error burst classification.
