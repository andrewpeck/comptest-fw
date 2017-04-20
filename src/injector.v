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
    output reg compin,

    input fire_pulse,

    input [11:0] num_pulses,
    output pulser_ready,

    input [7:0] bx_delay,
    input [3:0] pulse_width,
	 
	 input [15:0] restore_cnt,
	 
	 output reg [7:0] peak_time,  

    output reg pulse_en,

    input clock
);

reg double_pulse = 0; 

reg fire_ff=0; 
always @(posedge clock)  begin
fire_ff <= fire_pulse; 
end


reg[7:0] fire_pulse_debounced=0; 
always @(posedge clock) begin
	fire_pulse_debounced <= {fire_pulse_debounced[6:0], fire_ff}; 
end

wire fire = &fire_pulse_debounced; 


assign pulser_ready = (pulser_sm==idle);

reg compout_went_high=0; 
always @(posedge clock) begin
	
	if (pulser_sm==idle)
		compout_went_high <= 1'b0; 
	
	else if (pulser_sm==readout && compout)
		compout_went_high <= 1'b1; 

end

/* Latch Halfstrips when the Triad is Updated with Non-zero bits*/
// (1) first condition covers the case that we want to readout the last halfstrips in the case that the chip doesn't trigger
// (2) second condition covers the case that the chip triggers (for just 1bx) so this latches only the hs that generated the trigger + (possibly) triad extended prior hits 
always @(posedge clock) begin
    halfstrips_last <= ((pulser_sm==readout && |halfstrips) || trigger) ? halfstrips : halfstrips_last;
    compout_last    <= ((pulser_sm==readout && |halfstrips) || trigger) ? compout_went_high   : compout_last;
end


reg [31:0] halfstrip_expect_mask;    // 32 bit mask of which halfstrip we should see a pulse on

always @(posedge clock) begin
  halfstrip_expect_mask <= (halfstrip_mask_en) << (active_halfstrip);
end

//reg [15:0] strip_expect_mask; // 16 bit mask of which strip we should see a pulse on (reduced from halfstrip mask)
wire [15:0] strips; // 16 bit mask of which strip we should see a pulse on (reduced from halfstrip mask)
genvar istrip;
generate
  for (istrip=0; istrip<16; istrip=istrip+1) begin: stripmask_loop
//always @(posedge clock) begin
//   strip_expect_mask [istrip] <= |(halfstrip_expect_mask[istrip*2+1:istrip*2]);
//  end
//   
	 assign strips[istrip] = |(halfstrips[istrip*2+1:istrip*2]);
  end
endgenerate

reg [15:0] strips_ff; 
reg [31:0] halfstrips_ff; 
always @(posedge clock) begin
strips_ff <= strips; 
halfstrips_ff <= halfstrips; 
end


wire [15:0] trigger_mask;  // this is a hack due to the fact that we can't turn off individual pulse muxers
//assign trigger_mask [0] = (active_halfstrip!=31 && active_halfstrip!=30);  // don't look at 0 when we are pulsing 15
//assign trigger_mask [15] = (active_halfstrip!=0 && active_halfstrip!=1); // don't look at 15 when we are pusling 0
//assign trigger_mask [14:1] = (-1);  // these are always OK

assign trigger_mask = 1'b1<<(active_halfstrip>>1'b1);   // trigger on either hit on this STRIP (either halfstrip)

assign trigger = (pulser_sm==readout) &&  (|( trigger_mask & strips));

reg trigger_ff; 
always @ (posedge clock)
trigger_ff <= trigger;

//----------------------------------------------------------------------------------------------------------------------
// Pulser State Machine
//----------------------------------------------------------------------------------------------------------------------

parameter sm_cnt=4;

reg [7:0] timeout_cnt;

reg [3:0] pulse_width_cnt=0;
reg [15:0] baseline_restore_cnt=0;
reg [7:0] delay_cnt=0;
reg [11:0] num_pulsed=0;

reg [2:0] pulser_sm = 3'h0;

parameter [7:0] TIMEOUT = 191;

parameter [2:0] idle      = 3'd0;
parameter [2:0] pulsing   = 3'd1;
parameter [2:0] delay     = 3'd2;
parameter [2:0] readout   = 3'd3;
parameter [2:0] rearming  = 3'd4;
parameter [2:0] restore   = 3'd5;

wire timed_out = (timeout_cnt==TIMEOUT);

always @(posedge clock)
begin

    case (pulser_sm)
	 
			// idle, waiting for signal
        idle    : pulser_sm <= (fire)                                         ? pulsing   : idle;

			// pulsing, turn on pulse for n-clocks
        pulsing : pulser_sm <= (pulse_width_cnt==pulse_width)                 ? delay     : pulsing;

			// delay, wait for n-clocks before checking data
        delay   : pulser_sm <= (bx_delay[3:0]==delay_cnt)                     ? readout   : delay;

			// readout, wait for trigger or timeout
        readout : begin
							
							 if (timed_out || trigger) 		      	pulser_sm <= restore; 
							 else 	             							pulser_sm <= readout; 
							 
							 if (trigger) 								peak_time <= timeout_cnt; 
							 else 								peak_time <= (-1);  
								
			end
			
    		// restore, wait for baseline to restore
			restore : begin
			
			if (baseline_restore_cnt==restore_cnt)
				pulser_sm <= rearming; 
				
			end
	
		   // rearming for next pulse
			rearming: begin
		  
				if 	  (num_pulsed!=num_pulses) 	pulser_sm <= pulsing; 
				else if (fire) 							pulser_sm <= rearming; // hold in rearming state until fire is deasserted
				else 		                       		pulser_sm <= idle; 
				
		  end
		  
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


	pulse_width_cnt <= (pulser_sm==pulsing) ? (pulse_width_cnt+1'b1) : 0;
  
	if (pulser_sm==restore)
		baseline_restore_cnt <= baseline_restore_cnt + 1'b1;
	else 
		baseline_restore_cnt <= 1'b0; 
	
	
  timeout_cnt     <= (pulser_sm==readout) ? (timeout_cnt+1'b1)     : 0;

  delay_cnt       <= (pulser_sm==delay)   ? (delay_cnt+1'b1)       : 0;

end

always @(posedge clock) begin
pulse_en <= (pulser_sm==pulsing || (pulser_sm==readout && timeout_cnt<=pulse_width && double_pulse==1));
compin   <= (pulser_sm==readout && compin_inject);
end

wire [3:0] active_strip = (active_halfstrip>>1'b1);

wire thresholds_match = 1'b1 & (strips_ff     >> active_strip); // there is a  response on the correct strip (ignore halfstrip)
wire offsets_match    = 1'b1 & (halfstrips_ff >> active_halfstrip); // there is a response on the correct halfstrip

wire compout_match    = (compout_went_high==compout_expect);

reg thresholds_err;
reg offsets_err;
reg compout_err;

always @ (posedge clock) begin

    thresholds_err    <= (trigger_ff && !thresholds_match) || timed_out; // error if we see strips, but not the right one  || if we see no strips at all
    offsets_err       <= (trigger_ff && !offsets_match)    || timed_out;

//    thresholds_err    <= (trigger && pulser_sm==readout && !thresholds_match) || timed_out; // error if we see strips, but not the right one  || if we see no strips at all
//    offsets_err       <= (trigger && pulser_sm==readout && !offsets_match);
    
	 compout_err       <= ((timed_out || trigger_ff)) && !compout_match;

    thresholds_errcnt <= (thresholds_errcnt_rst) ? 16'd0 : thresholds_errcnt + thresholds_err;
    offsets_errcnt    <= (offsets_errcnt_rst)    ? 16'd0 : offsets_errcnt    +    offsets_err;
    compout_errcnt    <= (compout_errcnt_rst)    ? 16'd0 : compout_errcnt    +    compout_err;

end

//----------------------------------------------------------------------------------------------------------------------
endmodule
//----------------------------------------------------------------------------------------------------------------------
