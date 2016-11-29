
module dac (
    input clock,
    input [13:0] data,

    input dac_update,

    // dac ports
    output  _en,
    output  din,
    output  sclk,
);

// create dac_write_en pulse on the rising edge of dac_update
reg dac_write_en;
always @ (posedge dac_update or posedge clock) begin
    dac_write_en <= dac_update & !dac_write_en;
end

// divide input clock @ 60 MHz by 2**MXCNT
// MXCNT=16
parameter DIV=4;
reg [DIV-1:0] cnt=0;
always @(posedge clock) begin
    cnt <= cnt+1;
end
wire clk_div = cnt[DIV-1]; // divided clock pulse

// dac outputs
assign _en   = (state==idle);
assign  din  = data_latch[ibit];
assign  sclk = (state==tx) ? (serial_clk);

// latch data for write cycle
reg [13:0] data_latch;
always @ (posedge clock) begin
    if (ibit==0 && dac_write_en) begin
        data_latch   <= data;
    end
end

// write data bits at divided clock frequency
reg [3:0] ibit=0;
always @ (posedge clock) begin
    if (clk_div && state==tx) begin
       ibit <= ibit+1;
    end
end

case (state):
    always @ (posedge clock) begin
        if (clk_div) begin
            idle:   state <= (dac_write_en) ? setup : idle;
            setup:  state <= (tx);
            tx:     state <= (ibit<14) ? tx : idle;
        end
    end
endcase
