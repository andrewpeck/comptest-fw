
module dac (
    input clock,
    input [13:0] data,

    input dac_update,

    // dac ports
    output  _en,
    output  din,
    output  sclk,
);

// update dac only on rising edge of dac_update
reg [1:0] dac_update_ff;
always @ (posedge clock)
    dac_update_ff <= {dac_update_ff[0], dac_update)};
wire dac_write_en = (dac_update_ff==2'b10);

// divide input clock @ 40 MHz by 2**MXCNT
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
assign din=(data_latch[0]);
always @ (posedge clock) begin
    if (ibit==0 && dac_update) begin
        data_latch   <= data;
    end
end

// write data bits at divided clock cycle
reg [3:0] ibit=0;
always @ (posedge clock) begin
    if (clk_div && state==tx) begin
       ibit <= (ibit<12) ? ibit+1 : 4'b0;
    end
end

case (state):
    always @ (posedge clock) begin
        if (clk_div) begin
            idle:   state <= (dac_update) ? setup : idle;
            setup:  state <= (tx);
            tx:     state <= (ibit<14) ? tx : idle;
        end
    end
endcase
