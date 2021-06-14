module asmi (
    addr,
    clkin,
    rden,
    read,
    reset,
    busy,
    data_valid,
    dataout)/* synthesis synthesis_clearbox = 2 */;

    input   [23:0]  addr;
    input     clkin;
    input     rden;
    input     read;
    input     reset;
    output    busy;
    output    data_valid;
    output  [7:0]  dataout;

    assign busy = 0;
    assign data_valid = 1'b1;
    assign dataout = 0;

endmodule
