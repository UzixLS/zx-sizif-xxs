`timescale 1ns/100ps
module testbench_zx_ula();

reg rst_n;
reg clk28;


/* CPU */
wire clkcpu;
wire n_rstcpu;
wire [15:0] a_cpu, a_cpu_cpu;
wire [7:0] d_cpu_o, d_cpu_i;
wire n_rd, n_rd_cpu;
wire n_wr, n_wr_cpu;
wire n_iorq, n_iorq_cpu;
wire n_mreq, n_mreq_cpu;
wire n_m1, n_m1_cpu;
wire n_rfsh, n_rfsh_cpu;
wire n_int;
wire n_nmi;

T80na cpu1(
    .RESET_n(n_rstcpu),
    .CLK_n(clkcpu),
    .WAIT_n(1'b1),
    .INT_n(n_int),
    .NMI_n(n_nmi),
    .BUSRQ_n(1'b1),
    .M1_n(n_m1_cpu),
    .MREQ_n(n_mreq_cpu),
    .IORQ_n(n_iorq_cpu),
    .RD_n(n_rd_cpu),
    .WR_n(n_wr_cpu),
    .RFSH_n(n_rfsh_cpu),
    .HALT_n(),
    .BUSAK_n(),
    .A(a_cpu_cpu),
    .D_i(d_cpu_i),
    .D_o(d_cpu_o)
);

// z80_top_direct_n cpu1(
//     .nM1(n_m1_cpu),
//     .nMREQ(n_mreq_cpu),
//     .nIORQ(n_iorq_cpu),
//     .nRD(n_rd_cpu),
//     .nWR(n_wr_cpu),
//     .nRFSH(n_rfsh_cpu),
//     .nWAIT(1'b1),
//     .nINT(n_int),
//     .nNMI(n_nmi),
//     .nRESET(rstcpu_n),
//     .nBUSRQ(1'b1),
//     .CLK(clkcpu),
//     .A(a_cpu_cpu),
//     .D(d_cpu_o)
// );
// assign d_cpu_o = n_wr? d_cpu_i : {8{1'bz}};


/* ULA */
wire [7:0] vd;
wire [18:0] va;
wire [16:14] ra;
wire m_romcs;
wire n_vrd;
wire n_vwr;
wire dout;
wire vdout;
wire n_iorqge;
reg n_magic;
wire sd_mosi_miso;
zx_ula zx_ula1(
    .clk_in(clk28),
    .clkcpu(clkcpu),
    .n_rstcpu(n_rstcpu),
    .a(a_cpu[15:13]),
    .vd(vd),
    .va(va),
    .n_vrd(n_vrd),
    .n_vwr(n_vwr),
    .n_rd(n_rd),
    .n_wr(n_wr),
    .n_mreq(n_mreq),
    .n_iorq(n_iorq),
    .n_m1(n_m1),
    .n_rfsh(n_rfsh),
    .n_int(n_int),
    .n_nmi(n_nmi),
    .sd_cd(1'b1),
    .sd_cs(),
    .sd_sck(),
    .sd_mosi_tape_out(sd_mosi_miso),
    .sd_miso_tape_in(sd_mosi_miso),
    .ps2_clk(),
    .ps2_dat()
    );


/* MEMORY */
reg [7:0] ram [0:524288];
wire [15:0] ram_addr_a = va;
reg [15:0] ram_addr_a0;
wire [7:0] ram_q_a = ram[ram_addr_a0];

always @(posedge clk28) begin
    if (n_vwr == 0) begin
        ram[ram_addr_a] <= vd;
    end
    ram_addr_a0 <= ram_addr_a;
end
initial begin
    integer i;
    for (i = 64*1024; i < 524288; i++)
        ram[i] <= 0;
    $readmemh("rom.mem", ram);
end


/* BUS ARBITER */
assign (weak0, weak1) va[15:0] = a_cpu;
assign vd = ~n_vrd? ram_q_a : {8{1'bz}};
assign (weak0, weak1) vd = d_cpu_o;
assign d_cpu_i = vd;


/* CPU SIGNALS (ideal timings) */
// assign n_rd = n_rd_cpu;
// assign n_wr = n_wr_cpu;
// assign n_iorq = n_iorq_cpu;
// assign n_mreq = n_mreq_cpu;
// assign n_m1 = n_m1_cpu;
// assign n_rfsh = n_rfsh_cpu;
// assign a_cpu = a_cpu_cpu;

/* CPU SIGNALS (Z84C0020 timings) */
assign #40 n_rd = n_rd_cpu; //TdCf(RDf)
assign #40 n_wr = n_wr_cpu; //TdCf(WRf)
assign #40 n_iorq = n_iorq_cpu; //TdCr(IORQf)
assign #40 n_mreq = n_mreq_cpu; //TdCf(MREQf)
assign #45 n_m1 = n_m1_cpu; //TdCr(M1f)
assign #60 n_rfsh = n_rfsh_cpu; //TdCr(RFSHf)
assign #57 a_cpu = a_cpu_cpu; //TdCr(A)

/* CPU SIGNALS (Z84C0008 timings) */
//assign #70 n_rd = n_rd_cpu; //TdCf(RDf)
//assign #60 n_wr = n_wr_cpu; //TdCf(WRf)
//assign #55 n_iorq = n_iorq_cpu; //TdCr(IORQf)
//assign #60 n_mreq = n_mreq_cpu; //TdCf(MREQf)
//assign #70 n_m1 = n_m1_cpu; //TdCr(M1f)
//assign #95 n_rfsh = n_rfsh_cpu; //TdCr(RFSHf)
//assign #80 a_cpu = a_cpu_cpu; //TdCr(A)

/* CPU SIGNALS (Z84C0004 timings) */
// assign #85 n_rd = n_rd_cpu; //TdCf(RDf)
// assign #80 n_wr = n_wr_cpu; //TdCf(WRf)
// assign #75 n_iorq = n_iorq_cpu; //TdCr(IORQf)
// assign #85 n_mreq = n_mreq_cpu; //TdCf(MREQf)
// assign #100 n_m1 = n_m1_cpu; //TdCr(M1f)
// assign #130 n_rfsh = n_rfsh_cpu; //TdCr(RFSHf)
// assign #110 a_cpu = a_cpu_cpu; //TdCr(A)


/* SIMULATION SIGNALS */
initial begin
    n_magic = 1;
    #50000
    // n_magic = 0;
    #50000
    n_magic = 1;
end


/* CLOCKS & RESET */
initial begin
    rst_n = 0;
    #300 rst_n = 1;
end

always begin
    clk28 = 0;
    #17.8 clk28 = 1;
    #17.9;
end


/* TESTBENCH CONTROL */
initial begin
    $dumpfile("testbench_zx_ula.vcd");
    $dumpvars;
    #500_000 $finish;
    // #21_000_000 $finish;
    // #41_000_000 $finish;
end


always @(clk28) begin
    // if (v > 100) $dumpoff;
    // if (~n_iorq) $dumpon;
    // if (v == 1 && ovf == 1) $finish;
end



endmodule
