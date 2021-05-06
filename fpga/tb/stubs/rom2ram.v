module rom2ram (
	clock,
	datain,
	init,
	rom_data_ready,
	dataout,
	init_busy,
	ram_address,
	ram_wren,
	rom_address,
	rom_rden);

	input	  clock;
	input	[7:0]  datain;
	input	  init;
	input	  rom_data_ready;
	output	[7:0]  dataout;
	output	  init_busy;
	output	[16:0]  ram_address;
	output	  ram_wren;
	output	[16:0]  rom_address;
	output	  rom_rden;

assign init_busy = 0;
assign ram_wren = 0;
assign rom_rden = 0;

endmodule
