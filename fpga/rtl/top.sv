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

    output reg [5:0] luma,
    output reg [2:0] chroma,
    output reg csync,

    output snd_l,
    output snd_r,

    input ps2_clk,
    input ps2_dat,

    input sd_cd,
    input sd_miso_tape_in,
    output sd_mosi,
    output reg sd_sck,
    output reg sd_cs
);

/* CLOCK */
wire clk28 = clk_in;
wire clk40;
wire clk20;
wire rst_n;
pll pll0(.inclk0(clk_in), .c0(clk40), .c1(clk20), .locked(rst_n));


/* SHARED DEFINITIONS */
timings_t timings;
turbo_t turbo;
rammode_t ram_mode;
wire ps2_key_pause, ps2_key_reset;
wire pause = ps2_key_pause;
wire [2:0] border;
wire magic_reboot, magic_beeper;
wire up_en;
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
        bus_memreq <= n_mreq == 1'b0;
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
always @(posedge clk28)
    usrrst_n <= (!rst_n || ps2_key_reset || magic_reboot)? 1'b0 : 1'b1;



/* SCREEN CONTROLLER */
wire blink;
wire [2:0] screen_border = {border[2] ^ ~sd_cs, border[1] ^ magic_beeper, border[0] ^ (pause & blink)};
wire [2:0] r, g, b;
wire hsync;
wire [5:0] up_ink_addr, up_paper_addr;
wire [7:0] up_ink, up_paper;
wire screen_loading;
wire [14:0] screen_addr;
wire [7:0] attr_next;
wire [8:0] vc, hc;
wire clk14, clk7, clk35, ck14, ck7, ck35;
screen screen0(
    .rst_n(rst_n),
    .clk28(clk28),

    .timings(timings),
    .border(screen_border),

    .r(r),
    .g(g),
    .b(b),
    .csync(csync),
    .vsync(),
    .hsync(hsync),

    .fetch_allow((!bus.iorq && !bus.mreq && !bus.m1) || bus.rfsh || clkwait),
    .fetch(screen_fetch),
    .addr(screen_addr),
    .fetch_next(screen_fetch_next),
    .fetch_data(bus.d),

    .loading(screen_loading),
    .blink(blink),
    .attr_next(attr_next),

    .up_en(up_en),
    .up_ink_addr(up_ink_addr),
    .up_paper_addr(up_paper_addr),
    .up_ink(up_ink),
    .up_paper(up_paper),

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
always @*
    luma <= {g[2], r[2], b[2], g[1], r[1], b[1]};

wire [2:0] chroma0;
chroma_gen #(.CLK_FREQ(40_000_000)) chroma_gen1(
    .cg_clock(clk40),
    .cg_rgb({g[2],r[2],b[2]}),
    .cg_hsync(hsync),
    .cg_enable(1'b1),
    .cg_pnsel(1'b0),
    .cg_out(chroma0)
);
assign chroma[0] = (chroma0[2]|chroma0[1])? chroma0[0] : 1'bz;
assign chroma[1] = (chroma0[2]|chroma0[1])? chroma0[0] : 1'bz;
assign chroma[2] = (chroma0[2]|chroma0[1])? chroma0[0] : 1'bz;


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

    .bus(bus),

    .vc(vc),
    .hc(hc),
    .rampage128(rampage128),
    .screen_loading(screen_loading),
    .turbo(turbo),
    .timings(timings),
    .pause(pause),
    .ext_wait_cycle(div_wait || up_en),
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
wire magic_mode, magic_map;
wire divmmc_en, joy_sinclair, rom_plus3, rom_alt48, mix_acb, mix_mono;
magic magic0(
    .rst_n(usrrst_n),
    .clk28(clk28),

    .bus(bus),
    .n_int(n_int),
    .n_int_next(n_int_next),
    .n_nmi(n_nmi),

    .magic_button(ps2_key_magic),

    .magic_mode(magic_mode),
    .magic_map(magic_map),

    .magic_reboot(magic_reboot),
    .magic_beeper(magic_beeper),
    .timings(timings),
    .turbo(turbo),
    .ram_mode(ram_mode),
    .joy_sinclair(joy_sinclair),
    .rom_plus3(rom_plus3),
    .rom_alt48(rom_alt48),
    .mix_acb(mix_acb),
    .mix_mono(mix_mono),
    .divmmc_en(divmmc_en)
);


/* PORTS */
wire [7:0] ports_dout;
wire ports_dout_active;
wire beeper, tape_out;
wire screenpage;
wire rompage128;
wire [3:0] rampage_ext;
wire [2:0] port_1ffd;
wire port_dffd_d3;
wire port_dffd_d4;
ports ports0 (
    .rst_n(usrrst_n),
    .clk28(clk28),

    .bus(bus),
    .d_out(ports_dout),
    .d_out_active(ports_dout_active),

    .en_128k(ram_mode == RAM_512 || ram_mode == RAM_128),
    .en_plus3(rom_plus3),
    .en_profi(ram_mode == RAM_512),
    .en_kempston(!joy_sinclair),
    .en_sinclair(joy_sinclair),

    .timings(timings),
    .clkcpu_ck(clkcpu_ck),
    .screen_loading(screen_loading),
    .attr_next(attr_next),
    .kd(ps2_kd),
    .kempston_data({3'b000, ps2_joy_fire, ps2_joy_up, ps2_joy_down, ps2_joy_left, ps2_joy_right}),
    .magic_button(ps2_key_magic),
    .tape_in(sd_miso_tape_in),

    .tape_out(tape_out),
    .beeper(beeper),
    .border(border),
    .screenpage(screenpage),
    .rompage128(rompage128),
    .rampage128(rampage128),
    .rampage_ext(rampage_ext),
    .port_1ffd(port_1ffd),
    .port_dffd_d3(port_dffd_d3),
    .port_dffd_d4(port_dffd_d4)
);


/* AY TURBOSOUND */
wire turbosound_dout_active;
wire [7:0] turbosound_dout;
wire [7:0] ay_a0, ay_b0, ay_c0, ay_a1, ay_b1, ay_c1;
turbosound turbosound0(
    .rst_n(usrrst_n),
    .clk28(clk28),
    .ck35(ck35),
    .en(1'b1),
    .en_ts(1'b1),

    .bus(bus),
    .d_out(turbosound_dout),
    .d_out_active(turbosound_dout_active),

    .pause(pause),

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
    .en_covox(1'b1),
    .en_soundrive(1'b1),

    .bus(bus),

    .ch_l0(soundrive_l0),
    .ch_l1(soundrive_l1),
    .ch_r0(soundrive_r0),
    .ch_r1(soundrive_r1)
);


/* SOUND MIXER */
mixer mixer0(
    .rst_n(rst_n),
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

    .ay_acb(mix_acb),
    .mono(mix_mono),

    .dac_l(snd_l),
    .dac_r(snd_r)
);


/* DIVMMC */
wire div_map, div_ram, div_ramwr_mask, div_dout_active;
wire [7:0] div_dout;
wire [3:0] div_page;
wire sd_mosi0;
divmmc divmmc0(
    .rst_n(usrrst_n),
    .clk28(clk28),
    .ck14(ck14),
    .ck7(ck7),
    .en(divmmc_en),
    .en_hooks(~sd_cd),

    .bus(bus),
    .d_out(div_dout),
    .d_out_active(div_dout_active),

    .sd_miso(sd_miso_tape_in),
    .sd_mosi(sd_mosi0),
    .sd_sck(sd_sck),
    .sd_cs(sd_cs),
    
    .rammap(port_dffd_d4 | port_1ffd[0]),
    .magic_mode(magic_mode),
    .magic_map(magic_map),

    .div_page(div_page),
    .div_map(div_map),
    .div_ram(div_ram),
    .div_ramwr_mask(div_ramwr_mask),
    .div_wait(div_wait)
);
///assign sd_mosi = (sd_cs == 1'b0)? sd_mosi0 : tape_out;
assign sd_mosi = sd_mosi0;


/* ULAPLUS */
wire up_dout_active;
wire [7:0] up_dout;
ulaplus ulaplus0(
    .rst_n(usrrst_n),
    .clk28(clk28),
    .en(1'b1),
    
    .bus(bus),
    .d_out(up_dout),
    .d_out_active(up_dout_active),

    .active(up_en),
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
reg romreq, ramreq, ramreq_wr;
always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n) begin
        romreq = 1'b0;
        ramreq = 1'b0;
        ramreq_wr = 1'b0;
    end
    else begin
        romreq =  bus.mreq && !bus.rfsh && bus.a[14] == 0 && bus.a[15] == 0 &&
            (magic_map || (!div_ram && div_map) || (!div_ram && !port_dffd_d4 && !port_1ffd[0]));
        ramreq = bus.mreq && !bus.rfsh && !romreq;
        ramreq_wr = ramreq && bus.wr && div_ramwr_mask == 0;
    end
end

assign n_vrd = ((((ramreq || romreq) && bus.rd) || screen_fetch) && !rom2ram_ram_wren)? 1'b0 : 1'b1;
assign n_vwr = ((ramreq_wr && bus.wr && !screen_fetch) || rom2ram_ram_wren)? 1'b0 : 1'b1;

/* VA[18:13] map
 * 00xxxx 128Kb of roms
 * 00111x 16Kb of magic ram
 * 01xxxx 128Kb of divmmc memory
 * 10xxxx 128Kb of extended ram (via port dffd)
 * 11xxxx 128Kb of main ram
 */

reg [18:13] ram_a;
always @(posedge clk28) begin
    ram_a <=
        magic_map & bus.a[15] & bus.a[14]? {2'b00, 3'b111, bus.a[13]} :
        magic_map? {3'b111, screenpage, bus.a[14:13]} :
        div_map & ~bus.a[14] & ~bus.a[15] & bus.a[13]? {2'b01, div_page} :
        div_map & ~bus.a[14] & ~bus.a[15]? {2'b01, 4'b0011} :
        port_dffd_d3 & bus.a[15]? {2'b11, bus.a[14], bus.a[15], bus.a[14], bus.a[13]} :
        port_dffd_d3 & bus.a[14]? {1'b1, ~rampage_ext[0], rampage128, bus.a[13]} :
        (port_1ffd[2] == 1'b0 && port_1ffd[0] == 1'b1)? {2'b11, port_1ffd[1], bus.a[15], bus.a[14], bus.a[13]} :
        (port_1ffd == 3'b101)? {2'b11, ~(bus.a[15] & bus.a[14]), bus.a[15], bus.a[14]} :
        (port_1ffd == 3'b111)? {2'b11, ~(bus.a[15] & bus.a[14]), (bus.a[15] | bus.a[14]), bus.a[14]} :
        bus.a[15] & bus.a[14]? {1'b1, ~rampage_ext[0], rampage128, bus.a[13]} :
        {2'b11, bus.a[14], bus.a[15], bus.a[14], bus.a[13]} ;
end

reg [16:14] rom_a;
always @(posedge clk28) begin
    rom_a <=
        magic_map? 3'd2 :
        div_map? 3'd3 :
        (rom_plus3 && port_1ffd[2] == 1'b0 && rompage128 == 1'b0)? 3'd4 :
        (rom_plus3 && port_1ffd[2] == 1'b0 && rompage128 == 1'b1)? 3'd5 :
        (rom_plus3 && port_1ffd[2] == 1'b1 && rompage128 == 1'b0)? 3'd6 :
        (rompage128 == 1'b1 && rom_alt48 == 1'b1)? 3'd7 :
        (rompage128 == 1'b1)? 3'd1 :
        3'd0;
end

assign va[18:0] =
    rom2ram_ram_wren? {2'b00, rom2ram_ram_address} :
    screen_fetch && snow? {3'b111, screenpage, screen_addr[14:8], {8{1'bz}}} :
    screen_fetch? {3'b111, screenpage, screen_addr} :
    romreq? {2'b00, rom_a[16:14], bus.a[13], {13{1'bz}}} :
    {ram_a[18:13], {13{1'bz}}};

assign vd[7:0] =
    ~n_vrd? {8{1'bz}} :
    rom2ram_ram_wren? rom2ram_dataout :
    up_dout_active? up_dout :
    div_dout_active? div_dout :
    turbosound_dout_active? turbosound_dout :
    ports_dout_active? ports_dout :
    ~n_wr? {8{1'bz}} :
    8'hFF;


endmodule
