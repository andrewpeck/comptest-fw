`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   10:46:45 03/24/2015
// Design Name:   serial
// Module Name:   C:/Users/Andrew/Dropbox/CMS/Comparator/Testing/Firmware/comptest/serial_test.v
// Project Name:  comptest
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: serial
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module serial_test;

	// Inputs
	reg adc_miso;
	reg pulser_ready;
	reg [31:0] halfstrips;
	reg [31:0] halfstrips_errcnt;
	reg [31:0] compout_errcnt;
	reg ddd_miso;
	reg _reset;
	reg _ft_rxf;
	reg clk;
	reg _ft_rd;
	reg _ft_wr;
	reg [7:0] ft_byte_out;

	// Outputs
	wire adc_sclk;
	wire _adc_cs;
	wire adc_mosi;
	wire _pdac_en;
	wire pdac_din;
	wire pdac_sclk;
	wire [2:0] bx_delay;
	wire [3:0] pulse_width;
	wire fire_pulse;
	wire [31:0] halfstrips_expect;
	wire halfstrips_errcnt_rst;
	wire compout_expect;
	wire compout_errcnt_rst;
	wire compin_inject;
	wire [2:0] pktime;
	wire [1:0] pkmode;
	wire lctrst;
	wire _cdac_en;
	wire cdac_din;
	wire cdac_sclk;
	wire [15:0] mux_a0;
	wire [15:0] mux_a1;
	wire mux_a0_next;
	wire mux_a1_next;
	wire mux_a0_prev;
	wire mux_a1_prev;
	wire _ddd_al;
	wire ddd_mosi;
	wire ddd_sclk;
	wire _serial_wr;
	wire _serial_rd;
	wire [7:0] ft_byte_in;

	// Instantiate the Unit Under Test (UUT)
	serial uut (
		.adc_sclk(adc_sclk), 
		._adc_cs(_adc_cs), 
		.adc_mosi(adc_mosi), 
		.adc_miso(adc_miso), 
		._pdac_en(_pdac_en), 
		.pdac_din(pdac_din), 
		.pdac_sclk(pdac_sclk), 
		.bx_delay(bx_delay), 
		.pulse_width(pulse_width), 
		.fire_pulse(fire_pulse), 
		.pulser_ready(pulser_ready), 
		.halfstrips(halfstrips), 
		.halfstrips_expect(halfstrips_expect), 
		.halfstrips_errcnt(halfstrips_errcnt), 
		.halfstrips_errcnt_rst(halfstrips_errcnt_rst), 
		.compout_expect(compout_expect), 
		.compout_errcnt(compout_errcnt), 
		.compout_errcnt_rst(compout_errcnt_rst), 
		.compin_inject(compin_inject), 
		.pktime(pktime), 
		.pkmode(pkmode), 
		.lctrst(lctrst), 
		._cdac_en(_cdac_en), 
		.cdac_din(cdac_din), 
		.cdac_sclk(cdac_sclk), 
		.mux_a0(mux_a0), 
		.mux_a1(mux_a1), 
		.mux_a0_next(mux_a0_next), 
		.mux_a1_next(mux_a1_next), 
		.mux_a0_prev(mux_a0_prev), 
		.mux_a1_prev(mux_a1_prev), 
		._ddd_al(_ddd_al), 
		.ddd_mosi(ddd_mosi), 
		.ddd_miso(ddd_miso), 
		.ddd_sclk(ddd_sclk), 
		._reset(_reset), 
		._ft_rxf(_ft_rxf), 
		.clk(clk), 
		._ft_rd(_ft_rd), 
		._ft_wr(_ft_wr), 
		._serial_wr(_serial_wr), 
		._serial_rd(_serial_rd), 
		.ft_byte_out(ft_byte_out), 
		.ft_byte_in(ft_byte_in)
	);

	initial begin
		// Initialize Inputs
		adc_miso = 0;
		pulser_ready = 0;
		halfstrips = 0;
		halfstrips_errcnt = 0;
		compout_errcnt = 0;
		ddd_miso = 1'b0;
		_reset = 1'b1;
		_ft_rxf = 1'b1;
		clk = 1'b1;
		_ft_rd = 1'b1;
		_ft_wr = 1'b1;
		ft_byte_out = 8'b0;
	end

	always 
		#10 clk = ~clk; 
		
	initial begin
		// Wait 100 ns for global reset to finish
		#5     _ft_rd  = 0;
		       _ft_rxf = 0;
		        ft_byte_out = 8'hA0;
		#5      ft_byte_out = 8'hFE;
		#5      ft_byte_out = 8'hED;
		#5      ft_byte_out = 8'hBE;
		#5      ft_byte_out = 8'hEF;
		
        
		// Add stimulus here 
		//always 
		//		#5 clk = !clk; 	
		
	end
      
endmodule

