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

    input ay_acb,
    input mono,

    output dac_l,
    output dac_r
);

localparam WIDTH = 13;

reg [WIDTH:0] dac_l_cnt, dac_r_cnt;
assign dac_l = dac_l_cnt[WIDTH];
assign dac_r = dac_r_cnt[WIDTH];

wire [WIDTH-1:0] dac_next_l =
    {ay_a0, 1'b0} +
    (ay_acb? ay_c0 : ay_b0) +
    {ay_a1, 1'b0} +
    {1'b0, ay_b1} +
    {sd_l0, 1'b0} +
    {sd_l1, 1'b0}
    ;
wire [WIDTH-1:0] dac_next_r =
    (ay_acb? {ay_b0, 1'b0} : {ay_c0, 1'b0}) +
    (ay_acb? ay_c0 : ay_b0) +
    {1'b0, ay_b1} +
    {ay_c1, 1'b0} +
    {sd_r0, 1'b0} +
    {sd_r1, 1'b0}
    ;

wire [WIDTH-1:0] dac_next_lr = {beeper, tape_out, tape_in, 7'd0};

always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n) begin
        dac_l_cnt <= 0;
        dac_r_cnt <= 0;
    end
    else begin
        dac_l_cnt <= dac_l_cnt[WIDTH-1:0] + dac_next_lr + dac_next_l + (mono? dac_next_r : {WIDTH{1'b0}});
        dac_r_cnt <= dac_r_cnt[WIDTH-1:0] + dac_next_lr + dac_next_r + (mono? dac_next_l : {WIDTH{1'b0}});
    end
end

endmodule
