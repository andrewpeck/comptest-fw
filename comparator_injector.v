`timescale 1ns / 1ps

module comparator_injector(
    input      [31:0] halfstrips,
    input      [31:0] halfstrips_expect,
    output reg [31:0] halfstrips_ff,

    output reg [31:0] thresholds_errcnt,
    output reg [31:0] halfstrips_errcnt,
    output reg [31:0] compout_errcnt,

    input compout,
    input compout_expect,

	  input [31:0] active_strip_mask,

    input compout_errcnt_rst,
    input halfstrips_errcnt_rst,
    input thresholds_errcnt_rst,

    input compin_inject,
    output reg compin,

    input fire_pulse,
    output pulser_ready,

    input [3:0] bx_delay,
    input [3:0] pulse_width,

    input [7:0] distrip,

    output pulse_en,

    input clk
);

assign trigger      = | halfstrips[31:0];
assign pulser_ready = (pulser_sm==idle);

/* Latch Halfstrips when the Triad is Updated */
always @(posedge clk) begin
    halfstrips_ff <= (trigger) ? halfstrips : halfstrips_ff;
end

//----------------------------------------------------------------------------------------------------------------------
// Pulser State Machine
//----------------------------------------------------------------------------------------------------------------------

reg       [2:0] pulser_sm = 3'h0;

parameter [2:0] idle      = 3'h0;
parameter [2:0] pulsing   = 3'h1;
parameter [2:0] delay     = 3'h2;
parameter [2:0] readout   = 3'h3;
parameter [2:0] rearming  = 3'h4;

always @(posedge clk)
begin
    case (pulser_sm)
        idle    : pulser_sm <= (fire_pulse)                   ? pulsing  : idle;
        pulsing : pulser_sm <= (pulse_width_cnt==pulse_width) ? delay    : pulsing;
        delay   : pulser_sm <= (bx_delay==dly_cnt)            ? readout  : delay;
        readout : pulser_sm <= (trigger || timedout)          ? rearming : readout;
        rearming: pulser_sm <= (!fire_pulse)                  ? idle     : rearming;
    endcase

end

reg [3:0] pulse_width_cnt;
always @ (posedge clock) begin
    pulse_width_cnt <= (pulser_sm=pulsing) ? (pulse_width_cnt+1) : 0;
end

reg [3:0] timeout_cnt;
always @ (posedge clock) begin
    timeout_cnt <= (pulser_sm=readout) ? (timeout_cnt+1) : 0;
end

parameter TIMEOUT = 16'd20;
wire timed_out = (timeout_cnt==TIMEOUT);

reg [3:0] dly_cnt;
always @ (posedge clock) begin
    dly_cnt <= (pulser_sm=delay) ? (delay_cnt+1) : 0;
end

assign pulse_en = (pulser_sm==pulsing);
assign compin   = (pulser_sm==pulsing && compin_inject);

always @ (posedge clk) begin
    thresholds_errcnt <= ((halfstrips &  active_strip_mask)==32'b0) ? thresholds_errcnt : thresholds_errcnt+1;
    halfstrips_errcnt <= ((halfstrips != halfstrips_expect)==32'b0) ? halfstrips_errcnt : thresholds_errcnt+1;
    halfstrips_errcnt <= ((halfstrips != halfstrips_expect)==32'b0) ? compout_errcnt    : thresholds_errcnt+1;

    if (halfstrips_errcnt_rst) halfstrips_errcnt <= 32'b0;
    if (compout_errcnt_rst)    compout_errcnt    <= 32'b0;
    if (thresholds_errcnt_rst) thresholds_errcnt <= 32'b0;
end

//----------------------------------------------------------------------------------------------------------------------
endmodule
//----------------------------------------------------------------------------------------------------------------------
