import common::*;
module mem(
    input rst_n,
    input clk28,
    cpu_bus bus,
    output reg [18:0] va,
    inout [7:0] vd,
    output reg n_vrd,
    output reg n_vwr,

    output bus_valid,
    output cpuwait,
    output basic48_paged,

    input machine_t machine,
    input turbo_t turbo,
    input cpu_contention,
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
    output video_read_req_ack,
    output video_data_valid,

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
always @* begin
    romreq =  a[15:14] == 2'b00 &&
        (magic_map || (!div_ram && div_map) || (!div_ram && !port_dffd[4] && !port_1ffd[0]));
    ramreq = !romreq;
    ramreq_wr = ramreq && div_ramwr_mask == 0;

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

assign basic48_paged = (va_18_13[18:14] == 5'd1) ||
                       (va_18_13[18:14] == 5'd3) ;

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

localparam BUS_VALID_LATENCY = 2'd1;
reg [1:0] bus_valid_step;
localparam LATENCY = 2'd2;
reg [1:0] step;
localparam REQ_NONE       = 3'd0;
localparam REQ_CPU_RD     = 3'd1;
localparam REQ_CPU_WR     = 3'd2;
localparam REQ_VIDEO_RD   = 3'd3;
localparam REQ_ROM2RAM_WR = 3'd4;
reg [2:0] current_req;
reg cpuwait_reg;

always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n) begin
        va                       <= {va_18_13, {13{1'bz}}};
        n_vrd                    <= 1'b1;
        n_vwr                    <= 1'b1;
        cpuwait_reg              <= 0;
        bus_valid_step           <= 0;
        step                     <= 0;
        current_req              <= REQ_NONE;
    end
    else begin
        if (step)
            step                 <= step - 1'd1;
        if (bus_valid_step)
            bus_valid_step       <= bus_valid_step - 1'd1;
        if (!(bus.mreq && bus.rd))
            cpuwait_reg          <= 0;

        if (rom2ram_ram_wren) begin
            if (current_req != REQ_ROM2RAM_WR)
                step             <= LATENCY;
            va                   <= {2'b00, rom2ram_ram_address};
            n_vrd                <= 1'b1;
            n_vwr                <= (current_req == REQ_ROM2RAM_WR && step == 0)? 1'b1 : 1'b0;
            bus_valid_step       <= BUS_VALID_LATENCY;
            current_req          <= REQ_ROM2RAM_WR;
        end
        else if (turbo == TURBO_14 && current_req == REQ_VIDEO_RD && step) begin
            // complete current request
            bus_valid_step       <= BUS_VALID_LATENCY;
        end
        else if (bus.mreq && bus.wr && ramreq_wr) begin
            if (current_req != REQ_CPU_WR)
                step             <= LATENCY;
            va                   <= {va_18_13, {13{1'bz}}};
            n_vrd                <= 1'b1;
            n_vwr                <= (current_req == REQ_CPU_WR && step == 0)? 1'b1 : 1'b0;
            current_req          <= REQ_CPU_WR;
        end
        else if (bus.mreq && bus.rd) begin
            if (current_req != REQ_CPU_RD) begin
                step             <= LATENCY;
            end
            else if (va[18:13] != va_18_13) begin
                cpuwait_reg      <= 1'b1;
                step             <= LATENCY;
            end
            else if (!step) begin
                cpuwait_reg      <= 1'b0;
            end
            va                   <= {va_18_13, {13{1'bz}}};
            n_vrd                <= 1'b0;
            n_vwr                <= 1'b1;
            current_req          <= REQ_CPU_RD;
        end
        else if ((bus.mreq || bus.iorq) && !bus.rfsh && !cpu_contention) begin
            va                   <= {va_18_13, {13{1'bz}}};
            n_vrd                <= 1'b1;
            n_vwr                <= 1'b1;
            current_req          <= REQ_NONE;
        end
        else if (video_read_req) begin
            if (current_req != REQ_VIDEO_RD || !step)
                step             <= LATENCY;
            va                   <= snow? {3'b111, video_page, video_read_addr[14:7], {7{1'bz}}} :
                                          {3'b111, video_page, video_read_addr} ;
            n_vrd                <= 1'b0;
            n_vwr                <= 1'b1;
            bus_valid_step       <= BUS_VALID_LATENCY;
            current_req          <= REQ_VIDEO_RD;
        end
        else begin
            va                   <= {va_18_13, {13{1'bz}}};
            n_vrd                <= 1'b1;
            n_vwr                <= 1'b1;
            current_req          <= REQ_NONE;
        end
    end
end

assign cpuwait                = cpuwait_reg || (bus.mreq && bus.rd && current_req == REQ_CPU_RD && va[18:13] != va_18_13);
assign bus_valid              = bus_valid_step == 0;
assign video_data_valid       = current_req == REQ_VIDEO_RD && step == 0;
assign video_read_req_ack     = current_req == REQ_VIDEO_RD && step == 1'd1 && (!((bus.mreq || bus.iorq) && !bus.rfsh && !cpu_contention) || turbo == TURBO_14);


endmodule
