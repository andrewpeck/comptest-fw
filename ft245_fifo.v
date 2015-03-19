`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:55:33 12/04/2014 
// Design Name: 
// Module Name:    ft245_fifo 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module ft245_fifo(
input CLK_40, 
input CLK_60 
);

fifo_dualclock ft245_write (
  .rst(rst),       // input rst
  .wr_clk(wr_clk), // input wr_clk
  .rd_clk(rd_clk), // input rd_clk
  .din(din),       // input [7 : 0] din
  .wr_en(wr_en),   // input wr_en
  .rd_en(rd_en),   // input rd_en
  .dout(dout),     // output [7 : 0] dout
  .full(full),     // output full
  .empty(empty)    // output empty
);

fifo_dualclock ft245_read (
  .rst(rst), // input rst
  .wr_clk(wr_clk), // input wr_clk
  .rd_clk(rd_clk), // input rd_clk
  .din(din), // input [7 : 0] din
  .wr_en(wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout), // output [7 : 0] dout
  .full(full), // output full
  .empty(empty) // output empty
);

endmodule
