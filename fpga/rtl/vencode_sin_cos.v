module vencode_sin_cos(
    input clk,
    input [7:0] phase,
    output reg [15:0] sinus,
    output reg [15:0] cosinus
);
    reg [6:0] addr1, addr2;
    wire [15:0] value1, value2;
    vencode_sin_cos_rom vencode_sin_cos_rom0(
        .address_a(addr1),
        .address_b(addr2),
        .clock(clk),
        .q_a(value1),
        .q_b(value2)
    ); 
    
    always @* begin
        if(!phase[6])
            addr1 <= {1'b0, phase[5:0]};
        else
            addr1 <= 7'h40 - {1'b0, phase[5:0]};
        if (!phase[7])
            sinus <= value1;
        else
            sinus <= -value1;
    end
    
    wire [7:0] phase_cosinus = phase + 8'b01000000;
    always @* begin
        if(!phase_cosinus[6])
            addr2 <= {1'b0, phase_cosinus[5:0]};
        else
            addr2 <= 7'h40 - {1'b0, phase_cosinus[5:0]};
        if (!phase_cosinus[7])
            cosinus <= value2;
        else
            cosinus <= -value2;
    end
endmodule


module vencode_sin_cos_rom(
    input [6:0] address_a,
    input [6:0] address_b,
    input clock,
    output reg [15:0] q_a,
    output reg [15:0] q_b
);
    reg [15:0] rom [0:64];
    initial begin
        rom <= '{
            16'h0000, 16'h025b, 16'h04b6, 16'h0710, 16'h0969, 16'h0bc0, 16'h0e16, 16'h106a,
            16'h12bb, 16'h1509, 16'h1753, 16'h199b, 16'h1bde, 16'h1e1d, 16'h2057, 16'h228d,
            16'h24bd, 16'h26e7, 16'h290c, 16'h2b2a, 16'h2d41, 16'h2f51, 16'h315b, 16'h335c,
            16'h3556, 16'h3747, 16'h3930, 16'h3b10, 16'h3ce7, 16'h3eb4, 16'h4078, 16'h4232,
            16'h43e2, 16'h4587, 16'h4722, 16'h48b1, 16'h4a36, 16'h4bae, 16'h4d1c, 16'h4e7d,
            16'h4fd2, 16'h511b, 16'h5258, 16'h5387, 16'h54aa, 16'h55c0, 16'h56c8, 16'h57c4,
            16'h58b1, 16'h5991, 16'h5a63, 16'h5b28, 16'h5bde, 16'h5c86, 16'h5d1f, 16'h5dab,
            16'h5e28, 16'h5e96, 16'h5ef6, 16'h5f47, 16'h5f8a, 16'h5fbd, 16'h5fe2, 16'h5ff9,
            16'h6000 };
    end
    always @(negedge clock) begin
        q_a <= rom[address_a];
        q_b <= rom[address_b];
    end
endmodule
