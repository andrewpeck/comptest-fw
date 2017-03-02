module led_ctrl (
  input         dcms_locked,
  input         reset,
  input         clock,
  input  [31:0] halfstrips,
  output reg [11:0] leds
);

reg idle=1;

always @(posedge clock) begin
  if (reset)
    idle <= 1'b1;
  else if (|halfstrips)
    idle <= 1'b0;
end

wire [7:0] cylonone;
wire [7:0] cylontwo;

cylon1 ucylon1 (clock, 2'd0, cylonone);
cylon2 ucylon2 (clock, 2'd0, cylontwo);

reg [7:0] distrips;
reg [3:0] side;

wire [7:0] distrip_flash;
wire [3:0] side_flash;

always @(posedge clock) begin
  if (!dcms_locked) begin
    leds[7:0]  <= cylontwo;
    leds[11:8] <= 4'h0;
  end
  else if (pulser_ready) begin
    leds[7:0]  <= cylonone;
    leds[11:8] <= 4'd0;
  end
  else begin
    leds[7:0]  <= distrip_flash[7:0];
    leds[11:8] <= side_flash[3:0];
  end
end

always @(posedge clock) begin
  side[0] <= halfstrips[0] | halfstrips[4] | halfstrips[8]  | halfstrips [12] | halfstrips [16] | halfstrips [20] | halfstrips [24] | halfstrips [28];
  side[1] <= halfstrips[1] | halfstrips[5] | halfstrips[9]  | halfstrips [13] | halfstrips [17] | halfstrips [21] | halfstrips [25] | halfstrips [29];
  side[2] <= halfstrips[2] | halfstrips[6] | halfstrips[10] | halfstrips [14] | halfstrips [18] | halfstrips [22] | halfstrips [26] | halfstrips [30];
  side[3] <= halfstrips[3] | halfstrips[7] | halfstrips[11] | halfstrips [15] | halfstrips [19] | halfstrips [23] | halfstrips [27] | halfstrips [31];

  distrips [0] <= |(halfstrips[3:0]);
  distrips [1] <= |(halfstrips[7:4]);
  distrips [2] <= |(halfstrips[11:8]);
  distrips [3] <= |(halfstrips[15:12]);
  distrips [4] <= |(halfstrips[19:16]);
  distrips [5] <= |(halfstrips[23:20]);
  distrips [6] <= |(halfstrips[27:24]);
  distrips [7] <= |(halfstrips[31:28]);
end

x_flashsm uflash0 (distrips[0],1'b0,clock,distrip_flash[0]);
x_flashsm uflash1 (distrips[1],1'b0,clock,distrip_flash[1]);
x_flashsm uflash2 (distrips[2],1'b0,clock,distrip_flash[2]);
x_flashsm uflash3 (distrips[3],1'b0,clock,distrip_flash[3]);
x_flashsm uflash4 (distrips[4],1'b0,clock,distrip_flash[4]);
x_flashsm uflash5 (distrips[5],1'b0,clock,distrip_flash[5]);
x_flashsm uflash6 (distrips[6],1'b0,clock,distrip_flash[6]);
x_flashsm uflash7 (distrips[7],1'b0,clock,distrip_flash[7]);

x_flashsm uflash8  (side[0],1'b0,clock,side_flash[0]);
x_flashsm uflash9  (side[1],1'b0,clock,side_flash[1]);
x_flashsm uflash10 (side[2],1'b0,clock,side_flash[2]);
x_flashsm uflash11 (side[3],1'b0,clock,side_flash[3]);

endmodule
