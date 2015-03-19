`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:02:41 03/03/2015 
// Design Name: 
// Module Name:    comparator_injector 
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
///////////////////////////////////////////////////////////////////////////////

module comparator_injector(
    input [31:0] halfstrips, 
    input [31:0] halfstrips_expect, 

    output reg [31:0] halfstrips_errcnt,
    output reg [31:0] compout_errcnt,

    input compout, 
    input compout_expect, 

    input compout_errcnt_rst, 
    input halfstrips_errcnt_rst, 

    input compin_inject, 
    output reg compin, 

    input fire_pulse, 
    output reg pulser_ready, 

    input [2:0] bx_delay, 
    input [3:0] pulse_width,

    output reg pulse_en,

    input clock40	
);

reg [3:0] bx; 
initial 
begin
    bx = 0;
end

always @ (posedge clock40)
begin

    if (halfstrips_errcnt_rst)
    begin
        halfstrips_errcnt = 0; 
    end

    if (compout_errcnt_rst)
    begin
        compout_errcnt = 0; 
    end

    // turn on digipulse at first bx
    if (fire_pulse && bx==0 && pulser_ready)
    begin
        pulse_en     = 1;
        pulser_ready = 0; 
    end

    //  turn off digipulse after pulse_width bxs
    if (bx==pulse_width)
    begin
        pulse_en   = 0; 
    end

    // wait until some later point in time
    // (value depends on shaping circuit)
    // should be determined empirically...
    if (bx < bx_delay)
    begin
        bx <= (bx+1);
    end 
    else if (bx == bx_delay)
    begin
        // Pulse Injector Error Counter
        if (halfstrips!=halfstrips_expect)
            halfstrips_errcnt = halfstrips_errcnt + 1; 

        if (compout!=compout_expect)
            compout_errcnt = compout_errcnt + 1; 

        bx <= 0;
        pulser_ready = 1;
    end	 
end
endmodule
