import common::*;
module cpu(
    input rst_n,
    input clk28,
    input clk14,
    input clk7,
    input clk35,
    input ck14,
    input ck7,

    cpu_bus bus,

    input [8:0] vc,
    input [8:0] hc,
    input video_contention,
    input [2:0] ram_page128,
    input machine_t machine,
    input turbo_t turbo,
    input init_done_in,

    output reg n_rstcpu_out,
    output reg clkcpu,
    output clkcpu_ck,
    output clkcpu_stall,
    output reg n_int,
    output n_int_next,
    output snow
);


/* CONTENTION */
wire iorq_contended = bus.iorq && (~bus.a[0] || (~bus.a[1] && ~bus.a_raw[15] && bus.wr)) && (machine != MACHINE_S3);
reg mreq_delayed, iorq_delayed;
always @(negedge clk28) if (clkcpu_ck)
    mreq_delayed <= bus.mreq;
always @(negedge clk28) if (clkcpu_ck)
    iorq_delayed <= bus.iorq && ~bus.a[0];
wire contention_mem_page = (machine == MACHINE_S3)? ram_page128[2] : ram_page128[0];
wire contention_mem_addr = bus.a_raw[14] & (~bus.a_raw[15] | (bus.a_raw[15] & contention_mem_page));
wire contention_mem = iorq_delayed == 1'b0 && mreq_delayed == 1'b0 && contention_mem_addr;
wire contention_io = iorq_delayed == 1'b0 && iorq_contended;
wire contention0 = video_contention && (contention_mem || contention_io);
wire contention = clkcpu && contention0 && turbo == TURBO_NONE && (machine == MACHINE_S48 || machine == MACHINE_S128 || machine == MACHINE_S3);
assign snow = bus.a_raw[14] && ~bus.a_raw[15] && bus.rfsh && (machine == MACHINE_S48 || machine == MACHINE_S128);


/* CLOCK */
reg [3:0] turbo_wait;
wire turbo_wait_trig0 = turbo == TURBO_14 && bus.mreq && !bus.rfsh;
wire turbo_wait_trig1 = turbo == TURBO_14 && (bus.rd || bus.wr);
reg turbo_wait_trig0_prev, turbo_wait_trig1_prev;
always @(posedge clk28) begin
    turbo_wait[0] <= turbo_wait_trig0 && !turbo_wait_trig0_prev;
    turbo_wait[1] <= turbo_wait[0] || (turbo_wait_trig1 && !turbo_wait_trig1_prev);
    turbo_wait[2] <= turbo_wait[1];
    turbo_wait[3] <= turbo_wait[2];
    turbo_wait_trig0_prev <= turbo_wait_trig0;
    turbo_wait_trig1_prev <= turbo_wait_trig1;
end

reg clkcpu_prev;
assign clkcpu_ck = clkcpu && !clkcpu_prev;
assign clkcpu_stall = contention || (|turbo_wait[3:1]);
always @(posedge clk28) begin
    clkcpu_prev <= clkcpu;
    if (clkcpu_stall)
        clkcpu <= clkcpu;
    else if (turbo == TURBO_14)
        clkcpu <= clk14;
    else if (turbo == TURBO_7 && ck14)
        clkcpu <= clk7;
    else if (turbo == TURBO_5 && ck14 && hc[1])
        clkcpu <= clk7;
    else if (turbo == TURBO_4 && ck14 && hc[1] && hc[2])
        clkcpu <= clk7;
    else if (ck7)
        clkcpu <= clk35;
end


/* INT GENERATOR */
localparam INT_V_S48       = 248;
localparam INT_H_S48       = 0;
localparam INT_L_S48       = 6'd32;
localparam INT_V_S128      = 248;
localparam INT_H_S128      = 4;
localparam INT_L_S128      = 6'd36;
localparam INT_V_PENT      = 239;
localparam INT_H_PENT      = 322;
localparam INT_L_PENT      = 6'd32;
wire int_begin =
    (machine == MACHINE_S48)?
        vc == INT_V_S48 && hc == INT_H_S48 :
    (machine == MACHINE_S128 || machine == MACHINE_S3)?
        vc == INT_V_S128 && hc == INT_H_S128 :
    // Pentagon
        vc == INT_V_PENT && hc == INT_H_PENT ;
wire [5:0] int_len =
    (machine == MACHINE_S48)?
        INT_L_S48 :
    (machine == MACHINE_S128 || machine == MACHINE_S3)?
        INT_L_S128 :
    // Pentagon
        INT_L_PENT ;

reg [5:0] int_cnt;
always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n) begin
        int_cnt <= 0;
        n_int_next <= 1'b1;
    end
    else if ((int_cnt != 0 && clkcpu_ck) || (int_cnt == 0 && int_begin)) begin
        int_cnt <= int_cnt + 1'b1;
        n_int_next <= (int_cnt < int_len)? 1'b0 : 1'b1;
    end
end

always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n)
        n_int <= 1'b1;
    else if (clkcpu_ck)
        n_int <= n_int_next;
end


/* RESET */
always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n)
        n_rstcpu_out <= 0;
    else if (!init_done_in)
        n_rstcpu_out <= 0;
`ifdef TESTBENCH
    else if (hc[4])
        n_rstcpu_out <= 1'b1;
`endif
    else if (vc[8])
        n_rstcpu_out <= 1'b1;
end


/* T-STATES COUNTER (for debug) */
`ifdef TESTBENCH
integer tstate;
always @(posedge clkcpu) begin
    if (!n_int_next && n_int)
        tstate <= -1;
    else
        tstate <= tstate + 1;
end
`endif


endmodule