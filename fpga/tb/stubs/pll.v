`timescale 1 ps / 1 ps
module pll (
    inclk0,
    c0,
    c1,
    locked);

    input     inclk0;
    output    c0;
    output    c1;
    output reg    locked;

initial begin
    locked = 0;
    #3000 locked = 1;
end

assign c0 = 0;
assign c1 = 0;

endmodule