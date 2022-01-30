import common::*;
module magic(
    input rst_n,
    input clk28,

    cpu_bus bus,
    output [7:0] d_out,
    output d_out_active,

    input n_int,
    input n_int_next,
    output reg n_nmi,

    input magic_button,
    input pause_button,
    input sd_cd,
    input div_automap,

    output reg magic_mode,
    output reg magic_map,

    output reg magic_reboot,
    output reg magic_beeper,
    output machine_t machine,
    output turbo_t turbo,
    output panning_t panning,
    output reg joy_sinclair,
    output divmmc_t divmmc_en,
    output reg ulaplus_en,
    output reg covox_en,
    output reg soundrive_en
);

reg magic_unmap_next;
reg magic_map_next;
always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n) begin
        n_nmi <= 1'b1;
        magic_mode <= 1'b1;
        magic_map <= 1'b1;
        magic_map_next <= 0;
        magic_unmap_next <= 0;
    end
    else begin
        if ((magic_button || pause_button) && n_int == 1'b1 && n_int_next == 1'b0) begin
            if (!magic_mode)
                n_nmi <= 1'b0;
            magic_mode <= 1'b1;
        end

        if (magic_map && bus.memreq && bus.rd && bus.a_reg == 16'hf000 && !magic_map_next) begin
            magic_unmap_next <= 1'b1;
            magic_mode <= 1'b0;
        end
        else if (magic_map && bus.memreq && bus.rd && bus.a_reg == 16'hf008) begin
            magic_unmap_next <= 1'b1;
            magic_map_next <= 1'b1;
        end
        else if (magic_unmap_next && !bus.memreq) begin
            magic_map <= 1'b0;
            magic_unmap_next <= 1'b0;
        end
        else if (magic_mode && bus.m1 && bus.memreq && (bus.a_reg == 16'h0066 || magic_map_next)) begin
            n_nmi <= 1'b1;
            magic_map <= 1'b1;
            magic_map_next <= 1'b0;
        end
    end
end


/* MAGIC CONFIG */
wire config_cs = magic_map && bus.ioreq && bus.a_reg[7:0] == 8'hFF;
always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n) begin
        magic_reboot <= 0;
        magic_beeper <= 0;
        machine <= MACHINE_PENT;
        turbo <= TURBO_NONE;
        panning <= PANNING_ABC;
        joy_sinclair <= 0;
        divmmc_en <= DIVMMC_NOOS;
        ulaplus_en <= 1'b1;
        covox_en <= 1'b1;
        soundrive_en <= 1'b1;
    end
    else if (config_cs && bus.wr) case (bus.a_reg[15:8])
        8'h00: magic_reboot <= bus.d_reg[0];
        8'h01: magic_beeper <= bus.d_reg[0];
        8'h02: machine <= machine_t'(bus.d_reg[2:0]);
        8'h03: turbo <= turbo_t'(bus.d_reg[2:0]);
        8'h04: panning <= panning_t'(bus.d_reg[1:0]);
        8'h07: joy_sinclair <= bus.d_reg[0];
        8'h09: divmmc_en <= divmmc_t'(bus.d_reg[1:0]);
        8'h0a: ulaplus_en <= bus.d_reg[0];
        8'h0b: {soundrive_en, covox_en} <= bus.d_reg[1:0];
    endcase
end

reg config_rd;
wire [7:0] config_data = {4'b0000, div_automap, sd_cd, pause_button, magic_button};
always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n)
        config_rd <= 0;
    else
        config_rd <= config_cs && bus.rd && bus.a_reg[15:8] == 8'hFF;
end


/* BUS CONTROLLER */
assign d_out_active = config_rd;
assign d_out = config_data;


endmodule
