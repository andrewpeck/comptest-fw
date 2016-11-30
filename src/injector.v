`timescale 1ns / 1ps

module comparator_injector(
    input      [31:0] halfstrips,
    input      [31:0] halfstrips_expect,
    output reg [31:0] halfstrips_last,

    output reg [31:0] thresholds_errcnt,
    output reg [31:0] offsets_errcnt,
    output reg [31:0] compout_errcnt,

    input compout,
    input compout_expect,
    output reg compout_last,

	  input [31:0] active_strip_mask,

    input compout_errcnt_rst,
    input offsets_errcnt_rst,
    input thresholds_errcnt_rst,

    input compin_inject,
    output compin,

    input fire_pulse,
    output pulser_ready,

    input [3:0] bx_delay,
    input [3:0] pulse_width,

    output pulse_en,

    input clock
);

assign trigger      = |halfstrips[31:0];
assign pulser_ready = (pulser_sm==idle);

/* Latch Halfstrips when the Triad is Updated with Non-zero bits*/
always @(posedge clock) begin
    halfstrips_last <= (trigger) ? halfstrips : halfstrips_last;
    compout_last    <= (trigger) ? compout : compout_last;
end

//----------------------------------------------------------------------------------------------------------------------
// Pulser State Machine
//----------------------------------------------------------------------------------------------------------------------

parameter sm_cnt=4;

reg [sm_cnt-1:0] pulse_width_cnt;
reg [sm_cnt-1:0] timeout_cnt;
reg [sm_cnt-1:0] delay_cnt;

reg [2:0] pulser_sm = 3'h0;

parameter TIMEOUT = 16'd20;

parameter [2:0] idle      = 3'h0;
parameter [2:0] pulsing   = 3'h1;
parameter [2:0] delay     = 3'h2;
parameter [2:0] readout   = 3'h3;
parameter [2:0] rearming  = 3'h4;
parameter [2:0] timedout  = 3'h5;

always @(posedge clock)
begin
    case (pulser_sm)
        idle    : pulser_sm <= (fire_pulse)                   ? pulsing  : idle;
        pulsing : pulser_sm <= (pulse_width_cnt==pulse_width) ? delay    : pulsing;
        delay   : pulser_sm <= (bx_delay==delay_cnt)          ? readout  : delay;
        readout : pulser_sm <= (trigger || timedout)          ? rearming : readout;
        rearming: pulser_sm <= (!fire_pulse)                  ? idle     : rearming;
    endcase

end

always @ (posedge clock) begin
    pulse_width_cnt <= (pulser_sm==pulsing) ? (pulse_width_cnt+1'b1) : {sm_cnt{1'b0}};
    timeout_cnt     <= (pulser_sm==readout) ? (timeout_cnt+1'b1)     : {sm_cnt{1'b0}};
    delay_cnt       <= (pulser_sm==delay)   ? (delay_cnt+1'b1)       : {sm_cnt{1'b0}};
end

wire timed_out = (timeout_cnt==TIMEOUT);

assign pulse_en = (pulser_sm==pulsing);
assign compin   = (pulser_sm==pulsing && compin_inject);

wire thresholds_match = |(halfstrips & active_strip_mask); // there is SOME response on the correct strips
wire offsets_match    = (halfstrips==halfstrips_expect);
wire compout_match    = (compout==compout_expect);

reg thresholds_err;
reg offsets_err;
reg compout_err;

always @ (posedge clock) begin

    thresholds_err    <= (trigger && pulser_sm==readout && !thresholds_match) || timed_out;
    offsets_err       <= (trigger && pulser_sm==readout && !offsets_match)    || timed_out;
    compout_err       <= (trigger && pulser_sm==readout && !compout_match)    || timed_out;

    thresholds_errcnt <= (thresholds_errcnt_rst) ? 0 : thresholds_errcnt + thresholds_err;
    offsets_errcnt    <= (offsets_errcnt_rst)    ? 0 : offsets_errcnt    +    offsets_err;
    compout_errcnt    <= (compout_errcnt_rst)    ? 0 : compout_errcnt    +    compout_err;

end

//----------------------------------------------------------------------------------------------------------------------
endmodule
//----------------------------------------------------------------------------------------------------------------------
