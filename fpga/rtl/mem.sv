import common::*;
module mem(
    input clk28,
    cpu_bus bus,
    output [18:0] va,
    inout [7:0] vd,
    output n_vrd,
    output n_vwr,

    input machine_t machine,
    input magic_map,
    input [2:0] ram_page128,
    input rom_page128,
    input [2:0] port_1ffd,
    input [4:0] port_dffd,
    input [2:0] ram_pageext,
    input div_ram,
    input div_map,
    input div_ramwr_mask,
    input [3:0] div_page,

    input snow,
    input video_page,
    input video_read_req,
    input [14:0] video_read_addr,

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


/* VA[18:13] map
 * 00xxxx 112Kb of roms
 * 00111x 16Kb of magic ram
 * 01xxxx 128Kb of divmmc memory
 * 10xxxx 128Kb of extended ram (via port dffd)
 * 11xxxx 128Kb of main ram
 */

reg romreq, ramreq, ramreq_wr;
reg [18:13] va_18_13;
wire [15:0] a = bus.a_raw[15:0];
always @(negedge clk28) begin
    romreq =  bus.mreq && a[15:14] == 2'b00 &&
        (magic_map || (!div_ram && div_map) || (!div_ram && !port_dffd[4] && !port_1ffd[0]));
    ramreq = bus.mreq && !romreq;
    ramreq_wr = ramreq && bus.wr && div_ramwr_mask == 0;

    if (romreq) va_18_13 =
        (magic_map)                                                            ? {5'd2, 1'b0} :
        (div_map)                                                              ? {5'd2, 1'b1} :
        (machine == MACHINE_S3 && port_1ffd[2] == 1'b0 && rom_page128 == 1'b0) ? {5'd4, a[13]} :
        (machine == MACHINE_S3 && port_1ffd[2] == 1'b0 && rom_page128 == 1'b1) ? {5'd5, a[13]} :
        (machine == MACHINE_S3 && port_1ffd[2] == 1'b1 && rom_page128 == 1'b0) ? {5'd6, a[13]} :
        (machine == MACHINE_S48)                                               ? {5'd3, a[13]} :
        (rom_page128 == 1'b1)                                                  ? {5'd1, a[13]} :
                                                                                 {5'd0, a[13]} ;
    else va_18_13 =
        (magic_map && a[15:14] == 2'b11)               ? {2'b00, 3'b111, a[13]} :
        (magic_map)                                    ? {3'b111, video_page, a[14:13]} :
        (div_map && a[15:13] == 3'b001)                ? {2'b01, div_page} :
        (div_map && a[15:14] == 2'b00)                 ? {2'b01, 4'b0011} :
        (port_dffd[3] & a[15])                         ? {2'b11, a[14], a[15], a[14], a[13]} :
        (port_dffd[3] & a[14])                         ? {1'b1, ~ram_pageext[0], ram_page128, a[13]} :
        (port_1ffd[2] == 1'b0 && port_1ffd[0] == 1'b1) ? {2'b11, port_1ffd[1], a[15], a[14], a[13]} :
        (port_1ffd == 3'b101)                          ? {2'b11, ~(a[15] & a[14]), a[15], a[14], a[13]} :
        (port_1ffd == 3'b111)                          ? {2'b11, ~(a[15] & a[14]), (a[15] | a[14]), a[14], a[13]} :
        (a[15:14] == 2'b11)                            ? {1'b1, ~ram_pageext[0], ram_page128, a[13]} :
                                                         {2'b11, a[14], a[15], a[14], a[13]} ;
end

assign n_vrd = (((bus.mreq && bus.rd) || video_read_req) && !rom2ram_ram_wren)? 1'b0 : 1'b1;
assign n_vwr = ((ramreq_wr && bus.wr && !video_read_req) || rom2ram_ram_wren)? 1'b0 : 1'b1;

assign va[18:0] =
    (rom2ram_ram_wren)       ? {2'b00, rom2ram_ram_address} :
    (video_read_req && snow) ? {3'b111, video_page, video_read_addr[14:8], {8{1'bz}}} :
    (video_read_req)         ? {3'b111, video_page, video_read_addr} :
                               {va_18_13, {13{1'bz}}};

assign vd[7:0] =
    ~n_vrd                 ? {8{1'bz}} :
    bus.wr                 ? {8{1'bz}} :
    rom2ram_ram_wren       ? rom2ram_dataout :
    magic_dout_active      ? magic_dout :
    up_dout_active         ? up_dout :
    div_dout_active        ? div_dout :
    turbosound_dout_active ? turbosound_dout :
    ports_dout_active      ? ports_dout :
    (bus.m1 && bus.iorq)   ? 8'hFF :
    bus.rd                 ? 8'hFF :
                             {8{1'bz}} ;


endmodule
