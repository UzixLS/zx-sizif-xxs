module turbosound(
	input rst_n,
	input clk28,
	input ck35,
	input en,

	cpu_bus bus,
	output [7:0] d_out,
	output d_out_active,

	input pause,
	
	output [7:0] ay_a0,
	output [7:0] ay_b0,
	output [7:0] ay_c0,
	output [7:0] ay_a1,
	output [7:0] ay_b1,
	output [7:0] ay_c1
);


reg ay_bdir;
reg ay_bc1;
reg ay_sel;
wire ay_rd0 = bus.rd && ay_bc1 == 1'b1 && ay_bdir == 1'b0 && ay_sel == 1'b0;
wire ay_rd1 = bus.rd && ay_bc1 == 1'b1 && ay_bdir == 1'b0 && ay_sel == 1'b1;
wire port_bffd = bus.ioreq && bus.a[15] == 1'b1 && bus.a[1] == 0;
wire port_fffd = bus.ioreq && bus.a[15] == 1'b1 && bus.a[14] == 1'b1 && bus.a[1] == 0;
always @(posedge clk28 or negedge rst_n) begin
	if (!rst_n) begin
		ay_bc1 <= 0;
		ay_bdir <= 0;
		ay_sel <= 0;
	end
	else begin
		ay_bc1  <= en && port_fffd;
		ay_bdir <= en && port_bffd && bus.wr;
		if (bus.ioreq && port_fffd && bus.wr && bus.d[7:3] == 5'b11111)
			ay_sel <= bus.d[0];
	end
end


reg [1:0] ay_ck;
always @(posedge clk28 or negedge rst_n) begin
	if (!rst_n)
		ay_ck <= 0;
	else if (ck35 && en && !pause)
		ay_ck <= ay_ck + 1'b1;
	else
		ay_ck[1] <= 0;
end


wire [7:0] ay_dout0, ay_dout1;
YM2149 ym2149_0(
	.CLK(clk28),
	.ENA(ay_ck[1]),
	.RESET_H(~rst_n),
	.I_SEL_L(1'b1),
	.I_DA(bus.d),
	.O_DA(ay_dout0),
	.I_REG(1'b0),
	.busctrl_addr(ay_bc1 & ay_bdir & ~ay_sel),
	.busctrl_we(~ay_bc1 & ay_bdir & ~ay_sel),
	.ctrl_aymode(1'b1),
	.port_a_i(8'hff),
	.port_b_i(8'hff),
	.port_a_o(),
	.port_b_o(),
	.O_AUDIO_A(ay_a0),
	.O_AUDIO_B(ay_b0),
	.O_AUDIO_C(ay_c0)
	);
YM2149 ym2149_1(
	.CLK(clk28),
	.ENA(ay_ck[1]),
	.RESET_H(~rst_n),
	.I_SEL_L(1'b1),
	.I_DA(bus.d),
	.O_DA(ay_dout1),
	.I_REG(1'b0),
	.busctrl_addr(ay_bc1 & ay_bdir & ay_sel),
	.busctrl_we(~ay_bc1 & ay_bdir & ay_sel),
	.ctrl_aymode(1'b1),
	.port_a_i(8'hff),
	.port_b_i(8'hff),
	.port_a_o(),
	.port_b_o(),
	.O_AUDIO_A(ay_a1),
	.O_AUDIO_B(ay_b1),
	.O_AUDIO_C(ay_c1)
	);

	
assign d_out_active = ay_rd0 | ay_rd1;
assign d_out = ay_rd1? ay_dout1 : ay_dout0;

	
endmodule
