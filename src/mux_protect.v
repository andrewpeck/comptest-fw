module mux_protect (
  input clock,

  input  [3:0] high_adr_in,
  input  [3:0] med_adr_in,
  input  [3:0] low_adr_in,

  input mux_en_in,

  output mux_en_out

);


// we want to prevent mux address conflicts to keep from sending two pulses to the same channel

wire short_high_med = (high_adr_in==med_adr_in);
wire short_high_low = (high_adr_in==low_adr_in);
wire short_med_low  = ( med_adr_in==low_adr_in);

wire short = short_high_med || short_high_low || short_med_low;

assign mux_en_out = mux_en_in && !short;

endmodule
