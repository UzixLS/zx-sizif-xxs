
//low speed USB send function

module ls_usb_send(
	input wire reset,
	
	//clock should be 12Mhz
	input wire clk,
	input wire bit_impulse,
	input wire eof,

	input wire [7:0]sbyte,  	//byte for send
	input wire start_pkt,		//start sending packet on that signal
	input wire last_pkt_byte,	//mean send EOP at the end

	//received from host
	input wire cmd_reset,
	input wire cmd_enable,
	
	//usb BUS signals
	output reg dp,
	output reg dm,
	output reg  bus_enable,

	//usb BUS signals for 
	output reg  show_next, 	//request for next sending byte in packet
	output reg  pkt_end		//mean that packet was sent
	);

reg sbit;
reg  se0;
always @*
begin
	sbit = (prev_sbit ^ (!send_reg[0]) ^ (six_ones & send_reg[0])) & bus_ena_pkt;
	se0 = !(bus_ena_pkt ^ (bus_ena_pkt | bus_ena_prev[1]));
	show_next = (bit_count==3'h7) & sending_bit & bus_ena_pkt & (!last);
	pkt_end = bus_enable & (!bus_ena_pkt) & (bit_count==3'h3) & bit_impulse;
end

//USB Reset and USB Enable become actual with frame start only
reg usb_reset_fixed;
reg usb_enable_fixed;

always @(posedge clk or posedge reset)
begin
	if(reset)
	begin
		usb_reset_fixed  <= 1'b0;
		usb_enable_fixed <= 1'b0;
	end
	else
	if(eof)
	begin
		usb_reset_fixed  <= cmd_reset;
		usb_enable_fixed <= cmd_enable;
	end
end

//bus enable signal, which is related to packet sending
reg bus_ena_pkt;
always @(posedge clk or posedge reset)
begin
	if(reset)
		bus_ena_pkt <= 1'b0;
	else
	begin
		if(start_pkt)
			bus_ena_pkt <= 1'b1;
		else
		if( sending_last_bit & last | eof)
			bus_ena_pkt <= 1'b0;
	end
end

//delay shift register for bus enable for packet
reg [2:0]bus_ena_prev;
always @(posedge clk or posedge reset)
begin
	if(reset)
		bus_ena_prev <= 3'b000;
	else
	if(bit_impulse)
		bus_ena_prev <= {bus_ena_prev[1:0],bus_ena_pkt};
end

reg eof_f;
always @(posedge clk or posedge reset)
	if(reset)
		eof_f <= 1'b0;
	else
	if(bit_impulse)
		eof_f <= eof;

//bus enable generation
always @(posedge clk or posedge reset)
	if(reset)
		bus_enable <= 1'b0;
	else
	if(bit_impulse)
		bus_enable <= ((bus_ena_pkt | bus_ena_prev[2])) 
			| usb_reset_fixed 	//bus enabled when reset
			| (usb_enable_fixed & (eof|eof_f) ); //bus enabled for keep-alive messages

wire suppress; assign suppress = usb_reset_fixed | (usb_enable_fixed & eof);

//make output on USB buses
always @(posedge clk or posedge reset)
	if(reset)
	begin
		dp <= 1'b0;
		dm <= 1'b0;
	end
	else
	if(bit_impulse)
	begin
		dp <= suppress ? 1'b0 : (  sbit  & se0 );
		dm <= suppress ? 1'b0 : ((!sbit) & se0 );
	end

//count number of sequental ONEs
reg [2:0]ones_cnt;
wire six_ones; assign six_ones = (ones_cnt==3'h6);
wire sending_bit = bit_impulse & (!six_ones);

always @(posedge clk or posedge reset)
begin
	if(reset)
		ones_cnt <= 0;
	else
	begin
		if(eof)
			ones_cnt <= 0;
		else
		if(bit_impulse & bus_ena_pkt)
		begin
			if(sbit==prev_sbit)
				ones_cnt <= ones_cnt+1'b1;
			else
				ones_cnt <= 0;
		end
	end
end

//fix just sent bit
reg prev_sbit;
always @(posedge clk or posedge reset)
begin
	if(reset)
		prev_sbit <= 1'b0;
	else
	begin
		if( start_pkt )
			prev_sbit <= 1'b0;
		else
		if(bit_impulse & bus_ena_pkt )
			prev_sbit <= sbit;
	end
end

//fix flag about last byte in packet
reg last;
always @(posedge clk or posedge reset)
begin
	if(reset)
		last <= 1'b0;
	else
	begin
		if( start_pkt )
			last <= 1'b0;
		else
		if(sending_last_bit)
			last <= last_pkt_byte;
	end
end

//count number of sent bits
reg [2:0]bit_count;
always @(posedge clk or posedge reset)
begin
	if(reset)
		bit_count <= 3'b000;
	else
	begin
		if( start_pkt )
			bit_count <= 3'b000;
		else
		if( sending_bit)
			bit_count <= bit_count + 1'b1;
	end
end

wire bit_count_eq7; assign bit_count_eq7 = (bit_count==3'h7);
wire sending_last_bit = sending_bit & bit_count_eq7; //sending last bit in byte

//load/shift sending register
reg [7:0]send_reg;
always @(posedge clk or posedge reset)
begin
	if(reset)
		send_reg <= 0;
	else
	begin
		if(eof)
			send_reg <= 0;
		else
		if(sending_bit | start_pkt)
		begin	 
			if(bit_count_eq7 | start_pkt)
				send_reg <= sbyte;					//load first or next bytes for send
			else
				send_reg <= {1'b0, send_reg[7:1]}; 	//shift out byte
		end
	end
end

endmodule
