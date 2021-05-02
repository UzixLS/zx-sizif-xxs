
//simplest low speed USB receive function

module ls_usb_recv(
	input wire reset,
	
	//clock should be 12Mhz
	input wire clk,

	//usb BUS signals
	input wire dp,
	input wire dm,
	
	input wire enable,

	output wire eop_r,

	//output received bytes interface
	output reg [7:0]rdata,
	output reg rdata_ready,
	output reg [3:0]rbyte_cnt,

	output wire eop_rfe //receive EOP falling edge
	);

////////////////////////////////////////////////////////
//receiver regs
////////////////////////////////////////////////////////

reg [2:0]receiver_cnt;

//fix current USB line values
reg [1:0]dp_input;
reg [1:0]dm_input;

always @(posedge clk)
begin		
	dp_input <= { dp_input[0], dp };
	dm_input <= { dm_input[0], dm };
end

//if both lines in ZERO this is low speed EOP
//EOP reinitializes receiver
assign eop_r  = !(dp_input[0] | dp_input[1] | dm_input[0] | dm_input[1]);

//find edge of receive EOP
assign eop_rfe = receiver_enabled & (eop_r);

//logic for enabling/disabling receiver
reg receiver_enabled;
always @(posedge clk or posedge reset )
	if(reset)
		receiver_enabled <= 1'b0;
	else
	if( eop_r) //disable on any EOP
		receiver_enabled <= 1'b0;
	else
	if( dp_input[0] )  //enable receiver on raising edge of DP line
		receiver_enabled <= enable;

//change on DP line defines strobing
wire dp_change;
assign dp_change = dp_input[0] ^ dp_input[1];

//generate clocked receiver strobe with this counter
reg [2:0]clk_counter;
always @(posedge clk or posedge reset )
begin		
	if(reset)
		clk_counter <= 3'b000;
	else
	begin		
		//every edge on line resynchronizes receiver clock
		if(dp_change | eop_r)
			clk_counter <= 3'b000;
		else
			clk_counter <= clk_counter + 1'b1;
	end
end

reg r_strobe;
always @*
	r_strobe = (clk_counter == 3'b011) & receiver_enabled;

//on receiver strobe remember last fixed DP value
reg last_fixed_dp;
always @(posedge clk or posedge reset)
begin
	if(reset)
		last_fixed_dp <= 1'b0;
	else
	begin
		if(r_strobe | eop_r)
		begin
			last_fixed_dp <= dp_input[1] & (~eop_r);
		end	
	end
end

//count number of sequental ones for bit staffling
reg [2:0]num_ones;
always @(posedge clk or posedge reset)
begin
	if(reset)
		num_ones <= 3'b000;
	else
	begin
		if(r_strobe)
		begin
			if(last_fixed_dp == dp_input[1])
				num_ones <= num_ones + 1'b1;
			else
				num_ones <= 3'b000;
		end
	end
end

//flag which mean that zero should be removed from bit stream because of bitstuffling
wire do_remove_zero; assign do_remove_zero = (num_ones == 6);

//receiver process
always @(posedge clk or posedge reset )
begin		
	if(reset)
	begin
		//kind of reset
		receiver_cnt <= 0;
		rdata <= 0;
		rdata_ready <= 1'b0;
	end
	else
	begin		

		if(r_strobe & (!do_remove_zero) | eop_r)
		begin
			//decode NRZI
			//shift-in ONE  if older and new values are same
			//shift-in ZERO if older and new values are different
			//BUT (bitstuffling) do not shift-in one ZERO after 6 ONEs
			if(eop_r)
			begin
				receiver_cnt <= 0;
				rdata  <= 0;
			end
			else
			begin
				receiver_cnt <= receiver_cnt + 1'b1;
				rdata  <= { (last_fixed_dp == dp_input[1]) , rdata[7:1]};
			end
		end

		//set write-enable signal (write into receiver buffer)
		rdata_ready <= (receiver_cnt == 7) & r_strobe & (!do_remove_zero) & (~eop_r);
	end
end

//count number of received bytes
always @(posedge clk or posedge reset )
begin		
	if(reset)
		rbyte_cnt <= 0;
	else
	begin
		if(eop_rfe)
			rbyte_cnt <= 0;
		else
		if(rdata_ready)
			rbyte_cnt <= rbyte_cnt + 1'b1;
	end
end

endmodule
