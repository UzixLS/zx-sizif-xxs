`include "ps2_codes.vh"

module ps2#(
	parameter CLK_FREQ
	) (
	input rst_n,
	input clk,
	
	input ps2_clk_in,
	input ps2_dat_in,
	output ps2_clk_out,
	output ps2_dat_out,
	
	input [7:0] zxkb_addr,
	output [4:0] zxkb_data,
	output reg key_magic,
	output reg key_reset
);


/*         KD0 KD1 KD2 KD3 KD4
 * KA8(0)   cs   z   x   c   v
 * KA9(1)    a   s   d   f   g
 * KA10(2)   q   w   e   r   t 
 * KA11(3)   1   2   3   4   5
 * KA12(4)   0   9   8   7   6
 * KA13(5)   p   o   i   u   y
 * KA14(6)  en   l   k   j   h
 * KA15(7)  sp  ss   m   n   b
 */
 

reg rxdone;
reg rxerr;
reg [7:0] rxbyte;
ps2_rxtx #(.CLK_FREQ(CLK_FREQ)) ps2_rxtx0(
	.rst_n(rst_n),
	.clk(clk),
	.ps2_clk_in(ps2_clk_in),
	.ps2_dat_in(ps2_dat_in),
	.ps2_clk_out(ps2_clk_out),
	.ps2_dat_out(ps2_dat_out),
	.dataout(rxbyte),
	.dataout_valid(rxdone),
	.dataout_error(rxerr)
);


reg is_press;
reg is_ext;
reg [4:0] zxkb [0:7];
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
	  integer i;
		for (i = 0; i < 8; i = i + 1)
			zxkb[i] <= 0;
		is_press <= 0;
		is_ext <= 0;
		key_magic <= 0;
		key_reset <= 0;
	end
	else begin
		if (rxerr) begin
			is_press <= 0;
			is_ext <= 0;
		end
		else if (rxdone) begin
			is_press <= rxbyte != 8'hF0;
			is_ext <= rxbyte == 8'hE0 || (rxbyte == 8'hF0 && is_ext);
			case ({is_ext, rxbyte})
				`PS2_A: zxkb[1][0] = is_press;
				`PS2_B: zxkb[7][4] = is_press;
				`PS2_C: zxkb[0][3] = is_press;
				`PS2_D: zxkb[1][2] = is_press;
				`PS2_E: zxkb[2][2] = is_press;
				`PS2_F: zxkb[1][3] = is_press;
				`PS2_G: zxkb[1][4] = is_press;
				`PS2_H: zxkb[6][4] = is_press;
				`PS2_I: zxkb[5][2] = is_press;
				`PS2_J: zxkb[6][3] = is_press;
				`PS2_K: zxkb[6][2] = is_press;
				`PS2_L: zxkb[6][1] = is_press;
				`PS2_M: zxkb[7][2] = is_press;
				`PS2_N: zxkb[7][3] = is_press;
				`PS2_O: zxkb[5][1] = is_press;
				`PS2_P: zxkb[5][0] = is_press;
				`PS2_Q: zxkb[2][0] = is_press;
				`PS2_R: zxkb[2][3] = is_press;
				`PS2_S: zxkb[1][1] = is_press;
				`PS2_T: zxkb[2][4] = is_press;
				`PS2_U: zxkb[5][3] = is_press;
				`PS2_V: zxkb[0][4] = is_press;
				`PS2_W: zxkb[2][1] = is_press;
				`PS2_X: zxkb[0][2] = is_press;
				`PS2_Y: zxkb[5][4] = is_press;
				`PS2_Z: zxkb[0][1] = is_press;
				`PS2_0: zxkb[4][0] = is_press;
				`PS2_1: zxkb[3][0] = is_press;
				`PS2_2: zxkb[3][1] = is_press;
				`PS2_3: zxkb[3][2] = is_press;
				`PS2_4: zxkb[3][3] = is_press;
				`PS2_5: zxkb[3][4] = is_press;
				`PS2_6: zxkb[4][4] = is_press;
				`PS2_7: zxkb[4][3] = is_press;
				`PS2_8: zxkb[4][2] = is_press;
				`PS2_9: zxkb[4][1] = is_press;

				`PS2_SPACE: zxkb[7][0] = is_press;
				`PS2_ENTER: zxkb[6][0] = is_press;
				`PS2_ESC:       begin zxkb[0][0] = is_press; zxkb[7][0] = is_press; end
				`PS2_BACKSPACE: begin zxkb[0][0] = is_press; zxkb[4][0] = is_press; end
				
				`PS2_PERIOD:    begin zxkb[7][1] = is_press; zxkb[7][2] = is_press; end
				`PS2_COMMA:     begin zxkb[7][1] = is_press; zxkb[7][3] = is_press; end
				`PS2_SLASH:     begin zxkb[7][1] = is_press; zxkb[0][4] = is_press; end
				`PS2_SEMICOLON: begin zxkb[7][1] = is_press; zxkb[5][1] = is_press; end
				`PS2_QUOTE:     begin zxkb[7][1] = is_press; zxkb[5][0] = is_press; end
				
				`PS2_UP:    begin zxkb[0][0] = is_press; zxkb[4][3] = is_press; end
				`PS2_DOWN:  begin zxkb[0][0] = is_press; zxkb[4][4] = is_press; end
				`PS2_LEFT:  begin zxkb[0][0] = is_press; zxkb[3][4] = is_press; end
				`PS2_RIGHT: begin zxkb[0][0] = is_press; zxkb[4][2] = is_press; end
				
				`PS2_L_SHIFT: zxkb[7][1] = is_press;
				`PS2_R_SHIFT: zxkb[7][1] = is_press;
				`PS2_L_CTRL: zxkb[0][0] = is_press;
				`PS2_R_CTRL: zxkb[0][0] = is_press;
				
				`PS2_F5: key_magic = is_press;
				`PS2_F12: key_reset = is_press;
			endcase
		end
	end
end


always @* begin
	zxkb_data <= ~(
		((~zxkb_addr[0])? zxkb[0] : 5'd0) |
		((~zxkb_addr[1])? zxkb[1] : 5'd0) |
		((~zxkb_addr[2])? zxkb[2] : 5'd0) |
		((~zxkb_addr[3])? zxkb[3] : 5'd0) |
		((~zxkb_addr[4])? zxkb[4] : 5'd0) |
		((~zxkb_addr[5])? zxkb[5] : 5'd0) |
		((~zxkb_addr[6])? zxkb[6] : 5'd0) |
		((~zxkb_addr[7])? zxkb[7] : 5'd0)
	);
end

endmodule
