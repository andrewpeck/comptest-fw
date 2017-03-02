`timescale 1ns / 1ps

module comparator_injector(

    input      [31:0] halfstrips,
    output reg [31:0] halfstrips_last,

    output reg [15:0] thresholds_errcnt,
    output reg [15:0] offsets_errcnt,
    output reg [15:0] compout_errcnt,

    input compout,
    input compout_expect,
    output reg compout_last,

	  input [4:0] active_halfstrip,
	  input       halfstrip_mask_en,

    input compout_errcnt_rst,
    input offsets_errcnt_rst,
    input thresholds_errcnt_rst,

    input compin_inject,
    output compin,

    input fire_pulse,

    input [11:0] num_pulses,
    output pulser_ready,

    input [3:0] bx_delay,
    input [3:0] pulse_width,

    output pulse_en,

    input clock
);

reg fire_ff=0; 
always @(posedge clock)  begin
fire_ff <= fire_pulse; 
end


reg[7:0] fire_pulse_debounced=0; 
always @(posedge clock) begin
	fire_pulse_debounced <= {fire_pulse_debounced[6:0], fire_ff}; 
end

wire fire = &fire_pulse_debounced; 

assign trigger      = |halfstrips[31:0] || compout;
assign pulser_ready = (pulser_sm==idle);

/* Latch Halfstrips when the Triad is Updated with Non-zero bits*/
always @(posedge clock) begin
    halfstrips_last <= (trigger) ? halfstrips : halfstrips_last;
    compout_last    <= (trigger) ? compout    : compout_last;
end


reg [31:0] halfstrip_expect_mask;    // 32 bit mask of which halfstrip we should see a pulse on

always @(posedge clock) begin
  halfstrip_expect_mask <= (halfstrip_mask_en) << (active_halfstrip);
end

reg [15:0] strip_expect_mask; // 16 bit mask of which strip we should see a pulse on (reduced from halfstrip mask)
wire [15:0] strips; // 16 bit mask of which strip we should see a pulse on (reduced from halfstrip mask)
genvar istrip;
generate
  for (istrip=0; istrip<16; istrip=istrip+1) begin: stripmask_loop
    always @(posedge clock) begin
      strip_expect_mask [istrip] <= |(halfstrip_expect_mask[istrip*2+1:istrip*2]);
    end
      assign strips[istrip] = |(halfstrips[istrip*2+1:istrip*2]);
  end
endgenerate


//----------------------------------------------------------------------------------------------------------------------
// Pulser State Machine
//----------------------------------------------------------------------------------------------------------------------

parameter sm_cnt=4;

reg [sm_cnt-1:0] pulse_width_cnt;
reg [sm_cnt-1:0] timeout_cnt;
reg [sm_cnt-1:0] delay_cnt;
reg [11:0] num_pulsed=0;

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
        idle    : pulser_sm <= (fire)                                         ? pulsing   : idle;
        pulsing : pulser_sm <= (pulse_width_cnt==pulse_width)                 ? delay     : pulsing;
        delay   : pulser_sm <= (bx_delay==delay_cnt)                          ? readout   : delay;
        readout : pulser_sm <= (trigger || timedout)                          ? rearming  : readout;
        rearming: pulser_sm <= (num_pulsed!=num_pulses)                       ? pulsing   : 
			       (fire)                                         ? rearming  : idle; 

    endcase

end

always @ (posedge clock) begin

  if (pulser_sm==idle) begin
    num_pulsed <= 0;
  end
  else if (pulser_sm==pulsing && pulse_width_cnt==0) begin
    // increment when we are pulsing, but only once
    num_pulsed      <= (num_pulsed+1'b1);
  end

  pulse_width_cnt <= (pulser_sm==pulsing) ? (pulse_width_cnt+1'b1) : {sm_cnt{1'b0}};

  timeout_cnt     <= (pulser_sm==readout) ? (timeout_cnt+1'b1)     : {sm_cnt{1'b0}};

  delay_cnt       <= (pulser_sm==delay)   ? (delay_cnt+1'b1)       : {sm_cnt{1'b0}};

end

wire timed_out = (timeout_cnt==TIMEOUT);

assign pulse_en = (pulser_sm==pulsing);
assign compin   = (pulser_sm==pulsing && compin_inject);

wire thresholds_match = (strips == strip_expect_mask); // there is SOME response on the correct strips
wire offsets_match    = (halfstrips==halfstrip_expect_mask);
wire compout_match    = (compout==compout_expect);

reg thresholds_err;
reg offsets_err;
reg compout_err;

always @ (posedge clock) begin

    thresholds_err    <= (trigger && pulser_sm==readout && !thresholds_match) || timed_out; // error if we see strips, but not the right one  || if we see no strips at all
    offsets_err       <= (trigger && pulser_sm==readout && !offsets_match)    || timed_out;
    compout_err       <= (trigger && pulser_sm==readout && !compout_match)    || timed_out;

    thresholds_errcnt <= (thresholds_errcnt_rst) ? 16'd0 : thresholds_errcnt + thresholds_err;
    offsets_errcnt    <= (offsets_errcnt_rst)    ? 16'd0 : offsets_errcnt    +    offsets_err;
    compout_errcnt    <= (compout_errcnt_rst)    ? 16'd0 : compout_errcnt    +    compout_err;

end

//----------------------------------------------------------------------------------------------------------------------
endmodule
//----------------------------------------------------------------------------------------------------------------------
