import common::*;
module ports(
    input rst_n,
    input clk28,
    input en_kempston,
    input en_sinclair,

    cpu_bus bus,
    output [7:0] d_out,
    output d_out_active,

    input machine_t machine,
    input port_ff_active,
    input [7:0] port_ff_data,
    input [4:0] kd,
    input [7:0] kempston_data,
    input magic_map,
    input tape_in,

    output reg tape_out,
    output reg beeper,
    output reg [2:0] border,
    output reg screenpage,
    output reg rompage128,
    output reg [2:0] rampage128,
    output reg [2:0] rampage_ext,
    output reg [2:0] port_1ffd,
    output reg [4:0] port_dffd

);


/* PORT #FF */
reg port_ff_rd;
always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n)
        port_ff_rd <= 0;
    else
        port_ff_rd <= bus.rd && bus.ioreq && !magic_map && port_ff_active &&
            (machine != MACHINE_S3) && (machine != MACHINE_PENT || bus.a_reg[7:0] == 8'hFF);
end


/* PORT #FE */
wire port_fe_cs = bus.ioreq && bus.a_reg[0] == 0;
reg port_fe_rd;
always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n)
        port_fe_rd <= 0;
    else
        port_fe_rd <= port_fe_cs && bus.rd;
end

reg [4:0] kd0;
wire [7:0] port_fe_data = {1'b1, tape_in, 1'b1, kd0};
always @(negedge clk28 or negedge rst_n) begin
    if (!rst_n) begin
        beeper <= 0;
        tape_out <= 0;
        border <= 0;
    end
    else if (port_fe_cs && bus.wr) begin
        beeper <= bus.d_reg[4];
        tape_out <= bus.d_reg[3];
        border <= bus.d_reg[2:0];
    end
end

always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n) begin
        kd0 <= 5'b11111;
    end
    else if (en_sinclair) begin
        kd0 <= kd
            & (bus.a_reg[12] == 0? {~kempston_data[1], ~kempston_data[0], ~kempston_data[2], ~kempston_data[3], ~kempston_data[4]} : 5'b11111) // 6-0 keys
            & (bus.a_reg[15] == 0? {1'b1, ~kempston_data[6], ~kempston_data[5], 2'b11} : 5'b11111 ) ; // b-space keys
    end
    else begin
        kd0 <= kd;
    end
end


/* PORT #7FFD */
wire port_7ffd_cs = bus.ioreq && bus.a_reg[1] == 0 && bus.a_reg[15] == 0 &&
                    (bus.a_reg[14] == 1'b1 || (!magic_map && machine != MACHINE_S3)) &&
                    (machine != MACHINE_S48 || magic_map);
reg lock_7ffd;
always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n) begin
        rampage128 <= 0;
        screenpage <= 0;
        rompage128 <= 0;
        lock_7ffd <= 0;
    end
    else if (port_7ffd_cs && bus.wr && (lock_7ffd == 0 || port_dffd[4] == 1'b1)) begin
        rampage128 <= bus.d_reg[2:0];
        screenpage <= bus.d_reg[3];
        rompage128 <= bus.d_reg[4];
        lock_7ffd <= bus.d_reg[5];
    end
end


/* PORT #DFFD */
wire port_dffd_cs = bus.ioreq && bus.a_reg == 16'hDFFD && (machine == MACHINE_PENT || magic_map);
always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n) begin
        rampage_ext <= 0;
        port_dffd <= 0;
    end
    else if (port_dffd_cs && bus.wr) begin
        rampage_ext <= bus.d_reg[2:0];
        port_dffd <= bus.d_reg[4:0];
    end
end


/* PORT #1FFD */
wire port_1ffd_cs = bus.ioreq && bus.a_reg[15:12] == 4'b0001 && !bus.a_reg[1] &&
                    (machine == MACHINE_S3 || magic_map);
always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n) begin
        port_1ffd <= 0;
    end
    else if (port_1ffd_cs && bus.wr) begin
        port_1ffd <= bus.d_reg[2:0];
    end
end


/* KEMPSTON */
reg kempston_rd;
always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n)
        kempston_rd <= 0;
    else
        kempston_rd <= en_kempston && bus.ioreq && bus.rd && bus.a_reg[7:5] == 3'b000;
end


/* BUS CONTROLLER */
assign d_out_active = port_fe_rd | port_ff_rd | kempston_rd;

assign d_out =
    kempston_rd? kempston_data :
    port_fe_rd? port_fe_data :
    port_ff_data ;


endmodule
