module register_entry (
  input clk,
  input wr,

  input      [adrsize-1:0] regadr,
  input      [adrsize-1:0] adr,
  output reg [regsize-1:0] data_wr,
  input      [regsize-1:0] bus_wr
);


parameter adrsize = 8;
parameter regsize = 32;

wire wr_reg = (adr==regadr && wr);

always @ (posedge clk) begin
  if (wr_reg) data_wr <= bus_wr;
end


endmodule
