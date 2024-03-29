import common::*;
module ulaplus(
    input rst_n,
    input clk28,
    input en,

    cpu_bus bus,
    output [7:0] d_out,
    output d_out_active,

    output reg active,

    input [5:0] read_addr1,
    output reg [7:0] read_data1,
    input [5:0] read_addr2,
    output reg [7:0] read_data2
);


wire port_bf3b_cs = en && bus.ioreq && bus.a == 16'hbf3b;
wire port_ff3b_cs = en && bus.ioreq && bus.a == 16'hff3b;
reg port_ff3b_rd;
wire [7:0] port_ff3b_data = {7'b0000000, active};

reg [7:0] addr_reg;
reg [2:0] read_req;
reg [1:0] write_req;

always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n) begin
        active <= 0;
        addr_reg <= 0;
        write_req <= 0;
        port_ff3b_rd <= 0;
    end
    else begin
        if (port_bf3b_cs && bus.wr)
            addr_reg <= bus.d;
        if (port_ff3b_cs && bus.wr && addr_reg == 8'b01000000)
            active <= bus.d[0];

        read_req  <= {read_req[1:0], port_ff3b_cs && bus.rd && addr_reg[7:6] == 2'b00};
        write_req <= {write_req[0],  port_ff3b_cs && bus.wr && addr_reg[7:6] == 2'b00};
        port_ff3b_rd <= port_ff3b_cs && bus.rd;

        if (!en)
            active <= 0;
    end
end

reg read_step;
always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n)
        read_step <= 0;
    else
        read_step <= !read_step;
end

wire read_req0  = read_req[0]  && !read_req[1];
wire write_req0 = write_req[0] && !write_req[1];
wire [5:0] ram_a = (write_req0 || read_req0)? addr_reg[5:0] : read_step? read_addr2 : read_addr1;
wire [7:0] ram_q;
ulaplus_ram pallete(ram_q, ram_a, bus.d, write_req0, clk28);

reg [7:0] ram_q_reg;
always @(posedge clk28) begin
    if (read_req[1] && !read_req[2])
        ram_q_reg <= ram_q;
    else if (read_step)
        read_data1 <= ram_q;
    else
        read_data2 <= ram_q;
end


assign d_out = (addr_reg[7:6] == 2'b00)? ram_q_reg : port_ff3b_data;
assign d_out_active = port_ff3b_rd;

endmodule


module ulaplus_ram(q, a, d, we, clk);
    output reg [7:0] q;
    input [7:0] d;
    input [5:0] a;
    input we, clk;
    reg [7:0] mem [0:63];
    always @(posedge clk) begin
        if (we)
            mem[a] <= d;
        q <= mem[a];
    end
endmodule
