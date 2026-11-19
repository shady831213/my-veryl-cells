// The untyped payload preserves the width of the bound interface.
package bus_cell_properties;
    property held_until_accepted(clk, rst_n, valid, ready, payload);
        @(posedge clk) disable iff (!rst_n) valid && !ready |=> valid && $stable(payload);
    endproperty
endpackage
