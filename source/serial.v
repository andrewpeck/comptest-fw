`timescale 1ns / 1ps

module serial
(
    input  [31:0] data_wr,
    output [31:0] data_rd,
    input  [7:0]  adr_in,

    // Pulse Control

    output [3:0] bx_delay,
    output [3:0] pulse_width,
    output       fire_pulse,
    input        pulser_ready,

    output [3:0] triad_persist,
    output       triad_persist1,

    // Halfstrips
    input  [31:0] halfstrips,
    output [31:0] halfstrips_expect,
    input  [31:0] offsets_errcnt,
    output        offsets_errcnt_rst,

    input  [31:0] thresholds_errcnt,
    output        thresholds_errcnt_rst,

    output        compout_expect,
    input         compout_ff,
    input  [31:0] compout_errcnt,
    output        compout_errcnt_rst,
    output        compin_inject,

    // Comparator Config
    output [2:0] pktime,
    output [1:0] pkmode,
    output       lctrst,

    output [31:0] active_strip_mask,


    // Mux Ctrl

    output [3:0]  high_adr;
    output [3:0]   med_adr;
    output [3:0]   low_adr;

    output mux_en,
    output mux_a0_next,
    output mux_a1_next,

    output mux_a0_prev,
    output mux_a1_prev
);


parameter adr_loopback          = 7'd0;
parameter adr_comp_config       = 7'd1;
parameter adr_fire_pulse        = 7'd2;
parameter adr_mux_ctrl          = 7'd3;
parameter adr_pulse_ctrl        = 7'd4;
parameter adr_halfstrips        = 7'd5;
parameter adr_halfstrips_expect = 7'd6;
parameter adr_active_strip_mask = 7'd7;
parameter adr_offsets_errcnt = 7'd8;
parameter adr_compout_errcnt    = 7'd9;
parameter adr_thresholds_errcnt = 7'd10; // last address

parameter MXREG = adr_thresholds_errcnt + 1'b1;

wire      [31:0] data_wr_vec  [MXREG-1:0];
reg       [31:0] data_wr_init [MXREG-1:0];
wire      [31:0] data_rd_vec  [MXREG-1:0];


//----------------------------------------------------------------------------------------------------------------------
// Decompose 8 bit address
//----------------------------------------------------------------------------------------------------------------------

// only write when wr goes high, to keep from writing on read-only transfers

wire [6:0] adr = (adr[6:0]);
wire       wr  = (adr[7:7]);

//----------------------------------------------------------------------------------------------------------------------
// Bus Multiplexer selects between register outputs
//----------------------------------------------------------------------------------------------------------------------

assign data_rd = data_rd_vec [adr];

//----------------------------------------------------------------------------------------------------------------------
// Register generation loop
//----------------------------------------------------------------------------------------------------------------------

genvar ireg;
generate
for (ireg=0; ireg<MXREG; ireg=ireg+1) begin: regloop

  register u_regloop (
    .clk     (clk),
    .regadr  (ireg),              // address of this register
    .adr     (adr),               // serial address
    .data_wr (data_wr_vec[ireg]), // register memory
    .bus_wr  (data_wr),           // data input from SPI
    .wr      (wr)
  );


  //----------------------------------------------------------------------------------------------------------------------
  // adr_loopback
  //----------------------------------------------------------------------------------------------------------------------

  if (ireg==adr_loopback) begin
    assign data_rd_vec[ireg] = data_wr_vec[ireg];
  end

  //----------------------------------------------------------------------------------------------------------------------
  // adr_comp_config
  //----------------------------------------------------------------------------------------------------------------------

  else if (ireg==adr_comp_config) begin

    // Write

    assign  pktime[2:0] = data_wr_vec[ireg][2:0]; 
    assign  pkmode[1:0] = data_wr_vec[ireg][4:3];
    assign  lctrst      = data_wr_vec[ireg][5:5]; 
    initial data_wr_init[ireg][5:5] = 1'd1;

    // Read

    assign data_rd_vec[ireg] = data_wr_vec[ireg];

  end

  //------------------------------------------------------------------------------
  // adr_fire_pulse
  //------------------------------------------------------------------------------

  else if (ireg==adr_fire_pulse) begin

    // Write

    assign  fire_pulse              = data_wr_vec[ireg][0];
    assign  offsets_errcnt_rst   = data_wr_vec[ireg][1];
    assign  compout_errcnt_rst      = data_wr_vec[ireg][2];
    assign  thresholds_errcnt_rst   = data_wr_vec[ireg][3];

    // Read back

    assign data_rd_vec[ireg] = data_wr_vec[ireg];

  end

  //------------------------------------------------------------------------------
  // adr_pulse_ctrl
  //------------------------------------------------------------------------------

  else if (ireg==adr_pulse_ctrl) begin

    // Write

    assign  pulse_width        = data_wr_vec[ireg][4:1];
    assign  compin_inject      = data_wr_vec[ireg][10];
    assign  bx_delay[3:0]      = data_wr_vec[ireg][14:11];
    assign  compout_expect     = data_wr_vec[ireg][15];
    assign  triad_persist[3:0] = data_wr_vec[ireg][19:16];
    assign  triad_persist1     = data_wr_vec[ireg][20];

    // Read

    assign data_rd_vec[ireg][20:0]  = data_wr_vec[ireg][20:0]; // readback
    assign data_rd_vec[ireg][21]    = compout_ff;              // read only
    assign data_rd_vec[ireg][22]    = pulser_ready;            // read only
    assign data_rd_vec[ireg][31:23] = pulse_ctrl_wr[31:23];    // readback

  end

  //------------------------------------------------------------------------------
  // adr_mux_ctrl
  //------------------------------------------------------------------------------

  else if (ireg==adr_mux_ctrl) begin

    // Write

    assign  mux_a0_prev        = data_wr_vec[ireg][0];
    assign  mux_a1_prev        = data_wr_vec[ireg][1];

    assign  mux_a0_next        = data_wr_vec[ireg][2];
    assign  mux_a1_next        = data_wr_vec[ireg][3];

    assign  mux_high_adr [3:0] = data_wr_vec[ireg] [7:4];
    assign  mux_med_adr [3:0]  = data_wr_vec[ireg] [11:8];
    assign  mux_low_adr [3:0]  = data_wr_vec[ireg] [15:12];

    assign  mux_en             = data_wr_vec[ireg] [16:16];

    //Read

    assign data_rd_vec[ireg] = data_wr_vec[ireg];

  end

  //------------------------------------------------------------------------------
  // adr_halfstrips
  //------------------------------------------------------------------------------

  else if (ireg==adr_halfstrips) begin

    // Read only
    assign data_rd_vec [31:0] = halfstrips [31:0]; // WRITE only

  end

  //------------------------------------------------------------------------------
  // adr_halfstrips_expect
  //------------------------------------------------------------------------------
  else if (ireg==adr_halfstrips_expect) begin

    // write
    assign halfstrips_expect     [31:0] = data_wr_vec[ireg] [31:0];

    // read
    assign data_rd_vec[ireg] = data_wr_vec[ireg];

  end
  //------------------------------------------------------------------------------
  // adr_active_strip_mask
  //------------------------------------------------------------------------------

  else if (ireg==adr_active_strip_mask) begin

    // write
    assign active_strip_mask     [31:0] = data_wr_vec[ireg][31:0];

    // read
    assign data_rd_vec[ireg] = data_wr_vec[ireg];

  end

  //------------------------------------------------------------------------------
  // adr_offsets_errcnt
  //------------------------------------------------------------------------------

  else if (ireg==adr_offsets_errcnt) begin

    // write
    assign offsets_errcnt_rd [31:0] = data_wr_vec[ireg][31:0];

    // read
    assign data_rd_vec[adr_offsets_errcnt] = data_wr_vec[adr_offsets_errcnt];

  end

  //------------------------------------------------------------------------------
  // adr_compout_errcnt
  //------------------------------------------------------------------------------

  else if (ireg==adr_compout_errcnt) begin

    // read only
    assign data_rd_vec[ireg] = compout_errcnt[31:0];

  end
  //------------------------------------------------------------------------------
  // adr_thresholds_errcnt
  //------------------------------------------------------------------------------

  else if (ireg==adr_thresholds_errcnt) begin

    // read only
    assign data_rd_vec[ireg] = thresholds_errcnt [31:0];

  end

  //----------------------------------------------------------------------------------------------------------------------
  // fini
  //----------------------------------------------------------------------------------------------------------------------

end
endgenerate

//----------------------------------------------------------------------------------------------------------------------
endmodule
//----------------------------------------------------------------------------------------------------------------------
