module mixer(
	input rst_n,
	input clk28,

	input beeper,
	input tape_out,
	input tape_in,
	input [7:0] ay_a0,
	input [7:0] ay_b0,
	input [7:0] ay_c0,
	input [7:0] ay_a1,
	input [7:0] ay_b1,
	input [7:0] ay_c1,
	input [7:0] sd_l0,
	input [7:0] sd_l1,
	input [7:0] sd_r0,
	input [7:0] sd_r1,

	input ay_abc,
	input ay_mono,

	output dac_l,
	output dac_r
);


reg [10:0] dac_l_cnt, dac_r_cnt;
assign dac_l = dac_l_cnt[10];
assign dac_r = dac_r_cnt[10];

wire [9:0] dac_next_l = 
	sd_l0 + sd_l1 +
	ay_a0 + ay_b0 +
	ay_a1 + ay_b1 +
	{beeper, tape_out, tape_in, 6'b000000}
	;
wire [9:0] dac_next_r =
	sd_r0 + sd_r1 +
	ay_b0 + ay_c0 +
	ay_b1 + ay_c1 +
	{beeper, tape_out, tape_in, 6'b000000}
	;

always @(posedge clk28 or negedge rst_n) begin
	if (!rst_n) begin
		dac_l_cnt <= 0;
		dac_r_cnt <= 0;
	end
	else begin
		dac_l_cnt <= dac_l_cnt[9:0] + dac_next_l;
		dac_r_cnt <= dac_r_cnt[9:0] + dac_next_r;
	end
end

endmodule
