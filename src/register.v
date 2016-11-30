module register_entry (

  input clock,
  input reset,
  input wr,

  input      [ADRSIZE-1:0] adr,
  output reg [REGSIZE-1:0] data_wr,
  input      [REGSIZE-1:0] bus_wr,
  input      [REGSIZE-1:0] init
);


parameter ADRSIZE = 8;
parameter REGSIZE = 32;
parameter REGADR  = 0;

wire wr_reg = (adr==REGADR && wr);

always @ (posedge clock) begin
  if      (reset)  data_wr <= init;
  else if (wr_reg) data_wr <= bus_wr;
end


endmodule
