
`timescale 1ns / 1ns

module tb;

//usb clock ~12MHz
reg clock12 = 1'b0;
always #42
	clock12 = ~clock12;

//system clock
reg clock = 1'b0;
always #5
	clock = ~clock;

reg reset=1'b0;
wire idp;
wire idm;
reg [7:0]cmd=8'h00;
reg cmd_wr=1'b0;
wire odp, odm, ooe;
wire [7:0]rdata;
reg rdata_rd=1'b0;
wire w_rd;

usbhost usbhost_(
	.rst( reset ),
	.iclk( clock ),	//interface clk
	.wdata( cmd ),	//interface commands and data
	.wr( cmd_wr ),	//write
	.wr_level(),
	.rdata( rdata ),//result data
	.rd( w_rd ),//read
	.rdata_ready( w_rd ),
	
	.cclk( clock12 ), //core clock, 12MHz
	
	.i_dp( idp ),
	.i_dm( idm ),
	.o_dp( odp ),
	.o_dm( odm ),
	.o_oe( ooe )
);

reg [31:0] cmd_time [0:255];
reg [ 7:0] cmd_val  [0:255];
reg [7:0]idx;
initial
begin
idx=0;
cmd_time[idx]=100; cmd_val[idx]=8'h01; idx=idx+1; //get lines
cmd_time[idx]=200; cmd_val[idx]=8'h32; idx=idx+1; //reset
cmd_time[idx]=199130; cmd_val[idx]=8'h22; idx=idx+1; //enable
cmd_time[idx]=203200; cmd_val[idx]=8'h03; idx=idx+1; //wait eof
cmd_time[idx]=203201; cmd_val[idx]=8'h03; idx=idx+1; //wait eof
cmd_time[idx]=203202; cmd_val[idx]=8'h44; idx=idx+1; //send pkt
cmd_time[idx]=203203; cmd_val[idx]=8'h80; idx=idx+1;
cmd_time[idx]=203204; cmd_val[idx]=8'h2d; idx=idx+1;
cmd_time[idx]=203205; cmd_val[idx]=8'h00; idx=idx+1;
cmd_time[idx]=203206; cmd_val[idx]=8'h10; idx=idx+1;
cmd_time[idx]=203207; cmd_val[idx]=8'he4; idx=idx+1; //send pkt
cmd_time[idx]=203208; cmd_val[idx]=8'h80; idx=idx+1;
cmd_time[idx]=203209; cmd_val[idx]=8'hC4; idx=idx+1;
cmd_time[idx]=203210; cmd_val[idx]=8'h80; idx=idx+1;
cmd_time[idx]=203211; cmd_val[idx]=8'hc3; idx=idx+1;
cmd_time[idx]=203212; cmd_val[idx]=8'h80; idx=idx+1;
cmd_time[idx]=203213; cmd_val[idx]=8'h06; idx=idx+1;
cmd_time[idx]=203214; cmd_val[idx]=8'h00; idx=idx+1;
cmd_time[idx]=203215; cmd_val[idx]=8'h01; idx=idx+1;
cmd_time[idx]=203216; cmd_val[idx]=8'h00; idx=idx+1;
cmd_time[idx]=203217; cmd_val[idx]=8'h00; idx=idx+1;
cmd_time[idx]=203218; cmd_val[idx]=8'h40; idx=idx+1;
cmd_time[idx]=203219; cmd_val[idx]=8'h00; idx=idx+1;
cmd_time[idx]=203220; cmd_val[idx]=8'hdd; idx=idx+1;
cmd_time[idx]=203221; cmd_val[idx]=8'h94; idx=idx+1;
cmd_time[idx]=203222; cmd_val[idx]=8'h05; idx=idx+1;
cmd_time[idx]=203225; cmd_val[idx]=8'h06; idx=idx+1;
idx=0;
end

reg [32:0]counter=0;
always @(posedge clock)
begin
	counter<=counter+1;
	if( counter==cmd_time[idx] )
	begin
		cmd <= cmd_val[idx];
		cmd_wr<=1'b1;
		idx<=idx+1;
	end
	else
	begin
		cmd <= 0;
		cmd_wr<=1'b0;
	end
end

always @( posedge usbhost_.bit_impulse )
	if( usbhost_.bit_time==300)
		$dumpoff;
	else
	if( usbhost_.bit_time==1450)
		$dumpon;

wire [7:0]w_send_byte;
wire w_start_pkt;
wire w_last;
wire w_show_next;
wire w_pkt_end;

ls_usb_send ls_usb_send_(
	.reset( reset ),
	.clk( clock12 ),
	.bit_impulse( usbhost_.bit_impulse ),
	.eof( usbhost_.eof ),
	.sbyte( w_send_byte ),  			//byte for send
	.start_pkt( w_start_pkt ),		//start sending packet on that signal
	.last_pkt_byte( w_last ),			//mean send EOP at the end
	.cmd_reset( 1'b0 ),
	.cmd_enable( 1'b1 ),
	.dp( idp ),
	.dm( idm ),
	.bus_enable( ),
	.show_next( w_show_next ), 	//request for next sending byte in packet
	.pkt_end( w_pkt_end )		//mean that packet was sent
	);

reg [7:0]send_state = 0;
always @(posedge clock12)
	if( send_state==0 && usbhost_.enable_recv )
		send_state<=1;
	else
	if( send_state==1)
		send_state<=2;
	else
	if( send_state==2 && w_show_next )
		send_state<=3;
	else
	if( send_state==3 && w_show_next )
		send_state<=4;
	else
	if( send_state==4 && w_show_next )
		send_state<=5;

assign w_start_pkt = (send_state==1);
assign w_send_byte = (send_state==1) ? 8'h80 :
	(send_state==2) ? 8'hA5 :
	(send_state==3) ? 8'h73 :
	(send_state==4) ? 8'h23 :
	(send_state==5) ? 8'h11 : 0;
assign w_last = (send_state==4);
	
initial
begin
	$dumpfile("out.vcd");
	$dumpvars(0,tb);
	
	reset = 1'b1;
	#500;
	reset = 1'b0;
 
	
	#6000000;
	$finish();
end

endmodule
