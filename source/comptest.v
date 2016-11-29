`timescale 1ns / 1ps

module comptest (
    // Data Delay Chip
    input  mosi,
    output miso,
    input  sclk,
    input  cs,

    // Pulse Multiplexer Control

    output  mux_en, // global mux en

    output [3:0] adr_high,
    output [3:0] adr_med,
    output [3:0] adr_low,

    output  mux_a0_next,
    output  mux_a1_next,

    output  mux_a1_prev,
    output  mux_a0_prev,

    // Comparator Logic

    input   [7:0] distrip,

    input   compout,

    output  compin,
    output  lctrst,
    output  lctclk,
    output  [2:0] pktime,
    output  [1:0] pkmode,

    // Leds

    output [11:0] led,

    input osc40
);


/*
 * Inter-module connections
 */

wire [31:0] halfstrips;
wire [31:0] halfstrips_expect;

wire [31:0] offsets_errcnt;
wire [31:0] compout_errcnt;
wire [31:0] thresholds_errcnt;

wire compout_expect;
wire compout_ff  ;
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

dcm uclkgen (
    .CLK_IN1  ( osc40), // Oscillator 40MHz
    .CLK_OUT1 ( clk80), // 80 MHz logic output
    .CLK_OUT2 ( clk40), // 40 MHz logic output
    .RESET    ( dcm_rst),       // IN
    .LOCKED   ( dcm_islocked)
);


//----------------------------------------------------------------------------------------------------------------------
// should add 2nd dcm to phase shift the 40MHz clock for the comparators
//----------------------------------------------------------------------------------------------------------------------

dcm uclkgen (
    .CLK_IN1  ( clk40),   // 40 MHz input
    .CLK_OUT1 ( lct_clk), // Phase-shifted 40MHz output
    .RESET    ( dcm_rst), // IN
    .LOCKED   ( dcm_islocked)
);

//----------------------------------------------------------------------------------------------------------------------
// forward 40mhz clock to the lct comparator
//----------------------------------------------------------------------------------------------------------------------


ODDR2 #(
    .DDR_ALIGNMENT("NONE"), // Sets output alignment to "NONE", "C0" or "C1"
    .INIT(1'b0),            // Sets initial state of the Q output to 1'b0 or 1'b1
    .SRTYPE("SYNC")         // Specifies "SYNC" or "ASYNC" set/reset
    ) clock_forward_inst (
        .Q  (lctclk), // 1-bit DDR output data
        .C0 ( clk40), // 1-bit clock input
        .C1 (~clk40), // 1-bit clock input
        .CE (lctclk_en),   // 1-bit clock enable input
        .D0 (1'b0),   // 1-bit data input (associated with C0)
        .D1 (1'b1),   // 1-bit data input (associated with C1)
        .R  (1'b0)    // 1-bit reset input
        //.S(1'b1)    // 1-bit set input
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
    .offsets_errcnt     (offsets_errcnt[31:0]  ), // Out
    .thresholds_errcnt     (thresholds_errcnt[31:0]  ),
    .compout_errcnt        (compout_errcnt           ),
    .compout_expect        (compout_expect           ),
    .compout_ff            (compout_ff               ),
    .active_strip_mask     (active_strip_mask[31:0]  ),
    .compout_errcnt_rst    (compout_errcnt_rst       ),
    .offsets_errcnt_rst (offsets_errcnt_rst    ),
    .thresholds_errcnt_rst (thresholds_errcnt_rst    ),
    .compin_inject         (compin_inject            ),
    .fire_pulse            (fire_pulse               ), // In  inject pulse
    .pulser_ready          (pulser_ready             ), // Out pulser is idle
    .bx_delay              (bx_delay[3:0]            ), // In  delay after pulsing before reading out half-strips
    .pulse_width           (pulse_width[3:0]         ), // In  width of digital pulse (in bx)
    .pulse_en              (pulse_en                 ), // Out turn on pulse
    .clk                   (clk40                    )
);

//----------------------------------------------------------------------------------------------------------------------
//
//----------------------------------------------------------------------------------------------------------------------


// SPI Serial Interface
serial u_serial            (

    .bx_delay              (bx_delay[3:0]),
    .pulse_width           (pulse_width[3:0]),
    .fire_pulse            (fire_pulse),
    .pulser_ready          (pulser_ready),
    .triad_persist         (triad_persist[3:0]),
    .triad_persist1        (triad_persist1),

    .halfstrips            (halfstrips_last    [31:0]),
    .halfstrips_expect     (halfstrips_expect[31:0]),

    .offsets_errcnt     (offsets_errcnt[31:0]),
    .offsets_errcnt_rst (offsets_errcnt_rst),

    .thresholds_errcnt     (thresholds_errcnt[31:0]),
    .thresholds_errcnt_rst (thresholds_errcnt_rst),

    .compout_expect        (compout_expect),
    .compout_ff            (compout_ff),

    .compout_errcnt        (compout_errcnt),
    .compout_errcnt_rst    (compout_errcnt_rst),

    .compin_inject         (compin_inject),

    .pktime                (pktime[2:0]),
    .pkmode                (pkmode[1:0]),
    .lctrst                (lctrst),

    .active_strip_mask     (active_strip_mask[31:0]), // OUT set mask of expected half-strips for this pattern

    .high_adr              (high_adr_raw[3:0]), // Pulser high amplitude address
    .med_adr               (med_adr_raw[3:0]),  // Pulser med amplitude address
    .low_adr               (low_adr_raw[3:0]),  // Pulser low amplitude address

    .mux_en                (mux_en_raw),

    .mux_a0_next           (mux_a0_next),  // OUT next mux address 0
    .mux_a1_next           (mux_a1_next),  // OUT next mux address 1

    .mux_a0_prev           (mux_a0_prev),
    .mux_a1_prev           (mux_a1_prev),

    .clk                   (clk40)
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
        .reset          ( 1'b0                                ),
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

  .high_adr   ( high_adr_raw), // software set address
  .med_adr    ( med_adr_raw ), // software set address
  .low_adr    ( low_adr_raw ), // software set address

  .mux_en_in  ( mux_en_raw),   // software set mux_enable

  .mux_en_out ( mux_en)        // hardware controlled mux_enable; shutoff if address conflict

);

//-the bitter end-------------------------------------------------------------------------------------------------------
endmodule
//----------------------------------------------------------------------------------------------------------------------
