
module triad_tb (); 


reg clock=0; 

always @*
 #12.5 clock <= ~clock; 


reg [31:0] triad_stream = 32'b00000000000000110000001110111000;

reg [11:0] clk_cnt = 0; 
always @(posedge clock) 
	clk_cnt = clk_cnt + 1; 

wire triad = triad_stream >> clk_cnt; 
	
reg reset = 1; 
always @(posedge clock) 
reset <= 0; 

wire [3:0] h_strip; 
wire triad_skip; 

//Instantiate the module
triad_decode instance_name (
	.clock(clock), 
	.reset(reset), 
	.persist(4'd4), 
	.persist1(0), 
	.triad(triad), 
	.h_strip(h_strip), 
	.triad_skip(triad_skip)
);





endmodule
