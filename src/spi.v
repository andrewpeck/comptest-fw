module spi (
  input  mosi,
  output miso,
  input  sclk,
  input  cs,

  output  adr_latched,
  output data_latched,

  output [adrsize -1:0] adr,
  output [datasize-1:0] data_out,
  input  [datasize-1:0] data_in
);

parameter adrsize  = 8;
parameter datasize = 32;
parameter regsize  = adrsize + datasize;


reg [regsize-1:0] buffer;

reg [5:0] clk_counter = 0;

wire adr_latch_pulse = (wr_counter==adrsize-2); // pre-fetch address so data is ready by the falling edge
wire adr_latch_pulse = (wr_counter==regsize-2); // pre-fetch address so data is ready by the falling edge

reg wr_start = 0;
wire select= (~cs); // uninvert chip select

wire clk_is_last  = data_latch_pulse;
wire clk_is_first = wr_counter==0;

// spi mode 0: clock in on falling edge,
always @(posedge sclk) begin

  if (select) begin

    // shift in mosi on each clock cycle when cs is active
    buffer [regsize-1:0] <= {buffer [regsize-2:0], mosi};

    clk_counter <= (clk_is_last) ? 1'b0 : clk_counter + 1'b1;

    //--------------------------------------------------------------------------------------------------------------------
    // latch address on the 8th rising edge
    // latch data on the 40th rising edge
    //--------------------------------------------------------------------------------------------------------------------

    if   (clk_is_first) adr_latched  <= 1'b0;
    else                adr_latched  <= (adr_latch_pulse)  ? 1'b1 : adr_latched;

    if   (clk_is_first) data_latched <= 1'b0;
    else                data_latched <= (data_latch_pulse) ? 1'b1 : data_latched;

    adr     <= (adr_latch_pulse)  ? {buffer[adrsize-2:0], mosi} : adr;
    data_in <= (data_latch_pulse) ? {buffer[regsize-2:0], mosi} : data_in;

end

end


// spi mode 0: clock out on rising
always @(negedge sclk) begin
  if (select && adr_latched) begin
    miso <= data_in >> (clk_counter - (adrsize-1)); //start shifting out data on the 7th falling edge
  end
end

endmodule
