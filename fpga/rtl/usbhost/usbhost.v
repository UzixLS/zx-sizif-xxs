
module usbhost(
	//interface
	input wire rst,
	input wire iclk,		//interface clk
	input wire [7:0]wdata,	//interface commands and data
	input wire wr,			//write
	output wire [1:0]wr_level,
	output wire [7:0]rdata,	//result data
	input wire rd,			//read
	output wire rdata_ready,
	
	//core
	input wire cclk, //core clock, 12MHz
	
	input  wire i_dp,
	input  wire i_dm,
	output wire o_dp,
	output wire o_dm,
	output wire o_oe,
	output wire [7:0]leds
);

//controller serial bytes protocol 
localparam CMD_GET_LINES = 4'h1; //controller must once poll and return one byte state of USB lines
localparam CMD_BUS_CTRL  = 4'h2; //controller must set bus to reset/normal and/or or enabled/disabled state
									//reset state - dm/dm in zero
									//enabled state when no reset and 1ms periodic SE0 impulses go
localparam CMD_WAIT_EOF  = 4'h3; //controller just waits EOF/SE0 condition
									//any bus operation should start from this, so any read/write start //at begin of frame
localparam CMD_SEND_PKT  = 4'h4; //new packed will be sent to bus. high 4 bits of cmd byte mean data length
localparam CMD_READ_PKT  = 4'h5;
localparam CMD_AUTO_ACK  = 4'h6;

//controller state machine states
localparam STATE_IDLE = 0;
localparam STATE_READ_CMD = 1;
localparam STATE_GOT_CMD = 2;
localparam STATE_READ_LINES = 3;
localparam STATE_BUS_CONTROL = 4;
localparam STATE_WAIT_EOF = 5;
localparam STATE_WAIT_NO_EOF = 6;
localparam STATE_WAIT_BIT0 = 7;
localparam STATE_WAIT_BIT1 = 8;
localparam STATE_FETCH_SEND_BYTE = 9;
localparam STATE_CATCH_SEND_BYTE = 10;
localparam STATE_FETCH_SEND_BYTE1 = 11;
localparam STATE_CATCH_SEND_BYTE1 = 12;
localparam STATE_SENDING = 13;
localparam STATE_WAIT_ACK = 14;
localparam STATE_READ_DATA = 15;
localparam STATE_READ_DATA_ALL = 16;
localparam STATE_COPY_TMP_PKT = 17;
localparam STATE_COPY_TMP_PKT2 = 18;
localparam STATE_SEND_ACK_WAIT_BIT0 = 19;
localparam STATE_SEND_ACK_WAIT_BIT1 = 20;
localparam STATE_SEND_ACK_80 = 21;
localparam STATE_SEND_ACK_D2 = 22;

reg [7:0]state = 0;

//make low speed bit impulse
reg [2:0]cnt;
reg bit_impulse;
always @( posedge cclk or posedge rst )
begin
	if(rst)
	begin
		cnt <= 0;
		bit_impulse <= 0;
	end
	else
	begin
		cnt <= cnt + 1;
		bit_impulse <= (cnt==7);
	end
end

//make frame EOF impulse
reg eof;
reg [10:0]bit_time;
always @(posedge cclk or posedge rst)
begin
	if(rst)
	begin
		bit_time <= 0;
		eof <= 1'b0;
	end
	else
	begin
		if(bit_impulse)
		begin
			if(bit_time==1499)
				bit_time <= 0;
			else
				bit_time <= bit_time + 1'b1;
		end
		
		eof <= (bit_time > 1497 );
	end
end

wire in_empty;
wire [1:0]in_rd_level;
wire [7:0]in_cmd;
reg in_rd=1'b0;

//input data and commands go into FIFO
generic_fifo_dc_gray #( .dw(8), .aw(6) ) fifo_in(
	.rst( ~rst ),
	.rd_clk( cclk ),
	.wr_clk( iclk ),
	.clr( 1'b0 ),
	.din( wdata ),
	.we( wr ),
	.dout( in_cmd ),
	.rd( in_rd ),
	.full(),
	.empty( in_empty ),
	.wr_level( wr_level ),
	.rd_level( in_rd_level )
	);

assign leds = in_cmd;

//result data go to output FIFO
wire [7:0]out_data;
wire out_data_wr;
wire empty;
assign rdata_ready = ~empty;

generic_fifo_dc_gray #( .dw(8), .aw(4) ) fifo_out(
	.rst( ~rst ),
	.rd_clk( iclk ),
	.wr_clk( cclk ),
	.clr( 1'b0 ),
	.din( out_data ),
	.we(  out_data_wr ),
	.dout( rdata ),
	.rd( rd ),
	.full(),
	.empty( empty ),
	.wr_level(  ),
	.rd_level( )
	);

wire [7:0]usb_rdata;
wire usb_rdata_ready;
wire eop_r;
wire enable_recv;

//Need temporary fifo to store USB packet received from USB bus.
//When USB packet received, then we know actual packet length and then
//we can copy temporary data into output fifo, but first in protocol go packet length encoded with command
wire [7:0]tmp_fifo_data;
wire tmp_fifo_rd; assign tmp_fifo_rd = (~tmp_fifo_empty) & (state==STATE_COPY_TMP_PKT);
wire tmp_fifo_empty;
generic_fifo_dc_gray #( .dw(8), .aw(4) ) fifo_out_tmp(
	.rst( ~rst ),
	.rd_clk( cclk ),
	.wr_clk( cclk ),
	.clr( state==STATE_READ_DATA ), //reset tmp fifo at begin of any recv packet
	.din( usb_rdata ),
	.we(  usb_rdata_ready ),
	.dout( tmp_fifo_data ),
	.rd( tmp_fifo_rd ),
	.full(),
	.empty( tmp_fifo_empty ),
	.wr_level(  ),
	.rd_level( )
	);

assign out_data = 
		(state==STATE_READ_LINES) ? { 2'b00, i_dp, i_dm, CMD_GET_LINES }: 
		( (state==STATE_READ_DATA_ALL) & got_recv_pkt_length) ? { usb_rbyte_cnt, CMD_READ_PKT }: 
		tmp_fifo_data;

assign out_data_wr = 
		(state==STATE_READ_LINES) | 
		((state==STATE_READ_DATA_ALL) & got_recv_pkt_length) | 
		(state==STATE_COPY_TMP_PKT & (~tmp_fifo_empty) );
		
assign enable_recv = (state==STATE_READ_DATA) | (state==STATE_READ_DATA_ALL);

always @*
	in_rd = (state==STATE_READ_CMD) || (state==STATE_FETCH_SEND_BYTE) || (state==STATE_FETCH_SEND_BYTE1);
	
reg cmd_ready=1'b0;
always @( posedge cclk )
	cmd_ready <= in_rd;

reg [7:0]in_cmd_;
always @( posedge cclk )
	if( cmd_ready && state==STATE_GOT_CMD )
		in_cmd_ <= in_cmd;

reg [7:0]send_byte;
always @( posedge cclk )
	if( cmd_ready && (state==STATE_CATCH_SEND_BYTE || state==STATE_CATCH_SEND_BYTE1) )
		send_byte <= in_cmd;

reg bus_reset;
reg bus_enable;
always @( posedge cclk or posedge rst )
begin
	if(rst)
	begin
		bus_reset  <= 1'b0;
		bus_enable <= 1'b0;
	end
	else
	if( state==STATE_BUS_CONTROL )
	begin
		bus_reset  <= in_cmd_[4];
		bus_enable <= in_cmd_[5];
	end
end

always @( posedge cclk )
begin
	case( state )
	STATE_IDLE: begin 
					if( ~in_empty )
						state <= STATE_READ_CMD;
				end
	STATE_READ_CMD: begin 
						state <= STATE_GOT_CMD;
				end
	STATE_GOT_CMD: begin 
						case( in_cmd[3:0] )
							CMD_GET_LINES: state <= STATE_READ_LINES;
							CMD_BUS_CTRL:  state <= STATE_BUS_CONTROL;
							CMD_WAIT_EOF:  state <= STATE_WAIT_EOF;
							CMD_SEND_PKT:  state <= STATE_WAIT_BIT0;
							CMD_READ_PKT:  state <= STATE_READ_DATA;
							CMD_AUTO_ACK:  state <= STATE_SEND_ACK_WAIT_BIT0;
						default:
							   state <= STATE_IDLE;
						endcase
				end
	STATE_READ_LINES: begin 
					state <= STATE_IDLE;
				end
	STATE_BUS_CONTROL: begin
					state <= STATE_IDLE;
				end
	STATE_WAIT_EOF: begin
					if( bit_impulse & eof )
						state <= STATE_WAIT_NO_EOF;
				end
	STATE_WAIT_NO_EOF: begin
					if( bit_impulse & (~eof) )
						state <= STATE_IDLE;
				end
	STATE_WAIT_BIT0: begin
					if( bit_impulse &(~eof) )
						state <= STATE_WAIT_BIT1;
				end
	STATE_WAIT_BIT1: begin
					if( bit_impulse )
						state <= STATE_FETCH_SEND_BYTE;
				end
	STATE_FETCH_SEND_BYTE: begin 
				state <= STATE_CATCH_SEND_BYTE;
				end
	STATE_CATCH_SEND_BYTE: begin
				if( start_pkt)
					state <= STATE_FETCH_SEND_BYTE1;
				end
	STATE_FETCH_SEND_BYTE1: begin 
				state <= STATE_CATCH_SEND_BYTE1;
				end
	STATE_CATCH_SEND_BYTE1: begin
					state <= STATE_SENDING;
				end
	STATE_SENDING: begin 
				if( show_next & num_bytes_sent<in_cmd_[7:4])
					state <= STATE_FETCH_SEND_BYTE1;
				else
				if( pkt_end )
					state <= STATE_IDLE;
				end
	STATE_SEND_ACK_WAIT_BIT0: begin
					//here we may decide to ACK or not to ACK and got to STATE_IDLE..
					//if recent received byte is 0x5A(NAK) then no need to auto-ACK
					if( last_recv_byte==8'h5A )
						state <= STATE_IDLE;
					else
					if( bit_impulse )
						state <= STATE_SEND_ACK_WAIT_BIT1;
				end

	STATE_SEND_ACK_WAIT_BIT1: begin
					if( bit_impulse )
						state <= STATE_SEND_ACK_80;
				end
	STATE_SEND_ACK_80: begin
						state <= STATE_SEND_ACK_D2;
				end
	STATE_SEND_ACK_D2: begin
					if(show_next)
						state <= STATE_IDLE;
				end
	STATE_WAIT_ACK: begin
					state <= STATE_IDLE;
				end
	STATE_READ_DATA: begin 
					state <= STATE_READ_DATA_ALL;
				end
	STATE_READ_DATA_ALL: begin 
					if( eof | eop_r )
						state <= STATE_COPY_TMP_PKT;
				end
	STATE_COPY_TMP_PKT: begin 
					state <= STATE_COPY_TMP_PKT2;
				end
	STATE_COPY_TMP_PKT2: begin 
					if( tmp_fifo_empty )
						state <= STATE_IDLE;
					else
						state <= STATE_COPY_TMP_PKT;
				end
	endcase
end

reg [3:0]num_bytes_sent;
always @( posedge cclk )
	if( state==STATE_GOT_CMD )
		num_bytes_sent<= 1;
	else
	if( start_pkt | show_next )
		num_bytes_sent <= num_bytes_sent+1;
		
wire start_pkt; assign start_pkt = (state==STATE_CATCH_SEND_BYTE) & bit_impulse;
wire pkt_end;

wire [7:0]actual_send_byte;
assign actual_send_byte = 
	(state==STATE_SEND_ACK_80) ? 8'h80 : //maybe auto-ack or real data from SW
	(state==STATE_SEND_ACK_D2) ? 8'hD2 : send_byte;
	
wire actual_start_pkt;
assign actual_start_pkt = start_pkt | (state==STATE_SEND_ACK_80);

wire actual_last_pkt_byte;
assign actual_last_pkt_byte = (num_bytes_sent==in_cmd_[7:4]) | (state==STATE_SEND_ACK_D2);

wire show_next;
ls_usb_send ls_usb_send_(
	.reset( rst ),
	.clk( cclk ),
	.bit_impulse( bit_impulse ),
	.eof( eof ),
	.sbyte( actual_send_byte ),  			//byte for send
	.start_pkt( actual_start_pkt ),		//start sending packet on that signal
	.last_pkt_byte( actual_last_pkt_byte ),			//mean send EOP at the end
	.cmd_reset( bus_reset ),
	.cmd_enable( bus_enable ),
	.dp( o_dp ),
	.dm( o_dm ),
	.bus_enable( o_oe ),
	.show_next( show_next ), 	//request for next sending byte in packet
	.pkt_end( pkt_end )		//mean that packet was sent
	);

wire [3:0]usb_rbyte_cnt;
ls_usb_recv ls_usb_recv_(
	.reset( rst ),
	.clk( cclk ),
	.dp( i_dp ),
	.dm( i_dm ),
	.enable( enable_recv ),
	.eop_r( eop_r ),
	.rdata( usb_rdata ),
	.rdata_ready( usb_rdata_ready ),
	.rbyte_cnt( usb_rbyte_cnt ),
	.eop_rfe( )
	);

reg [7:0]last_recv_byte;
always @(posedge cclk)
	if(usb_rdata_ready) 
		last_recv_byte <= usb_rdata;

reg eop_r_;
always @(posedge cclk)
	eop_r_ <= eop_r;
wire got_recv_pkt_length;
assign got_recv_pkt_length = ((eop_r_==1'b0) && (eop_r==1'b1));
	
endmodule
