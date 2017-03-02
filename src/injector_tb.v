
module injector_tb (); 


reg clock=0; 

always @*
 #12.5 clock <= ~clock; 

reg reset = 1; 
always @(posedge clock) 
reset <= 0; 

reg [11:0] clk_cnt = 0; 
always @(negedge clock) 
	if (!reset)
	clk_cnt = clk_cnt + 1;


// Instantiate the module

parameter NTBINS=32; 


reg compout_expect = 0; 

reg [31:0] halfstrips_shr [NTBINS-1:0]; 
initial halfstrips_shr[0]  = 32'b00000000000000000000000000000000;
initial halfstrips_shr[1]  = 32'b00000000000000000000000000000000;
initial halfstrips_shr[2]  = 32'b00000000000000000000000000000000;
initial halfstrips_shr[3]  = 32'b00000000000000000000000000000000;
initial halfstrips_shr[4]  = 32'b00000000000000000000000000000000;
initial halfstrips_shr[5]  = 32'b00000000000000000000000000000000;
initial halfstrips_shr[6]  = 32'b00000000000000000000000000000000;
initial halfstrips_shr[7]  = 32'b00000000000000000000000000000000;
initial halfstrips_shr[8]  = 32'b00000000000000000000000000000000;
initial halfstrips_shr[9]  = 32'b00000000000000000000000000000000;
initial halfstrips_shr[10] = 32'b00000000000000000000000000000000;
initial halfstrips_shr[11] = 32'b00000000000000000000000000000000;
initial halfstrips_shr[12] = 32'b00000000000000000000000000000000;
initial halfstrips_shr[13] = 32'b00000000000000000000000000000000;
initial halfstrips_shr[14] = 32'b00000000000000000000000000000000;
initial halfstrips_shr[15] = 32'b00000000000000000000000000000000;
initial halfstrips_shr[16] = 32'b00000000000000000000000000000000;
initial halfstrips_shr[17] = 32'b00000001111111111111111111111000;
initial halfstrips_shr[18] = 32'b00000000000000000000000000000000;
initial halfstrips_shr[19] = 32'b00000000000000000000000000000000;
initial halfstrips_shr[20] = 32'b00000000000000000000000000000000;
initial halfstrips_shr[21] = 32'b00000000000000000000000000000000;
initial halfstrips_shr[22] = 32'b00000000000000000000000000000000;
initial halfstrips_shr[23] = 32'b00000000000000000000000000000000;
initial halfstrips_shr[24] = 32'b00000000000000000000000000000000;
initial halfstrips_shr[25] = 32'b00000000000000000000000000000000;
initial halfstrips_shr[26] = 32'b00000000000000000000000000000000;
initial halfstrips_shr[27] = 32'b00000000000000000000000000000000;
initial halfstrips_shr[28] = 32'b00000000000000000000000000000000;
initial halfstrips_shr[29] = 32'b00000000000000000000000000000000;
initial halfstrips_shr[30] = 32'b00000000000000000000000000000000;
initial halfstrips_shr[31] = 32'b00000000000000000000000000000000;

wire [31:0] halfstrip = {
halfstrips_shr[31][clk_cnt%31],
halfstrips_shr[30][clk_cnt%31],
halfstrips_shr[29][clk_cnt%31],
halfstrips_shr[28][clk_cnt%31],
halfstrips_shr[27][clk_cnt%31],
halfstrips_shr[26][clk_cnt%31],
halfstrips_shr[25][clk_cnt%31],
halfstrips_shr[24][clk_cnt%31],
halfstrips_shr[23][clk_cnt%31],
halfstrips_shr[22][clk_cnt%31],
halfstrips_shr[21][clk_cnt%31],
halfstrips_shr[20][clk_cnt%31],
halfstrips_shr[19][clk_cnt%31],
halfstrips_shr[18][clk_cnt%31],
halfstrips_shr[17][clk_cnt%31],
halfstrips_shr[16][clk_cnt%31],
halfstrips_shr[15][clk_cnt%31],
halfstrips_shr[14][clk_cnt%31],
halfstrips_shr[13][clk_cnt%31],
halfstrips_shr[12][clk_cnt%31],
halfstrips_shr[11][clk_cnt%31],
halfstrips_shr[10][clk_cnt%31],
halfstrips_shr[9][clk_cnt%31],
halfstrips_shr[8][clk_cnt%31],
halfstrips_shr[7][clk_cnt%31],
halfstrips_shr[6][clk_cnt%31],
halfstrips_shr[5][clk_cnt%31],
halfstrips_shr[4][clk_cnt%31],
halfstrips_shr[3][clk_cnt%31],
halfstrips_shr[2][clk_cnt%31],
halfstrips_shr[1][clk_cnt%31],
halfstrips_shr[0][clk_cnt%31]};

wire [31:0] halfstrips_last; 
wire [15:0] thresholds_errcnt; 
wire [15:0] offsets_errcnt; 
wire [15:0] compout_errcnt; 

reg [4:0] active_halfstrip = 17; 
reg halfstrip_mask_en =1; 

reg compout_errcnt_rst = 0; 

reg thresholds_errcnt_rst = 0; 
reg compin_inject = 1; 

reg fire_pulse = 1; 
always @(posedge clock) 
 if (clk_cnt > 18)
 fire_pulse = 0; 

reg [11:0] num_pulses = 3; 
reg [3:0] bx_delay = 12; 
reg [3:0] pulse_width = 0; 


// Instantiate the module
comparator_injector instance_name (
    .halfstrips(0),  // halfstrip
    .halfstrips_last(halfstrips_last), 
    .thresholds_errcnt(thresholds_errcnt), 
    .offsets_errcnt(offsets_errcnt), 
    .compout_errcnt(compout_errcnt), 
    .compout(compout), 
    .compout_expect(compout_expect), 
    .compout_last(compout_last), 
    .active_halfstrip(active_halfstrip), 
    .halfstrip_mask_en(halfstrip_mask_en), 
    .compout_errcnt_rst(compout_errcnt_rst), 
    .offsets_errcnt_rst(offsets_errcnt_rst), 
    .thresholds_errcnt_rst(thresholds_errcnt_rst), 
    .compin_inject(compin_inject), 
    .compin(compin), 
    .fire_pulse(fire_pulse), 
    .num_pulses(num_pulses), 
    .pulser_ready(pulser_ready), 
    .bx_delay(bx_delay), 
    .pulse_width(pulse_width), 
    .pulse_en(pulse_en), 
    .clock(clock)
    );









endmodule
