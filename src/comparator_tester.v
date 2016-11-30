`timescale 1ns / 1ps

module comptest (
    // Data Delay Chip
    input  mosi,
    output miso,
    input  sclk,
    input  cs,

    input [5:0] samd_io,

    output samd_clk,

    // Pulse Multiplexer Control

    output  mux_en, // global mux en

    output [3:0] adr_high,
    output [3:0] adr_med,
    output [3:0] adr_low,

    output [1:0] adr_next,
    output [1:0] adr_prev,

    input push_button,

    // Comparator Logic

    input   [7:0] distrip,

    input   compout,

    output  compin,
    output  lctrst,
    output  lctclk,
    output  [2:0] pktime,
    output  [1:0] pkmode,

    output pulse_en,

    // Leds

    output [11:0] led,

    input osc40
);

assign samd_clk = 1'bZ;

// hold reset low at startup
SRL16E #(.INIT(16'hFFFF)) upowerup (.CLK(clk40),.CE(1'b1),.D(1'b0),.A0(1'b1),.A1(1'b1),.A2(1'b1),.A3(1'b1),.Q(reset));

/*
 * Inter-module connections
 */

wire [31:0] halfstrips;
wire [31:0] halfstrips_expect;

wire [31:0] offsets_errcnt;
wire [31:0] compout_errcnt;
wire [31:0] thresholds_errcnt;

wire compout_expect;
wire compout_last  ;
wire compout_errcnt_rst;
wire offsets_errcnt_rst;
wire compin_inject;

wire pulser_ready;

wire [3:0] bx_delay;
wire [3:0] pulse_width;

wire fire_pulse;

wire [31:0] active_strip_mask;
wire [31:0] halfstrips_last;

wire triad_perist1;
wire [3:0] triad_persist;
wire [13:0] pdac_data;
wire [13:0] cdac_data;

wire dcm_rst=0;
wire dcm_islocked;

wire [7:0] tskip;   // Skipped triads
wire triad_skip = (|tskip[0]) | (|tskip[1]) | (|tskip[2]) | (|tskip[3]) | (|tskip[4]) | (|tskip[5]);

wire lctclk_en = 1'b1;

//------------------------------------------------------------------------------
// 40 MHz Clock Generation
//------------------------------------------------------------------------------


wire psen = 0;
wire psincdec = 0;
wire psdone;
wire lock0, lock1;
wire dcms_locked = lock0 & lock1;


//------------------------------------
// IBUFG clkin1_buf (.O (osc40_bufg), .I (osc40));

dcm u_dcm0 (
  // Clock in ports
    .CLK_IN1 (osc40), // IN

  // Clock out ports
    .CLK_OUT1 (clk40), // OUT

  // Dynamic phase shift ports
    .PSCLK    (1'b0), // IN
    .PSEN     (1'b0), // IN
    .PSINCDEC (1'b0), // IN
    .PSDONE   (),     // OUT

  // Status and control signals
    .RESET    (reset),  // IN
    .LOCKED   (lock0)   // OUT
);

dcm u_dcm1 (
  // Clock in ports
    .CLK_IN1 (clk40), // IN

  // Clock out ports
    .CLK_OUT1 (clk_comp), // OUT

  // Dynamic phase shift ports
    .PSCLK    (clk40),    // IN
    .PSEN     (psen),     // IN
    .PSINCDEC (psincdec), // IN
    .PSDONE   (psdone),   // OUT

  // Status and control signals
    .RESET    (reset), // IN
    .LOCKED   (lock1)  // OUT
);

IBUFG sclk_ibufg (.O (sclk_buf), .I (sclk));


//----------------------------------------------------------------------------------------------------------------------
// forward 40mhz clock to the lct comparator
//----------------------------------------------------------------------------------------------------------------------


ODDR2 #(
    .DDR_ALIGNMENT("NONE"), // Sets output alignment to "NONE", "C0" or "C1"
    .INIT(1'b0),            // Sets initial state of the Q output to 1'b0 or 1'b1
    .SRTYPE("SYNC")         // Specifies "SYNC" or "ASYNC" set/reset
    ) clock_forward_inst (
        .Q  (lctclk),    // 1-bit DDR output data
        .C0 ( clk_comp), // 1-bit clock input
        .C1 (~clk_comp), // 1-bit clock input
        .CE (lctclk_en), // 1-bit clock enable input
        .D0 (1'b0),      // 1-bit data input (associated with C0)
        .D1 (1'b1),      // 1-bit data input (associated with C1)
        .R  (1'b0),      // 1-bit reset input
        .S  ()           // 1-bit set input
    );


//----------------------------------------------------------------------------------------------------------------------
// Comparator Injector
//----------------------------------------------------------------------------------------------------------------------

comparator_injector u_comparator_injector (
    .compin                (compin                   ), // Out to comparator 
    .compout               (compout                  ), // In  from comparator

    .halfstrips            (halfstrips       [31:0]  ), // In  from triad decoder
    .halfstrips_last       (halfstrips_last  [31:0]  ), // Out Latched copy of last non-zero triads
    .halfstrips_expect     (halfstrips_expect[31:0]  ), // In  software-set expected halfstrip pattern
    .offsets_errcnt        (offsets_errcnt[31:0]     ), // Out
    .thresholds_errcnt     (thresholds_errcnt[31:0]  ),
    .compout_errcnt        (compout_errcnt           ),
    .compout_expect        (compout_expect           ),
    .compout_last            (compout_last               ),
    .active_strip_mask     (active_strip_mask[31:0]  ),
    .compout_errcnt_rst    (compout_errcnt_rst       ),
    .offsets_errcnt_rst    (offsets_errcnt_rst       ),
    .thresholds_errcnt_rst (thresholds_errcnt_rst    ),
    .compin_inject         (compin_inject            ),
    .fire_pulse            (fire_pulse               ), // In  inject pulse
    .pulser_ready          (pulser_ready             ), // Out pulser is idle
    .bx_delay              (bx_delay[3:0]            ), // In  delay after pulsing before reading out half-strips
    .pulse_width           (pulse_width[3:0]         ), // In  width of digital pulse (in bx)
    .pulse_en              (pulse_en                 ), // Out turn on pulse
    .clock                 (clk40                    )
);

//----------------------------------------------------------------------------------------------------------------------
//
//----------------------------------------------------------------------------------------------------------------------

parameter ADRSIZE  = 8;
parameter DATASIZE = 32;

wire [ADRSIZE-1:0] adr;
wire [DATASIZE-1:0] data_wr;
wire [DATASIZE-1:0] data_rd;

spi #( .ADRSIZE  (ADRSIZE), .DATASIZE (DATASIZE)) uspi (
  .mosi         (mosi),
  .miso         (miso),
  .sclk         (sclk_buf),
  .cs           (cs),
  .adr_latched  (),
  .data_latched (),
  .adr          (adr),
  .data_wr      (data_wr),
  .data_rd      (data_rd)

);

// SPI Serial Interface
serial u_serial            (

    .clock (clk40),

    .reset (reset),

    .data_wr (data_wr),
    .data_rd (data_rd),
    .adr_in  (adr),

    .bx_delay              (bx_delay[3:0]),
    .pulse_width           (pulse_width[3:0]),
    .fire_pulse            (fire_pulse),
    .pulser_ready          (pulser_ready),
    .triad_persist         (triad_persist[3:0]),
    .triad_persist1        (triad_persist1),

    .halfstrips            (halfstrips_last    [31:0]),
    .halfstrips_expect     (halfstrips_expect[31:0]),

    .offsets_errcnt        (offsets_errcnt[31:0]),
    .offsets_errcnt_rst    (offsets_errcnt_rst),

    .thresholds_errcnt     (thresholds_errcnt[31:0]),
    .thresholds_errcnt_rst (thresholds_errcnt_rst),

    .compout_expect        (compout_expect),
    .compout_last          (compout_last),

    .compout_errcnt        (compout_errcnt),
    .compout_errcnt_rst    (compout_errcnt_rst),

    .compin_inject         (compin_inject),

    .pktime                (pktime[2:0]),
    .pkmode                (pkmode[1:0]),
    .lctrst                (lctrst),

    .active_strip_mask     (active_strip_mask[31:0]), // OUT set mask of expected half-strips for this pattern

    .mux_high_adr          (high_adr_raw[3:0]), // Pulser high amplitude address
    .mux_med_adr           (med_adr_raw[3:0]),  // Pulser med amplitude address
    .mux_low_adr           (low_adr_raw[3:0]),  // Pulser low amplitude address

    .mux_en                (mux_en_raw),

    .mux_a0_next           (adr_next[0]),  // OUT next mux address 0
    .mux_a1_next           (adr_next[1]),  // OUT next mux address 1

    .mux_a0_prev           (adr_prev[0]),
    .mux_a1_prev           (adr_prev[1])

);

wire [3:0] high_adr_raw;
wire [3:0] med_adr_raw;
wire [3:0] low_adr_raw;

//----------------------------------------------------------------------------------------------------------------------
// Triad Decoder   FSMs to decode triads and map to half-strip hit register
//----------------------------------------------------------------------------------------------------------------------

genvar idistrip;
generate
for (idistrip=0; idistrip<=7; idistrip=idistrip+1)
begin: distrip_loop
    triad_decode utriad (
        .clock          ( clk40                               ),
        .reset          ( reset                               ),
        .persist        ( triad_persist-1'b1                  ), // Output persistence-1, ie 5 gives 6-clk width
        .persist1       ( triad_persist1                      ), // Output persistence is 1, use with  persist=0
        .triad          ( distrip[idistrip]                   ),
        .h_strip        ( halfstrips[3+idistrip*4:idistrip*4] ),
        .triad_skip     ( tskip[idistrip]                     ));
end
endgenerate

//----------------------------------------------------------------------------------------------------------------------
// Mux Protector
//----------------------------------------------------------------------------------------------------------------------

mux_protect umux_protect
(
  .clock      ( clk40),

  .high_adr_in( high_adr_raw), // software set address
  .med_adr_in ( med_adr_raw ), // software set address
  .low_adr_in ( low_adr_raw ), // software set address

  .mux_en_in  ( mux_en_raw),   // software set mux_enable

  .mux_en_out ( mux_en)        // hardware controlled mux_enable; shutoff if address conflict

);

assign adr_high = high_adr_raw;
assign adr_med  = med_adr_raw;
assign adr_low  = low_adr_raw;

led_ctrl u_led (
  .reset       ( reset),
  .dcms_locked (dcms_locked),
  .clock       ( clk40),
  .halfstrips  ( halfstrips),
  .leds        ( led[11:0])
);

//-the bitter end-------------------------------------------------------------------------------------------------------
endmodule
//----------------------------------------------------------------------------------------------------------------------
