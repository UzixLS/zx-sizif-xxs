module ps2_rxtx#(
	parameter CLK_FREQ
	) (
	input rst_n,
	input clk,
	
	input ps2_clk_in,
	input ps2_dat_in,
	output ps2_clk_out,
	output ps2_dat_out,
	
	output [7:0] dataout,
	output reg dataout_valid,
	output reg dataout_error
);

localparam CLKWAIT_US = 100;
localparam CLKWAIT_WIDTH = $clog2(int'(CLKWAIT_US*CLK_FREQ/1e6));

reg ps2_clk_prev, ps2_clk, ps2_dat;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		ps2_dat <= 1'b1;
    ps2_clk <= 1'b1;
		ps2_clk_prev <= 1'b1;
	end
	else begin
		ps2_dat <= ps2_dat_in;
		ps2_clk <= ps2_clk_in;
		ps2_clk_prev <= ps2_clk;
	end
end

reg [CLKWAIT_WIDTH-1:0] wait_cnt;
reg [3:0] bit_cnt;
reg [9:0] rxbits;
assign dataout = rxbits[8:1];
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		dataout_valid <= 0;
		dataout_error <= 0;
		wait_cnt <= 0;
		bit_cnt <= 0;
		rxbits <= 0;
		ps2_clk_out <= 1'b1;
		ps2_dat_out <= 1'b1;
	end
	else begin
		dataout_valid <= 0;
		dataout_error <= 0;
		if (ps2_clk == 0 && ps2_clk_prev == 1'b1) begin
			if (bit_cnt == 4'd10) begin
				bit_cnt <= 0;
				if (rxbits[0] == 0 && ~rxbits[9] == ^rxbits[8:1] && ps2_dat == 1'b1)
					dataout_valid <= 1'b1;
				else
					dataout_error <= 1'b1;
			end
			else begin
				bit_cnt <= bit_cnt + 1'b1;
				rxbits <= {ps2_dat, rxbits[9:1]};
			end
			wait_cnt <= 0;
		end
		else if (bit_cnt != 0) begin
			if (&wait_cnt) begin
				bit_cnt <= 0;
				dataout_error <= 1'b1;
			end
			wait_cnt <= wait_cnt + 1'b1;
		end
	end	
end


endmodule
