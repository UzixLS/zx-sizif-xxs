import common::*;
module turbosound(
    input rst_n,
    input clk28,
    input ck35,
    input en,
    input en_ts,

    cpu_bus bus,
    output reg [7:0] d_out,
    output reg d_out_active,

    output [7:0] ay_a0,
    output [7:0] ay_b0,
    output [7:0] ay_c0,
    output [7:0] ay_a1,
    output [7:0] ay_b1,
    output [7:0] ay_c1
);

//              bdir bc1 description
// bffd read  |   0   0  inactive
// bffd write |   1   0  write to psg
// fffd read  |   0   1  read from psg
// fffd write |   1   1  latch address

reg ay_bdir;
reg ay_bc1;
reg ay_sel;
wire port_bffd = en && bus.ioreq && bus.a[15] == 1'b1 && bus.a[1] == 0;
wire port_fffd = en && bus.ioreq && bus.a[15] == 1'b1 && bus.a[14] == 1'b1 && bus.a[1] == 0;
always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n) begin
        ay_bc1 <= 0;
        ay_bdir <= 0;
        ay_sel <= 0;
    end
    else begin
        ay_bc1  <= port_fffd;
        ay_bdir <= port_bffd && bus.wr;
        if (!en_ts)
            ay_sel <= 0;
        else if (bus.ioreq && port_fffd && bus.wr && bus.d[7:3] == 5'b11111)
            ay_sel <= bus.d[0];
    end
end


reg [1:0] ay_ck;
always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n)
        ay_ck <= 0;
    else if (ck35)
        ay_ck <= ay_ck + 1'b1;
    else
        ay_ck[1] <= 0;
end


wire [7:0] ay_dout0, ay_dout1;
YM2149 ym2149_0(
    .CLK(clk28),
    .CE(ay_ck[1]),
    .RESET(~rst_n),
    .A8(~ay_sel),
    .BDIR(ay_bdir),
    .BC(ay_bc1),
    .DI(bus.d),
    .DO(ay_dout0),
    .SEL(1'b0),
    .MODE(1'b1),
    .CHANNEL_A(ay_a0),
    .CHANNEL_B(ay_b0),
    .CHANNEL_C(ay_c0)
    );
YM2149 ym2149_1(
    .CLK(clk28),
    .CE(ay_ck[1]),
    .RESET(~rst_n || !en_ts),
    .A8(ay_sel),
    .BDIR(ay_bdir),
    .BC(ay_bc1),
    .DI(bus.d),
    .DO(ay_dout1),
    .SEL(1'b0),
    .MODE(1'b0),
    .CHANNEL_A(ay_a1),
    .CHANNEL_B(ay_b1),
    .CHANNEL_C(ay_c1)
    );


always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n) begin
        d_out_active <= 0;
        d_out <= 0;
    end
    else begin
        d_out_active <= bus.rd && port_fffd;
        d_out <= ay_sel? ay_dout1 : ay_dout0;
    end
end

endmodule
