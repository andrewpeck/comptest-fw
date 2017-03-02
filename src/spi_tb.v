
module spi_tb (); 


reg sys_clk = 0; 

reg clock=0; 

always @* 
	#3.125 sys_clk <= ~sys_clk; 
	
always @*
 #12.5 clock <= ~clock; 

reg reset = 1; 
always @(posedge clock) 
reset <= 0; 


reg [15:0] data_stream = 16'h5555;
reg [7:0] adr_stream = 8'h55;

reg [11:0] clk_cnt = 0; 
always @(negedge clock) 
	if (!reset)
	clk_cnt = clk_cnt + 1;

wire [24:0] mosi_stream = {data_stream,adr_stream}; 	

reg mosi; 
always @* begin
if (clk_cnt < 8)
	mosi = 1'b1&(mosi_stream >> (7-clk_cnt)); 
else
	mosi = 1'b1&(mosi_stream >> (23+8-clk_cnt)); 
end


//Instantiate the module

wire miso; 

reg cs=1; 
always @(posedge clock)  begin
if (clk_cnt > 25) 
cs = 0; 
end

wire [15:0] data_wr; 
wire [15:0] data_rd=16'hffff; 
wire [7:0] adr; 

// Instantiate the module
spi instance_name (
	  .sys_clk(sys_clk), 
    .mosi(mosi), 
    .miso(miso), 
    .sclk(clock), 
    .cs(cs), 
    .adr_latched(adr_latched), 
    .data_latched(data_latched), 
    .adr(adr), 
    .data_wr(data_wr), 
    .data_rd(data_rd)
 );








endmodule
