`include "util.vh"
import common::*;
module screen(
    input rst_n,
    input clk28,

    input machine_t machine,
    input [2:0] border,

    output reg [5:0] r,
    output reg [5:0] g,
    output reg [5:0] b,
    output reg vsync,
    output reg hsync,
    output reg csync,

    input fetch_allow,
    output reg fetch,
    output fetch_next,
    output reg [14:0] addr,
    input [7:0] fetch_data,

    output contention,
    output blink,
    output reg even_line,
    output port_ff_active,
    output [7:0] port_ff_data,

    input up_en,
    output [5:0] up_ink_addr,
    output [5:0] up_paper_addr,
    input [7:0] up_ink,
    input [7:0] up_paper,

    output [8:0] hc_out,
    output [8:0] vc_out,
    output clk14,
    output clk7,
    output clk35,
    output ck14,
    output ck7,
    output ck35
);

/* SCREEN CONTROLLER */
localparam H_AREA         = 256;
localparam V_AREA         = 192;
localparam SCREEN_DELAY   = 13;

localparam H_LBORDER_S48  = 54 - SCREEN_DELAY;
localparam H_RBORDER_S48  = 53 + SCREEN_DELAY;
localparam H_BLANK1_S48   = 12;
localparam H_SYNC_S48     = 33;
localparam H_BLANK2_S48   = 40;
localparam H_TOTAL_S48    = H_AREA + H_RBORDER_S48 + H_BLANK1_S48 + H_SYNC_S48 + H_BLANK2_S48 + H_LBORDER_S48;
localparam V_BBORDER_S48  = 56;
localparam V_SYNC_S48     = 8;
localparam V_TBORDER_S48  = 56;
localparam V_TOTAL_S48    = V_AREA + V_BBORDER_S48 + V_SYNC_S48 + V_TBORDER_S48;

localparam H_LBORDER_S128 = 54 - SCREEN_DELAY;
localparam H_RBORDER_S128 = 53 + SCREEN_DELAY;
localparam H_BLANK1_S128  = 16;
localparam H_SYNC_S128    = 33;
localparam H_BLANK2_S128  = 44;
localparam H_TOTAL_S128   = H_AREA + H_RBORDER_S128 + H_BLANK1_S128 + H_SYNC_S128 + H_BLANK2_S128 + H_LBORDER_S128;
localparam V_BBORDER_S128 = 55;
localparam V_SYNC_S128    = 8;
localparam V_TBORDER_S128 = 56;
localparam V_TOTAL_S128   = V_AREA + V_BBORDER_S128 + V_SYNC_S128 + V_TBORDER_S128;

localparam H_LBORDER_PENT = 54 - SCREEN_DELAY;
localparam H_RBORDER_PENT = 53 + SCREEN_DELAY;
localparam H_BLANK1_PENT  = 12;
localparam H_SYNC_PENT    = 33;
localparam H_BLANK2_PENT  = 40;
localparam H_TOTAL_PENT   = H_AREA + H_RBORDER_PENT + H_BLANK1_PENT + H_SYNC_PENT + H_BLANK2_PENT + H_LBORDER_PENT;
localparam V_BBORDER_PENT = 56;
localparam V_SYNC_PENT    = 8;
localparam V_TBORDER_PENT = 64;
localparam V_TOTAL_PENT   = V_AREA + V_BBORDER_PENT + V_SYNC_PENT + V_TBORDER_PENT;

reg  [8:0] vc;
reg  [10:0] hc0;
wire [8:0] hc = hc0[10:2];

assign vc_out = vc;
assign hc_out = hc;

assign clk14 = hc0[0];
assign clk7 = hc0[1];
assign clk35 = hc0[2];
assign ck14 = hc0[0];
assign ck7 = hc0[0] & hc0[1];
assign ck35 = hc0[0] & hc0[1] & hc0[2];

wire hc0_reset =
    (machine == MACHINE_S48)?
        hc0 == (H_TOTAL_S48<<2) - 1'b1 :
    (machine == MACHINE_S128 || machine == MACHINE_S3)?
        hc0 == (H_TOTAL_S128<<2) - 1'b1 :
    // Pentagon
        hc0 == (H_TOTAL_PENT<<2) - 1'b1 ;
wire vc_reset =
    (machine == MACHINE_S48)?
        vc == V_TOTAL_S48 - 1'b1:
    (machine == MACHINE_S128 || machine == MACHINE_S3)?
        vc == V_TOTAL_S128 - 1'b1 :
    // Pentagon
        vc == V_TOTAL_PENT - 1'b1 ;
wire hsync0 =
    (machine == MACHINE_S48)?
        (hc >= (H_AREA + H_RBORDER_S48 + H_BLANK1_S48)) &&
            (hc <  (H_AREA + H_RBORDER_S48 + H_BLANK1_S48 + H_SYNC_S48)) :
    (machine == MACHINE_S128 || machine == MACHINE_S3)?
        (hc >= (H_AREA + H_RBORDER_S128 + H_BLANK1_S128)) &&
            (hc <  (H_AREA + H_RBORDER_S128 + H_BLANK1_S128 + H_SYNC_S128)) :
    // Pentagon
        (hc >= (H_AREA + H_RBORDER_PENT + H_BLANK1_PENT)) &&
            (hc <  (H_AREA + H_RBORDER_PENT + H_BLANK1_PENT + H_SYNC_PENT)) ;
wire vsync0 =
    (machine == MACHINE_S48)?
        (vc >= (V_AREA + V_BBORDER_S48)) && (vc < (V_AREA + V_BBORDER_S48 + V_SYNC_S48)) :
    (machine == MACHINE_S128 || machine == MACHINE_S3)?
        (vc >= (V_AREA + V_BBORDER_S128)) && (vc < (V_AREA + V_BBORDER_S128 + V_SYNC_S128)) :
    // Pentagon
        (vc >= (V_AREA + V_BBORDER_PENT)) && (vc < (V_AREA + V_BBORDER_PENT + V_SYNC_PENT)) ;
wire blank =
    (machine == MACHINE_S48)?
        ((vc >= (V_AREA + V_BBORDER_S48)) && (vc < (V_AREA + V_BBORDER_S48 + V_SYNC_S48))) ||
            ((hc >= (H_AREA + H_RBORDER_S48)) &&
             (hc <  (H_AREA + H_RBORDER_S48 + H_BLANK1_S48 + H_SYNC_S48 + H_BLANK2_S48))) :
    (machine == MACHINE_S128 || machine == MACHINE_S3)?
        ((vc >= (V_AREA + V_BBORDER_S128)) && (vc < (V_AREA + V_BBORDER_S128 + V_SYNC_S128))) ||
            ((hc >= (H_AREA + H_RBORDER_S128)) &&
             (hc <  (H_AREA + H_RBORDER_S128 + H_BLANK1_S128 + H_SYNC_S128 + H_BLANK2_S128))) :
    // Pentagon
        ((vc >= (V_AREA + V_BBORDER_PENT)) && (vc < (V_AREA + V_BBORDER_PENT + V_SYNC_PENT))) ||
            ((hc >= (H_AREA + H_RBORDER_PENT)) &&
             (hc <  (H_AREA + H_RBORDER_PENT + H_BLANK1_PENT + H_SYNC_PENT + H_BLANK2_PENT))) ;


always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n) begin
        hc0 <= 0;
        vc <= 0;
    end
    else if (hc0_reset) begin
        hc0 <= 0;
        if (vc_reset) begin
            vc <= 0;
        end
        else begin
            vc <= vc + 1'b1;
        end
    end
    else begin
        hc0 <= hc0 + 1'b1;
    end
end


reg [4:0] blink_cnt;
assign blink = blink_cnt[$bits(blink_cnt)-1];
always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n)
        blink_cnt <= 0;
    else if (hc0_reset && vc_reset)
        blink_cnt <= blink_cnt + 1'b1;
end

reg hsync0_delayed;
always @(posedge clk28)
    hsync0_delayed <= hsync0;
always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n)
        even_line <= 0;
    else if (hsync0 && !hsync0_delayed)
        even_line <= ~even_line;
end


wire screen_show = (vc < V_AREA) && (hc0 >= (SCREEN_DELAY<<2) - 1) && (hc0 < ((H_AREA + SCREEN_DELAY)<<2) - 1);
wire screen_update = hc0[4:0] == 5'b10011;
wire border_update = (hc0[4:0] == 5'b10011) || (machine == MACHINE_PENT && ck7);
wire bitmap_shift = hc0[1:0] == 2'b11;
wire next_addr = hc0[4:0] == 5'b10000;

reg [7:0] vaddr;
reg [7:3] haddr;
always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n) begin
        vaddr <= 0;
        haddr <= 0;
    end
    else if (next_addr) begin
        vaddr <= vc[7:0];
        haddr <= hc[7:3];
    end
end

reg loading;
always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n)
        loading <= 0;
    else
        loading <= (vc < V_AREA) && (hc0 > 15) && (hc0 < (H_AREA<<2) + 17);
end


wire [7:0] attr_border = {2'b00, border[2:0], border[2:0]};

reg [7:0] bitmap, attr, bitmap_next, attr_next;
reg [7:0] up_ink0, up_paper0;

reg fetch_step;
wire fetch_bitmap = fetch && fetch_step == 1'd0;
wire fetch_attr   = fetch && fetch_step == 1'd1;
assign fetch_next = loading && fetch_allow;

assign up_ink_addr = { attr_next[7:6], 1'b0, attr_next[2:0] };
assign up_paper_addr = { attr_next[7:6], 1'b1, attr_next[5:3] };

always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n) begin
        addr <= 0;
        fetch <= 0;
        fetch_step <= 0;
        attr <= 0;
        bitmap <= 0;
        attr_next <= 0;
        bitmap_next <= 0;
        up_ink0 <= 0;
        up_paper0 <= 0;
    end
    else begin
        if (ck14) begin
            addr <= ((fetch && fetch_step == 1'd1) || (!fetch && fetch_step == 1'b0))?
                { 2'b10, vaddr[7:6], vaddr[2:0], vaddr[5:3], haddr[7:3] } :
                { 5'b10110, vaddr[7:3], haddr[7:3] };

            if (fetch)
                fetch_step <= fetch_step + 1'b1;
            fetch <= fetch_next;

            if (fetch_attr)
                attr_next <= fetch_data;
            else if (!loading)
                attr_next <= attr_border;
            if (fetch_bitmap)
                bitmap_next <= fetch_data;
            else if (!loading)
                bitmap_next <= 0;
        end

        if (screen_show && screen_update)
            attr <= attr_next;
        else if (!screen_show && border_update)
            attr <= attr_border;

        if (screen_update)
            bitmap <= bitmap_next;
        else if (bitmap_shift)
            bitmap <= {bitmap[6:0], 1'b0};

        if (screen_update)
            up_ink0 <= up_ink;
        if (screen_update)
            up_paper0 <= up_paper;
    end
end


/* ATTRIBUTE PORT */
wire port_ff_attr = (machine == MACHINE_PENT) || hc[3:1] == 3'h6 || hc[3:1] == 3'h0;
wire port_ff_bitmap = (hc[3] && hc[1]);
assign port_ff_active = loading && (port_ff_attr || port_ff_bitmap);
assign port_ff_data =
    port_ff_attr? attr_next :
    port_ff_bitmap? bitmap_next :
    8'hFF;

assign contention = (vc < V_AREA) && (hc < H_AREA) && (hc[2] || hc[3]);


/* RGBS generation */
wire pixel = bitmap[7];
always @(posedge clk28) begin
    if (blank)
        {g, r, b} = 0;
    else if (up_en) begin
        g[5:3] = pixel? up_ink0[7:5] : up_paper0[7:5];
        r[5:3] = pixel? up_ink0[4:2] : up_paper0[4:2];
        b[5:4] = pixel? up_ink0[1:0] : up_paper0[1:0];
        g[2:0] = g[5:3];
        r[2:0] = r[5:3];
        b[3:0] = {b[5:4], b[5:4]};
    end
    else begin
        {g[5], r[5], b[5]} = (pixel ^ (attr[7] & blink))? attr[2:0] : attr[5:3];
        {g[4], r[4], b[4]} = attr[6]? {g[5], r[5], b[5]} : 3'b000;
        {g[3], r[3], b[3]} = {g[5], r[5], b[5]};
        {g[2], r[2], b[2]} = {g[4], r[4], b[4]};
        {g[1], r[1], b[1]} = {g[4], r[4], b[4]};
        {g[0], r[0], b[0]} = {g[5], r[5], b[5]};
    end
end

always @(posedge clk28) begin
    csync = ~(vsync0 ^ hsync0);
    vsync = ~vsync0;
    hsync = ~hsync0;
end


endmodule
