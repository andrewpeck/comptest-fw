module spi (
  input      sys_clk,
  input      mosi,
  output     miso,
  input      sclk,
  input      cs,

  output reg adr_latched,
  output reg data_latched,

  output reg [ADRSIZE -1:0] adr,
  output reg [DATASIZE-1:0] data_wr,
  input      [DATASIZE-1:0] data_rd
);


reg [1:0] mosi_ff=0;
reg [1:0] sclk_ff=0;
always @(posedge sys_clk) begin
  mosi_ff[1:0] <= {mosi_ff[0],mosi};
  sclk_ff[1:0] <= {sclk_ff[0],sclk};
end

wire sclk_posedge = !sclk_ff[1] &&  sclk_ff[0];
wire sclk_negedge =  sclk_ff[1] && !sclk_ff[0];

parameter ADRSIZE  = 8;
parameter DATASIZE = 16;

parameter REGSIZE  = ADRSIZE + DATASIZE;

initial data_wr      = 0;
initial adr          = 0;
initial adr_latched  = 0;
initial data_latched = 0;

reg [REGSIZE-1:0] buffer = 0;

reg [5:0] clk_counter = 0;

wire  adr_latch_pulse = (clk_counter==ADRSIZE-1); // pre-fetch address so data is ready by the falling edge
wire data_latch_pulse = (clk_counter==REGSIZE-1); // pre-fetch address so data is ready by the falling edge

reg  wr_start = 0;
wire select   = cs;  // cs is not inverted

// spi mode 0: clock in on falling edge,
always @(posedge sys_clk) begin

  if (select) begin

    if (sclk_posedge) begin

      // shift in mosi on each clock cycle when cs is active
      buffer [REGSIZE-1:0] <= {buffer [REGSIZE-2:0], mosi_ff[1]};

      clk_counter <= clk_counter + 1'b1;

      //--------------------------------------------------------------------------------------------------------------------
      // latch address on the 8th rising edge
      // latch data on the 40th rising edge
      //--------------------------------------------------------------------------------------------------------------------

      adr_latched  <= (adr_latch_pulse)  ? 1'b1 : adr_latched;

      data_latched <= (data_latch_pulse) ? 1'b1 : data_latched;

      adr     <= (adr_latch_pulse)  ? {buffer[ADRSIZE-2 : 0], mosi_ff[1]} : adr; // take the 0th bit directly, bypassing the shift register
      data_wr <= (data_latch_pulse) ? {buffer[REGSIZE-ADRSIZE-2 : 0], mosi_ff[1]} : data_wr;
    end
  end
  else begin
    buffer       <= 0;
    clk_counter  <= 0;
    adr_latched  <= 0;
    data_latched <= 0;
  end
end


// spi mode 0: clock out on rising

wire miso_bit = (data_rd[15-(clk_counter-8)]); //start shifting out data MSB first on the 7th falling edge

reg miso_latch;

always @(posedge sys_clk) begin
  if (sclk_negedge)
  miso_latch <= (adr_latched || adr_latch_pulse) ? miso_bit : 1'b0; // use adr_latched_pulse to accelerate readout
end

assign miso = select ? miso_latch : 1'bZ;  // make sure to tristate..

endmodule
