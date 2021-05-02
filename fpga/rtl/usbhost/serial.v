  
module serial(
	input wire reset,
	input wire clk100,	//96MHz
	input wire rx,
	input wire [7:0]sbyte,
	input wire send,
	output reg [7:0]rx_byte,
	output reg rbyte_ready,
	output reg rbyte_ready2, //long variant of rbyte_ready
	output reg tx,
	output reg busy, 
	output wire [7:0]rb
	);

parameter RCONST = 104; // 96000000Hz / 921600bps = 104

assign rb = {1'b0,rx_byte[7:1]};

reg [1:0]shr;
always @(posedge clk100)
	shr <= {shr[0],rx};
wire rxf; assign rxf = shr[1];

reg [15:0]cnt;
reg [3:0]num_bits;

always @(posedge clk100 or posedge reset)
begin
	if(reset)
		cnt <= 0;
	else
	begin
		if(cnt == RCONST || num_bits==10)
			cnt <= 0;
		else
			cnt <= cnt + 1'b1;
	end
end

reg [7:0]shift_reg;

always @(posedge clk100 or posedge reset)
begin
	if(reset)
	begin
		num_bits <= 0;
		shift_reg <= 0;
	end
	else
	begin
		if(num_bits==10 && rxf==1'b0)
			num_bits <= 0;
		else
		if(cnt == RCONST)
			num_bits <= num_bits + 1'b1;
		
		if( cnt == RCONST/2 )
			shift_reg <= {rxf,shift_reg[7:1]};
	end
end

always @(posedge clk100 or posedge reset)
	if(reset)
	begin
		rx_byte <= 0;
	end
	else
	begin	
	if(num_bits==9 && cnt == RCONST/2)
		rx_byte <= shift_reg[7:0];
	end

always @(posedge clk100 or posedge reset)
	if( reset )
		rbyte_ready <= 1'b0;
	else
		rbyte_ready <= (num_bits==9 && cnt == RCONST/2);

reg [8:0]send_reg;
reg [3:0]send_num;
reg [15:0]send_cnt;

wire send_time; assign send_time = send_cnt == RCONST;

always @(posedge clk100 or posedge reset)
begin
	if(reset)
	begin
		send_reg <= 9'h1FF;
		send_num <= 10;
		send_cnt <= 0;
	end
	else
	begin
		if(send)
			send_cnt <= 0;
		else
			if(send_time)
				send_cnt <= 0;
			else
				send_cnt <= send_cnt + 1'b1;
		
		if(send)
		begin
			send_reg <= {sbyte,1'b0};
			send_num <= 0;
		end
		else
		if(send_time && send_num!=10)
		begin
			send_reg <= {1'b1,send_reg[8:1]};
			send_num <= send_num + 1'b1;
		end
	end
end

always @*
begin
	busy = send_num!=10;
	tx = send_reg[0];
end
	
endmodule
