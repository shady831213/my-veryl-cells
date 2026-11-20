# Synchronous bus endpoints

The package adapts AXI to a register request/response port. A transfer takes place on a rising clock edge with valid and ready asserted. The source holds valid and the complete payload across stalls. Reset clears outstanding state. Integrators coordinate reset with both peers and drain live transactions before a warm reset.

## Register access

`AxiLiteRegisterFrontend::<B>` connects a 32- or 64-bit AXI4-Lite slave to `RegisterPort`. AW, W and AR each have a one-entry slice. A write becomes eligible after both beats arrive. Complete writes and reads share one internal request/response credit and alternate preference when both are eligible. B and R each retain their direction’s credit until consumed.

The request carries the byte address, write flag, 64 data bits, eight byte enables and a wide flag indicating a 64-bit host interface. A 32-bit access uses the low four lanes. The default port uses a 32-bit address. For other widths instantiate the port with `REQUEST: RegisterBus::<B::ADDRESS_WIDTH>::Request`. The frontend checks that the address widths agree. The register owner applies byte enables and side effects on acceptance and returns data and status. The frontend propagates success, access error and unmapped status to AXI. Another frontend can drive the same port and reuse the register target.
