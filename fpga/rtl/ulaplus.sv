module ulaplus(
	input rst_n,
	input clk28,
	input en,
	
	cpu_bus bus,
	output [7:0] d_out,
	output d_out_active,
	
	output reg active,
	input [5:0] ink_addr,
	input [5:0] paper_addr,
	output reg [7:0] ink,
	output reg [7:0] paper
);


wire port_bf3b_cs = en && bus.ioreq && bus.a_reg == 16'hbf3b;
wire port_ff3b_cs = en && bus.ioreq && bus.a_reg == 16'hff3b;
reg port_ff3b_rd;
wire [7:0] port_ff3b_data = {7'b0000000, active};

reg [7:0] addr_reg;
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
				addr_reg <= bus.d_reg;
		if (port_ff3b_cs && bus.wr && addr_reg == 8'b01000000)
				active <= bus.d_reg[0];
		
		write_req <= {write_req[0], port_ff3b_cs && bus.wr && addr_reg[7:6] == 2'b00};
		port_ff3b_rd <= port_ff3b_cs && bus.rd;
	end
end


wire write_req0 = write_req[0] && !write_req[1];
reg read_step;
wire [5:0] ram_a = write_req0? addr_reg[5:0] : read_step? ink_addr : paper_addr;
wire [7:0] ram_q;
ram pallete(ram_q, ram_a, bus.d_reg, write_req0, clk28);

always @(posedge clk28 or negedge rst_n) begin
	if (!rst_n)
		read_step <= 0;
	else
		read_step <= !read_step;
end

always @(posedge clk28) begin
	if (read_step)
		paper <= ram_q;
	else
		ink <= ram_q;
end


assign d_out = port_ff3b_data;
assign d_out_active = port_ff3b_rd;

endmodule


module ram(q, a, d, we, clk);
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
