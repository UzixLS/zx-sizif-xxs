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


localparam CLKWAIT_US = 1;
localparam TOUT_US = 200;
localparam CLKWAIT_TICKS = int'(CLKWAIT_US*CLK_FREQ/1e6) + 1'b1;
localparam TOUT_TICKS = int'(TOUT_US*CLK_FREQ/1e6) + 1'b1;
reg [$clog2(TOUT_TICKS)-1:0] timer;


reg ps2_dat;
reg [1:0] ps2_clk;
wire ps2_clk_fall = ps2_clk[0] == 0 && ps2_clk[1] == 1'b1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ps2_dat <= 1'b1;
        ps2_clk <= 2'b11;
    end
    else begin
        ps2_dat <= ps2_dat_in;
        ps2_clk <= {ps2_clk[0], ps2_clk_in};
    end
end


reg [3:0] bit_cnt;
reg [9:0] rxbits;
assign dataout = rxbits[8:1];
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dataout_valid <= 0;
        dataout_error <= 0;
        timer <= 0;
        bit_cnt <= 0;
        rxbits <= 0;
    end
    else begin
        dataout_valid <= 0;
        dataout_error <= 0;
        if (ps2_clk_fall) begin
            timer <= 1'b1;
        end
        else if (timer != 0) begin
            if (timer == CLKWAIT_TICKS && !ps2_clk) begin
                if (bit_cnt == 4'd10) begin
                    if (rxbits[0] == 0 && ~rxbits[9] == ^rxbits[8:1] && ps2_dat == 1'b1)
                        dataout_valid <= 1'b1;
                    else
                        dataout_error <= 1'b1;
                    bit_cnt <= 0;
                end
                else begin
                    rxbits <= {ps2_dat, rxbits[9:1]};
                    bit_cnt <= bit_cnt + 1'b1;
                end
            end
            else if (timer == TOUT_TICKS) begin
                dataout_error <= bit_cnt != 0;
                bit_cnt <= 0;
            end
            timer <= timer + 1'b1;
        end
    end
end


// No transmitter yet
assign ps2_clk_out = 1'b1;
assign ps2_dat_out = 1'b1;


endmodule
