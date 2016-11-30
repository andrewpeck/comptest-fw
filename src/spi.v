module spi (
  input      mosi,
  output reg miso,
  input      sclk,
  input      cs,

  output reg adr_latched,
  output reg data_latched,

  output reg [ADRSIZE -1:0] adr,
  output reg [DATASIZE-1:0] data_wr,
  input      [DATASIZE-1:0] data_rd
);

parameter ADRSIZE  = 8;
parameter DATASIZE = 32;

parameter REGSIZE  = ADRSIZE + DATASIZE;


reg [REGSIZE-1:0] buffer;

reg [5:0] clk_counter = 0;

wire  adr_latch_pulse = (clk_counter==ADRSIZE-2); // pre-fetch address so data is ready by the falling edge
wire data_latch_pulse = (clk_counter==REGSIZE-2); // pre-fetch address so data is ready by the falling edge

reg wr_start = 0;
wire select= (~cs); // uninvert chip select

wire clk_is_last  = data_latch_pulse;
wire clk_is_first = clk_counter==0;

// spi mode 0: clock in on falling edge,
always @(posedge sclk) begin

  if (select) begin

    // shift in mosi on each clock cycle when cs is active
    buffer [REGSIZE-1:0] <= {buffer [REGSIZE-2:0], mosi};

    clk_counter <= (clk_is_last) ? 1'b0 : clk_counter + 1'b1;

    //--------------------------------------------------------------------------------------------------------------------
    // latch address on the 8th rising edge
    // latch data on the 40th rising edge
    //--------------------------------------------------------------------------------------------------------------------

    if   (clk_is_first) adr_latched  <= 1'b0;
    else                adr_latched  <= (adr_latch_pulse)  ? 1'b1 : adr_latched;

    if   (clk_is_first) data_latched <= 1'b0;
    else                data_latched <= (data_latch_pulse) ? 1'b1 : data_latched;

    adr     <= (adr_latch_pulse)  ? {buffer[ADRSIZE-1 :         1], mosi} : adr; // take the 0th bit directly, bypassing the shift register
    data_wr <= (data_latch_pulse) ? {buffer[REGSIZE-1 : ADRSIZE+1], mosi} : data_wr;

end

end


// spi mode 0: clock out on rising

wire miso_bit = 1'b1 & (data_rd >> (clk_counter - (ADRSIZE-1))); //start shifting out data on the 7th falling edge

always @(negedge sclk) begin
  if (select && adr_latched) begin
    miso <= miso_bit;
  end
end

endmodule
