`timescale 1ns / 1ps
//`define DEBUG_CYLON2 1
//--------------------------------------------------------------------------------------------------------
//
//  Cylon sequence generator, two-eye
//
//  10/01/2003  Initial
//  09/28/2006  Mod xst remove output ff, inferred ROM is already registered
//  10/10/2006  Replace init ff with srl
//  05/16/2007  Port from cylon9, add rate
//  08/11/2009  Replace 10MHz clock_vme with  40MHz clock, increase prescale counter by 2 bits
//  04/22/2010  Port to ISE 11, add FF to srl output to sync with gsr
//  07/09/2010  Port to ISE 12
//--------------------------------------------------------------------------------------------------------
  module cylon2 (clock,rate,q);

// Ports
  input       clock;
  input  [1:0]  rate;
  output  [11:0]  q;

// Initialization
  wire [3:0] pdly  = 0;
  reg        ready = 0;
  wire       idly;

  SRL16E uinit (.CLK(clock),.CE(!idly),.D(1'b1),.A0(pdly[0]),.A1(pdly[1]),.A2(pdly[2]),.A3(pdly[3]),.Q(idly));

  always @(posedge clock) begin
  ready <= idly;
  end

// Scale clock down below visual fusion
  `ifndef DEBUG_CYLON2
  parameter MXPRE = 21;  `else
  parameter MXPRE = 6;
  `endif

  reg   [MXPRE-1:0] prescaler  = 0;
  wire [MXPRE-1:0] full_scale = {MXPRE{1'b1}};

  always @(posedge clock) begin
  if (ready)
  prescaler <= prescaler + rate + 1'b1;
  end
 
  wire next_adr = (prescaler==full_scale);

// ROM address pointer runs 0 to 6
  reg  [3:0] adr = 0;

  wire last_adr = (adr==9);
  
  always @(posedge clock) begin
  if (next_adr) begin
  if (last_adr) adr <= 0;
  else          adr <= adr + 1'b1;
  end
  end

// Display pattern ROM
  reg  [11:0] rom;

  always @(adr) begin
  case (adr)
  4'd0:  rom  <=  12'b010000000010;
  4'd1:  rom  <=  12'b001000000100;
  4'd2:  rom  <=  12'b000100001000;
  4'd3:  rom  <=  12'b000010010000;
  4'd4:  rom  <=  12'b000001100000;
  4'd5:  rom  <=  12'b000010010000;
  4'd6:  rom  <=  12'b000100001000;
  4'd7:  rom  <=  12'b001000000100;
  4'd8:  rom  <=  12'b010000000010;
  4'd9:  rom  <=  12'b100000000001;
  endcase
  end

  assign q = rom;

  endmodule
