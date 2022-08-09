import common::*;

module zx_ula(
    input clk_in,

    output reg n_rstcpu,
    output reg clkcpu,

    inout [18:0] va,
    inout [7:0] vd,
    input [15:13] a,

    output n_vrd,
    output n_vwr,

    input n_rd,
    input n_wr,
    input n_mreq,
    input n_iorq,
    input n_m1,
    input n_rfsh,
    output reg n_int,
    output n_nmi,

    output [7:0] composite,
    input [1:0] reserv,

    output snd_l,
    output snd_r,

    input ps2_clk,
    input ps2_dat,

    input sd_cd,
    input sd_miso_tape_in,
    output sd_mosi_tape_out,
    output reg sd_sck,
    output reg sd_cs
);

/* CLOCK */
wire clk28 = clk_in;
wire clk168;
wire rst_n;
pll pll0(.inclk0(clk_in), .c0(clk168), .locked(rst_n));
reg [1:0] clk168_en42_cnt = 0;
reg clk168_en42;
always @(posedge clk168) begin
    clk168_en42 <= clk168_en42_cnt == 2'b00;
    clk168_en42_cnt <= clk168_en42_cnt + 1'b1;
end


/* SHARED DEFINITIONS */
machine_t machine;
turbo_t turbo;
wire ps2_key_reset, ps2_key_pause;
wire [2:0] border;
wire magic_reboot, magic_beeper;
wire up_active;
wire clkwait;
wire [2:0] rampage128;
wire div_wait;
wire init_done;
wire screen_fetch, screen_fetch_next;


/* CPU BUS */
cpu_bus bus();
reg bus_memreq, bus_ioreq;
always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n) begin
        bus_ioreq <= 0;
        bus_memreq <= 0;
    end
    else if (!screen_fetch && !screen_fetch_next) begin
        bus.a_reg <= bus.a;
        bus.d_reg <= bus.d;
        bus_ioreq <= n_iorq == 1'b0 && n_m1 == 1'b1;
        bus_memreq <= n_mreq == 1'b0 && n_rfsh == 1'b1;
    end
    else begin
        if (n_iorq)
            bus_ioreq <= 0;
        if (n_mreq)
            bus_memreq <= 0;
    end
end
assign bus.a = {a[15:13], va[12:0]};
assign bus.d = vd;
assign bus.iorq = ~n_iorq;
assign bus.mreq = ~n_mreq;
assign bus.m1 = ~n_m1;
assign bus.rfsh = ~n_rfsh;
assign bus.rd = ~n_rd;
assign bus.wr = ~n_wr;
assign bus.ioreq = bus_ioreq & ~n_iorq;
assign bus.memreq = bus_memreq & ~n_mreq;


/* RESET */
reg usrrst_n = 0;
always @(posedge clk28) begin
    usrrst_n <= (!rst_n || ps2_key_reset || magic_reboot)? 1'b0 : 1'b1;
end


/* SCREEN CONTROLLER */
wire blink;
wire [2:0] screen_border = {border[2] ^ ~sd_cs, border[1] ^ magic_beeper, border[0]};
wire [5:0] r, g, b;
wire hsync, vsync, csync0;
wire screen_contention, port_ff_active;
wire [14:0] screen_addr;
wire [5:0] up_ink_addr, up_paper_addr;
wire [7:0] up_ink, up_paper;
wire [8:0] vc, hc;
wire [7:0] port_ff_data;
wire clk14, clk7, clk35, ck14, ck7, ck35;
screen screen0(
    .rst_n(usrrst_n),
    .clk28(clk28),

    .machine(machine),
    .border(screen_border),

    .r(r),
    .g(g),
    .b(b),
    .csync(csync0),
    .vsync(vsync),
    .hsync(hsync),

    .fetch_allow((!bus.iorq && !bus.mreq) || bus.rfsh || clkwait),
    .fetch(screen_fetch),
    .addr(screen_addr),
    .fetch_next(screen_fetch_next),
    .fetch_data(bus.d),

    .up_en(up_active),
    .up_ink_addr(up_ink_addr),
    .up_paper_addr(up_paper_addr),
    .up_ink(up_ink),
    .up_paper(up_paper),

    .contention(screen_contention),
    .blink(blink),
    .port_ff_active(port_ff_active),
    .port_ff_data(port_ff_data),

    .vc_out(vc),
    .hc_out(hc),
    .clk14(clk14),
    .clk7(clk7),
    .clk35(clk35),
    .ck14(ck14),
    .ck7(ck7),
    .ck35(ck35)
);


/* VIDEO OUTPUT */
vencode vencode(
    .clk(clk168),
    .clk_en(clk168_en42),
    .videoR(r),
    .videoG(g),
    .videoB(b),
    .videoHS_n(hsync),
    .videoVS_n(vsync),
    .videoPS_n(csync0),
    .videoV(composite)
);


/* PS/2 KEYBOARD */
wire [4:0] ps2_kd;
wire ps2_key_magic;
wire ps2_joy_up, ps2_joy_down, ps2_joy_left, ps2_joy_right, ps2_joy_fire;
ps2 #(.CLK_FREQ(28_000_000)) ps2_0(
    .rst_n(rst_n),
    .clk(clk28),
    .ps2_clk_in(ps2_clk),
    .ps2_dat_in(ps2_dat),
    .zxkb_addr(bus.a_reg[15:8]),
    .zxkb_data(ps2_kd),
    .key_magic(ps2_key_magic),
    .key_reset(ps2_key_reset),
    .key_pause(ps2_key_pause),
    .joy_up(ps2_joy_up),
    .joy_down(ps2_joy_down),
    .joy_left(ps2_joy_left),
    .joy_right(ps2_joy_right),
    .joy_fire(ps2_joy_fire)
);


/* CPU CONTROLLER */
wire n_int_next, clkcpu_ck, snow;
cpucontrol cpucontrol0(
    .rst_n(usrrst_n),
    .clk28(clk28),
    .clk14(clk14),
    .clk7(clk7),
    .clk35(clk35),
    .ck14(ck14),
    .ck7(ck7),

    .bus(bus),

    .vc(vc),
    .hc(hc),
    .rampage128(rampage128),
    .machine(machine),
    .screen_contention(screen_contention),
    .turbo(turbo),
    .ext_wait_cycle(div_wait),
    .init_done_in(init_done),

    .n_rstcpu(n_rstcpu),
    .clkcpu(clkcpu),
    .clkcpu_ck(clkcpu_ck),
    .clkwait(clkwait),
    .n_int(n_int),
    .n_int_next(n_int_next),
    .snow(snow)
);


/* MAGIC */
wire div_automap;
wire [7:0] magic_dout;
wire magic_dout_active;
wire magic_mode, magic_map;
wire joy_sinclair, up_en, ay_en, covox_en, soundrive_en;
panning_t panning;
wire divmmc_en, zc_en;

magic magic0(
    .rst_n(n_rstcpu),
    .clk28(clk28),

    .bus(bus),
    .d_out(magic_dout),
    .d_out_active(magic_dout_active),

    .n_int(n_int),
    .n_int_next(n_int_next),
    .n_nmi(n_nmi),

    .magic_button(ps2_key_magic),
    .pause_button(ps2_key_pause),
    .div_automap(div_automap),

    .magic_mode(magic_mode),
    .magic_map(magic_map),

    .magic_reboot(magic_reboot),
    .magic_beeper(magic_beeper),
    .machine(machine),
    .turbo(turbo),
    .joy_sinclair(joy_sinclair),
    .panning(panning),
    .divmmc_en(divmmc_en),
    .zc_en(zc_en),
    .ulaplus_en(up_en),
    .ay_en(ay_en),
    .covox_en(covox_en),
    .soundrive_en(soundrive_en)
);


/* PORTS */
wire [7:0] ports_dout;
wire ports_dout_active;
wire beeper, tape_out;
wire screenpage;
wire rompage128;
wire [2:0] rampage_ext;
wire [2:0] port_1ffd;
wire [4:0] port_dffd;
ports ports0 (
    .rst_n(n_rstcpu),
    .clk28(clk28),

    .bus(bus),
    .d_out(ports_dout),
    .d_out_active(ports_dout_active),

    .en_kempston(!joy_sinclair),
    .en_sinclair(joy_sinclair),

    .machine(machine),
    .port_ff_active(port_ff_active),
    .port_ff_data(port_ff_data),
    .kd(ps2_kd),
    .kempston_data({3'b000, ps2_joy_fire, ps2_joy_up, ps2_joy_down, ps2_joy_left, ps2_joy_right}),
    .magic_map(magic_map),
    .tape_in(sd_miso_tape_in),

    .tape_out(tape_out),
    .beeper(beeper),
    .border(border),
    .screenpage(screenpage),
    .rompage128(rompage128),
    .rampage128(rampage128),
    .rampage_ext(rampage_ext),
    .port_1ffd(port_1ffd),
    .port_dffd(port_dffd)
);


/* AY TURBOSOUND */
wire turbosound_dout_active;
wire [7:0] turbosound_dout;
wire [7:0] ay_a0, ay_b0, ay_c0, ay_a1, ay_b1, ay_c1;
turbosound turbosound0(
    .rst_n(n_rstcpu),
    .clk28(clk28),
    .ck35(ck35),
    .en(ay_en),
    .en_ts(1'b1),

    .bus(bus),
    .d_out(turbosound_dout),
    .d_out_active(turbosound_dout_active),

    .ay_a0(ay_a0),
    .ay_b0(ay_b0),
    .ay_c0(ay_c0),
    .ay_a1(ay_a1),
    .ay_b1(ay_b1),
    .ay_c1(ay_c1)
);


/* COVOX & SOUNDRIVE */
wire [7:0] soundrive_l0, soundrive_l1, soundrive_r0, soundrive_r1;
soundrive soundrive0(
    .rst_n(usrrst_n),
    .clk28(clk28),
    .en_covox(covox_en),
    .en_soundrive(soundrive_en),

    .bus(bus),

    .ch_l0(soundrive_l0),
    .ch_l1(soundrive_l1),
    .ch_r0(soundrive_r0),
    .ch_r1(soundrive_r1)
);


/* SOUND MIXER */
mixer mixer0(
    .rst_n(usrrst_n),
    .clk28(clk28),

    .beeper(beeper ^ magic_beeper),
    .tape_out(tape_out),
    .tape_in(sd_miso_tape_in),
    .ay_a0(ay_a0),
    .ay_b0(ay_b0),
    .ay_c0(ay_c0),
    .ay_a1(ay_a1),
    .ay_b1(ay_b1),
    .ay_c1(ay_c1),
    .sd_l0(soundrive_l0),
    .sd_l1(soundrive_l1),
    .sd_r0(soundrive_r0),
    .sd_r1(soundrive_r1),

    .ay_acb(panning == PANNING_ACB),
    .mono(panning == PANNING_MONO),

    .dac_l(snd_l),
    .dac_r(snd_r)
);


/* DIVMMC */
wire div_map, div_ram, div_ramwr_mask, div_dout_active;
wire [7:0] div_dout;
wire [3:0] div_page;
wire sd_mosi0;
divmmc divmmc0(
    .rst_n(n_rstcpu),
    .clk28(clk28),
    .ck14(ck14),
    .ck7(ck7),
    .en(divmmc_en),
    .en_hooks(divmmc_en),
    .en_zc(zc_en),

    .bus(bus),
    .d_out(div_dout),
    .d_out_active(div_dout_active),

    .sd_cd(sd_cd),
    .sd_miso(sd_miso_tape_in),
    .sd_mosi(sd_mosi0),
    .sd_sck(sd_sck),
    .sd_cs(sd_cs),

    .rammap(port_dffd[4] | port_1ffd[0]),
    .magic_mode(magic_mode),
    .magic_map(magic_map),

    .page(div_page),
    .map(div_map),
    .automap(div_automap),
    .ram(div_ram),
    .ramwr_mask(div_ramwr_mask),
    .cpuwait(div_wait)
);
assign sd_mosi_tape_out = (!divmmc_en && !zc_en)? tape_out : sd_mosi0;


/* ULAPLUS */
wire up_dout_active;
wire [7:0] up_dout;
ulaplus ulaplus0(
    .rst_n(n_rstcpu),
    .clk28(clk28),
    .en(up_en),

    .bus(bus),
    .d_out(up_dout),
    .d_out_active(up_dout_active),

    .active(up_active),
    .ink_addr(up_ink_addr),
    .paper_addr(up_paper_addr),
    .ink(up_ink),
    .paper(up_paper)
);


/* MEMORY INITIALIZER */
wire rom2ram_clk = clk7;
wire [16:0] rom2ram_ram_address, rom2ram_rom_address;
wire [7:0] rom2ram_datain, rom2ram_dataout;
wire rom2ram_rom_rden;
wire rom2ram_rom_data_ready;
wire rom2ram_ram_wren;
wire rom2ram_active;
assign init_done = !rom2ram_active;
reg [1:0] rom2ram_init;
always @(posedge rom2ram_clk or negedge rst_n) begin
    if (!rst_n)
        rom2ram_init <= 0;
    else if (rom2ram_init != 3)
        rom2ram_init <= rom2ram_init + 1'b1;
end
rom2ram rom2ram0(
    .clock(rom2ram_clk),
    .init(rom2ram_init == 2),
    .datain(rom2ram_datain),
    .rom_data_ready(rom2ram_rom_data_ready),

    .init_busy(rom2ram_active),
    .rom_address(rom2ram_rom_address),
    .rom_rden(rom2ram_rom_rden),
    .ram_wren(rom2ram_ram_wren),
    .ram_address(rom2ram_ram_address),
    .dataout(rom2ram_dataout)
);

localparam ROM_OFFSET = 24'h13256;
wire [23:0] asmi_addr = ROM_OFFSET + rom2ram_rom_address;
asmi asmi0(
    .clkin(rom2ram_clk),
    .read(rom2ram_rom_rden),
    .rden(rom2ram_active),
    .addr(asmi_addr),
    .reset(!rst_n),

    .dataout(rom2ram_datain),
    .busy(),
    .data_valid(rom2ram_rom_data_ready)
);


/* MEMORY CONTROLLER */
memcontrol memcontrol0(
    .clk28(clk28),
    .bus(bus),
    .va(va),
    .vd(vd),
    .n_vrd(n_vrd),
    .n_vwr(n_vwr),

    .machine(machine),
    .screenpage(screenpage),
    .screen_fetch(screen_fetch),
    .snow(snow),
    .screen_addr(screen_addr),
    .magic_map(magic_map),
    .rampage128(rampage128),
    .rompage128(rompage128),
    .port_1ffd(port_1ffd),
    .port_dffd(port_dffd),
    .rampage_ext(rampage_ext),
    .divmmc_en(divmmc_en),
    .div_ram(div_ram),
    .div_map(div_map),
    .div_ramwr_mask(div_ramwr_mask),
    .div_page(div_page),

    .rom2ram_ram_address(rom2ram_ram_address),
    .rom2ram_ram_wren(rom2ram_ram_wren),
    .rom2ram_dataout(rom2ram_dataout),
    .magic_dout_active(magic_dout_active),
    .magic_dout(magic_dout),
    .up_dout_active(up_dout_active),
    .up_dout(up_dout),
    .div_dout_active(div_dout_active),
    .div_dout(div_dout),
    .turbosound_dout_active(turbosound_dout_active),
    .turbosound_dout(turbosound_dout),
    .ports_dout_active(ports_dout_active),
    .ports_dout(ports_dout)
);


endmodule
