
//simplest low speed USB CORE function

module ls_usb_core(

	//clock should be 5Mhz
	input wire clk,

	input wire EOP,
	input wire [7:0]data,
	input wire wre,

	input wire [3:0]rbyte_cnt,

	input wire show_next,

	output reg [7:0]sbyte,
	output reg start_pkt,
	output reg last_pkt_byte,
	output reg [7:0]leds
	);

//PIDs of last 2 received packets
reg [3:0]pid0;
reg [3:0]pid1;
reg [1:0]toggle;

always @(posedge clk)
begin
	if( (rbyte_cnt==4'h1) & wre)
	begin
		pid1 <= pid0;
		pid0 <= data[3:0];
	end
end

reg [3:0]setup_req;
always @(posedge clk)
begin
	if( (rbyte_cnt==4'h3) & wre & (pid1==4'hd) )
		setup_req <= data[3:0];
end

always @(posedge clk)
begin
	if( (rbyte_cnt==4'h6) & wre & (pid1==4'hd) )
		leds <= data[7:0];
end

/*
reg setup_val0;
always @(posedge clk)
begin
	if( (rbyte_cnt==4'h4) & wre & (pid1==4'hd) )
		setup_val0 <= data[0];
end
*/

reg [3:0]setup_val;
always @(posedge clk)
begin
	if( (rbyte_cnt==4'h5) & wre & (pid1==4'hd) )
		setup_val <= data[3:0];
end

reg [3:0]setup_len;
always @(posedge clk)
begin
	if( (rbyte_cnt==4'h8) & wre & (pid1==4'hd) )
		setup_len <= data[3:0];
end

//sending bytes table
reg [7:0]sptr;
reg [7:0]sb; //byte for send and flag for last packet

always @*
begin
	case(sptr)
	//ACK packet
	8'h00: sb = 8'h81;	//SYN	
	8'h01: sb = 8'hD2;	//last in packet
	8'h02: sb = 8'h00;
	8'h03: sb = 8'h00;
	8'h04: sb = 8'h00;
	8'h05: sb = 8'h00;
	8'h06: sb = 8'h00;
	8'h07: sb = 8'h00;
	8'h08: sb = 8'h00;
	8'h09: sb = 8'h00;
	8'h0a: sb = 8'h00;
	8'h0b: sb = 8'h00;
	8'h0c: sb = 8'h00;
	8'h0d: sb = 8'h00;
	8'h0e: sb = 8'h00;
	8'h0f: sb = 8'h00;
	
	//config descriptor 
	8'h10: sb = 8'h8b; //SYN
	8'h11: sb = 8'h4B;
	8'h12: sb = 8'h12;	//12 01 00 01 FF 00 00 08 23 f3
	8'h13: sb = 8'h01;
	8'h14: sb = 8'h00;
	8'h15: sb = 8'h01;
	8'h16: sb = 8'hff;
	8'h17: sb = 8'h00;
	8'h18: sb = 8'h00;
	8'h19: sb = 8'h08;
	8'h1a: sb = 8'h23;
	8'h1b: sb = 8'hf3;	//last in packet
	8'h1c: sb = 8'h00;
	8'h1d: sb = 8'h00;
	8'h1e: sb = 8'h00;
	8'h1f: sb = 8'h00;

	//config descriptor continued
	8'h20: sb = 8'h8b; 	//SYN
	8'h21: sb = 8'hC3;
	8'h22: sb = 8'hB9;	//B9 04 00 03 00 02 02 01 14 4a
	8'h23: sb = 8'h04;
	8'h24: sb = 8'h00;
	8'h25: sb = 8'h03;
	8'h26: sb = 8'h00;
	8'h27: sb = 8'h02;
	8'h28: sb = 8'h02;
	8'h29: sb = 8'h00;
	8'h2a: sb = 8'hd5;
	8'h2b: sb = 8'h8a;
	8'h2c: sb = 8'h00;
	8'h2d: sb = 8'h00;
	8'h2e: sb = 8'h00;
	8'h2f: sb = 8'h00;

	//config descriptor continued
	8'h30: sb = 8'h85; 	//SYN
	8'h31: sb = 8'h4B;
	8'h32: sb = 8'h00;	//00 01 3f 8f
	8'h33: sb = 8'h01;
	8'h34: sb = 8'h3f;
	8'h35: sb = 8'h8f;
	8'h36: sb = 8'h00;
	8'h37: sb = 8'h00;
	8'h38: sb = 8'h00;
	8'h39: sb = 8'h00;
	8'h3a: sb = 8'h00;
	8'h3b: sb = 8'h00;
	8'h3c: sb = 8'h00;
	8'h3d: sb = 8'h00;
	8'h3e: sb = 8'h00;
	8'h3f: sb = 8'h00;

	//empty IN
	8'h40: sb = 8'h83; 	//SYN
	8'h41: sb = 8'h4B;
	8'h42: sb = 8'h00;
	8'h43: sb = 8'h00;
	8'h44: sb = 8'h00;
	8'h45: sb = 8'h00;
	8'h46: sb = 8'h00;
	8'h47: sb = 8'h00;
	8'h48: sb = 8'h00;
	8'h49: sb = 8'h00;
	8'h4a: sb = 8'h00;
	8'h4b: sb = 8'h00;
	8'h4c: sb = 8'h00;
	8'h4d: sb = 8'h00;
	8'h4e: sb = 8'h00;
	8'h4f: sb = 8'h00;

	//config descriptor configuration
	8'h50: sb = 8'h8b; 	//SYN
	8'h51: sb = 8'h4B;
	8'h52: sb = 8'h09;
	8'h53: sb = 8'h02;
	8'h54: sb = 8'h14;
	8'h55: sb = 8'h00;
	8'h56: sb = 8'h01;
	8'h57: sb = 8'h01;
	8'h58: sb = 8'h00;
	8'h59: sb = 8'h80;
	8'h5a: sb = 8'h0e;
	8'h5b: sb = 8'hd6;
	8'h5c: sb = 8'h00;
	8'h5d: sb = 8'h00;
	8'h5e: sb = 8'h00;
	8'h5f: sb = 8'h00;

	//config descriptor configuration continued
	8'h60: sb = 8'h84; 	//SYN
	8'h61: sb = 8'hC3;
	8'h62: sb = 8'h0d;
	8'h63: sb = 8'h81;
	8'h64: sb = 8'h7a;
	8'h65: sb = 8'h00;
	8'h66: sb = 8'h00;
	8'h67: sb = 8'h00;
	8'h68: sb = 8'h00;
	8'h69: sb = 8'h00;
	8'h6a: sb = 8'h00;
	8'h6b: sb = 8'h00;
	8'h6c: sb = 8'h00;
	8'h6d: sb = 8'h00;
	8'h6e: sb = 8'h00;
	8'h6f: sb = 8'h00;

	//config descriptor configuration
	8'h70: sb = 8'h8b; 	//SYN
	8'h71: sb = 8'h4B;
	8'h72: sb = 8'h09;
	8'h73: sb = 8'h02;
	8'h74: sb = 8'h14;
	8'h75: sb = 8'h00;
	8'h76: sb = 8'h01;
	8'h77: sb = 8'h01;
	8'h78: sb = 8'h00;
	8'h79: sb = 8'h80;
	8'h7a: sb = 8'h0e;
	8'h7b: sb = 8'hd6;
	8'h7c: sb = 8'h00;
	8'h7d: sb = 8'h00;
	8'h7e: sb = 8'h00;
	8'h7f: sb = 8'h00;

	//config descriptor configuration continued
	8'h80: sb = 8'h8b; 	//SYN
	8'h81: sb = 8'hC3;
	8'h82: sb = 8'h0d;
	8'h83: sb = 8'h09;
	8'h84: sb = 8'h04;
	8'h85: sb = 8'h00;
	8'h86: sb = 8'h00;
	8'h87: sb = 8'h00;
	8'h88: sb = 8'hff;
	8'h89: sb = 8'h00;
	8'h8a: sb = 8'ha7;
	8'h8b: sb = 8'h19;
	8'h8c: sb = 8'h00;
	8'h8d: sb = 8'h00;
	8'h8e: sb = 8'h00;
	8'h8f: sb = 8'h00;

	//config descriptor configuration continued
	8'h90: sb = 8'h87; 	//SYN
	8'h91: sb = 8'h4B;
	8'h92: sb = 8'h00;
	8'h93: sb = 8'h00;
	8'h94: sb = 8'h02;
	8'h95: sb = 8'h40;
	8'h96: sb = 8'hff;
	8'h97: sb = 8'h4b;
	8'h98: sb = 8'h00;
	8'h99: sb = 8'h00;
	8'h9a: sb = 8'h00;
	8'h9b: sb = 8'h00;
	8'h9c: sb = 8'h00;
	8'h9d: sb = 8'h00;
	8'h9e: sb = 8'h00;
	8'h9f: sb = 8'h00;

	default:
		sb = 8'h00;
	endcase
end

reg [1:0]state;
reg [3:0]pkt_len;

always @(posedge clk)
begin
	if(sptr[3:0]==4'h0)
		pkt_len <= sb[3:0];
/*	
	if(sptr[3:0]==4'h0)	
		sbyte <= {sb[7:4],4'b0000};
	else
		sbyte <= sb;

	last_pkt_byte <= (sptr[3:0]==pkt_len);
*/
end

always @*
begin
	if(sptr[3:0]==4'h0)	
		sbyte = {sb[7:4],4'b0000};
	else
		sbyte = sb;

	last_pkt_byte = (sptr[3:0]==pkt_len);
end

always @(posedge clk)
begin
	if( (state==0) & (!EOP) )
	begin
		if(pid0==4'hd) //0x2D
			toggle <= 2'b00;
		else
		if(pid0==4'h9) //0x69
			toggle <= toggle + 1'b1;
	end
end

always @(posedge clk or posedge EOP)
begin
	if(EOP)
	begin
		//kind of reset
		start_pkt <= 1'b0;
		state <= 0;
		sptr  <= 8'h00;
	end
	else
	begin
		start_pkt <= (state==2'b10);

		case(state)
		0:
		begin
			//do nothing but just after EOP check last PIDs
			if( ((pid0==4'hb) | (pid0==4'h3)) & ((pid1==4'hd) | (pid1==4'h1)) ) // (0x4b or 0xc3) and (0x2d and 0xE1) 
			begin
				state <= 2;			//should send packet
				sptr[7:4] <= 4'h0;	//packet will be ACK
				sptr[3:0] <= 4'h0;
			end
			else
			if( (pid0==4'h9)&(setup_req==4'h6)&(setup_val==4'h1))
			begin
				state <= 2;			//should send packet
				sptr[7:4] <= 4'h1+toggle;	//packet will be config descriptor
				sptr[3:0] <= 4'h0;
			end
			else
			if( (pid0==4'h9)&(setup_req==4'h6)&(setup_val==4'h2)&(setup_len==4'h9))
			begin
				state <= 2;			//should send packet
				sptr[7:4] <= 4'h5+toggle;	//packet will be config descriptor configuration
				sptr[3:0] <= 4'h0;
			end
			else
			if( (pid0==4'h9)&(setup_req==4'h6)&(setup_val==4'h2)&(setup_len!=4'h9))
			begin
				state <= 2;			//should send packet
				sptr[7:4] <= 4'h7+toggle;	//packet will be config descriptor configuration
				sptr[3:0] <= 4'h0;
			end
			else
			if(pid0==4'h9)
			begin
				state <= 2;			//should send packet
				sptr[7:4] <= 4'h4;	//empty IN
				sptr[3:0] <= 4'h0;
			end
			else
			begin
				state <= 1; //should do nothing
				sptr<=8'h00;
			end
		end
		1:
		begin
			//do nothing
			state <= 1;
			sptr  <= 8'h00;
		end
		2:
		begin
			//initiate send packet
			state <= 3;
			sptr  <= sptr;
		end
		3:
		begin
			state <= 3;
			sptr[3:0] <= sptr[3:0] + show_next;
			sptr[7:4] <= sptr[7:4];
		end
		endcase
	end
end

endmodule
