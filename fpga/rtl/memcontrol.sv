import common::*;

module memcontrol(
    input clk28,
    cpu_bus bus,
    output [18:0] va,
    inout [7:0] vd,
    output n_vrd,
    output n_vwr,

    input machine_t machine,
    input screenpage,
    input screen_fetch,
    input screen_fetch_up,
    input snow,
    input [14:0] screen_addr,
    input magic_map,
    input [2:0] rampage128,
    input rompage128,
    input [2:0] port_1ffd,
    input [4:0] port_dffd,
    input [2:0] rampage_ext,
    input divmmc_en,
    input div_ram,
    input div_map,
    input div_ramwr_mask,
    input [3:0] div_page,

    input [16:0] rom2ram_ram_address,
    input rom2ram_ram_wren,
    input [7:0] rom2ram_dataout,
    input magic_dout_active,
    input [7:0] magic_dout,
    input up_dout_active,
    input [7:0] up_dout,
    input div_dout_active,
    input [7:0] div_dout,
    input turbosound_dout_active,
    input [7:0] turbosound_dout,
    input ports_dout_active,
    input [7:0] ports_dout
);


/* MEMORY CONTROLLER */
reg romreq, ramreq, ramreq_wr;
always @(posedge clk28) begin
    romreq =  bus.mreq && !bus.rfsh && bus.a[14] == 0 && bus.a[15] == 0 &&
        (magic_map || (!div_ram && div_map) || (!div_ram && !port_dffd[4] && !port_1ffd[0]));
    ramreq = bus.mreq && !bus.rfsh && !romreq;
    ramreq_wr = ramreq && bus.wr && div_ramwr_mask == 0;
end

assign n_vrd = ((((ramreq || romreq) && bus.rd) || screen_fetch) && !rom2ram_ram_wren)? 1'b0 : 1'b1;
assign n_vwr = ((ramreq_wr && bus.wr && !screen_fetch) || rom2ram_ram_wren)? 1'b0 : 1'b1;

/* VA[18:13] map
 * 00xxxx 112Kb of roms
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
        port_dffd[3] & bus.a[15]? {2'b11, bus.a[14], bus.a[15], bus.a[14], bus.a[13]} :
        port_dffd[3] & bus.a[14]? {1'b1, ~rampage_ext[0], rampage128, bus.a[13]} :
        (port_1ffd[2] == 1'b0 && port_1ffd[0] == 1'b1)? {2'b11, port_1ffd[1], bus.a[15], bus.a[14], bus.a[13]} :
        (port_1ffd == 3'b101)? {2'b11, ~(bus.a[15] & bus.a[14]), bus.a[15], bus.a[14]} :
        (port_1ffd == 3'b111)? {2'b11, ~(bus.a[15] & bus.a[14]), (bus.a[15] | bus.a[14]), bus.a[14]} :
        bus.a[15] & bus.a[14]? {1'b1, ~rampage_ext[0], rampage128, bus.a[13]} :
        {2'b11, bus.a[14], bus.a[15], bus.a[14], bus.a[13]} ;
end

reg [16:13] rom_a;
always @(posedge clk28) begin
    rom_a <=
        magic_map? {3'd2, 1'b0} :
        div_map? {3'd2, 1'b1} :
        (machine == MACHINE_S3 && port_1ffd[2] == 1'b0 && rompage128 == 1'b0)? {3'd4, bus.a[13]} :
        (machine == MACHINE_S3 && port_1ffd[2] == 1'b0 && rompage128 == 1'b1)? {3'd5, bus.a[13]} :
        (machine == MACHINE_S3 && port_1ffd[2] == 1'b1 && rompage128 == 1'b0)? {3'd6, bus.a[13]} :
        (machine == MACHINE_S48)? {3'd3, bus.a[13]} :
        (rompage128 == 1'b1)? {3'd1, bus.a[13]} :
        {3'd0, bus.a[13]};
end

assign va[18:0] =
    rom2ram_ram_wren? {2'b00, rom2ram_ram_address} :
    screen_fetch && snow? {3'b111, screenpage, screen_addr[14:8], {8{1'bz}}} :
    screen_fetch? {3'b111, screenpage, screen_addr} :
    romreq? {2'b00, rom_a[16:13], {13{1'bz}}} :
    {ram_a[18:13], {13{1'bz}}};

assign vd[7:0] =
    ~n_vrd? {8{1'bz}} :
    bus.wr? {8{1'bz}} :
    rom2ram_ram_wren? rom2ram_dataout :
    magic_dout_active? magic_dout :
    up_dout_active? up_dout :
    div_dout_active? div_dout :
    turbosound_dout_active? turbosound_dout :
    ports_dout_active? ports_dout :
    (bus.m1 && bus.iorq)? 8'hFF :
    bus.rd? 8'hFF :
    {8{1'bz}};


endmodule
