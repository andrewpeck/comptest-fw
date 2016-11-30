module register_entry (

  input clock,
  input wr,

  input      [ADRSIZE-1:0] adr,
  output reg [REGSIZE-1:0] data_wr,
  input      [REGSIZE-1:0] bus_wr
);


parameter ADRSIZE = 8;
parameter REGSIZE = 32;
parameter REGADR  = 0;

wire wr_reg = (adr==REGADR && wr);

always @ (posedge clock) begin
  if (wr_reg) data_wr <= bus_wr;
end


endmodule
