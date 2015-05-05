`timescale 1ns / 1ps

module comptest (
    // Data Delay Chip
    output _ddd_al,
    input  ddd_miso,
    output ddd_mosi,
    output ddd_sclk,

    // Serial Interface
    input  _ft_reset,
    output _ft_oe,
    input  _ft_txe,
    input  _ft_rxf,
    input   ft_clk,
    output _ft_wr,
    output _ft_siwu,
    output _ft_rd,

    // bidirectional 8 bit data bus
    inout   [7:0] ft_data,

    // Pulse Generation
    output   pdac_sclk,
    output   pdac_din,
    output  _pdac_en,
    output   pulse_en,

    input pulse_trig,

    // Comparator Threshold DAC
    output  cdac_sclk,
    output  cdac_din,
    output  _cdac_en,


    // Pulse Multiplexer Control
    output  [15:0] mux_a1,
    output  mux_a0_next,
    output  [15:0] mux_a0,
    output  mux_a1_next,
    output  mux_a1_prev,
    output  mux_a0_prev,

    // ADC Control
    output  _adc_cs,
    input   adc_miso,
    output  adc_mosi,
    output  adc_sclk,


    // Comparator Logic
    output  compin,
    output  lctrst,
    output  lctclk,
    output  [2:0] pktime,
    output  [1:0] pkmode,
    input   compout,
    input   [7:0] distrip,

    input osc40,

    output sump
);

/*
 * Inter-module connections
 */

//------------------------------------------------------------------------------
// 40 MHz Clock Generation
//------------------------------------------------------------------------------
wire dcm_rst;
wire dcm_islocked;

assign _ft_siwu = 1'b1;

IBUFG CLOCK60 (.I(ft_clk),.O(clk60));
IBUFG CLOCK40 (.I(osc40), .O(clk40));

//dcm uclkgen
//(
//    .CLK_IN1(ft_clk), // Clock in ports
//    .CLK_OUT1(clk60), // Clock out ports
//    .CLK_OUT2(clk40), // Clock out ports
//    .RESET(dcm_rst),       // IN
//    .LOCKED(dcm_islocked)
//);

// Clock forwarding circuit using the double data-rate register
//        Spartan-3E/3A/6
// Xilinx HDL Language Template, version 14.7

ODDR2 #(
    .DDR_ALIGNMENT("NONE"), // Sets output alignment to "NONE", "C0" or "C1"
    .INIT(1'b0),            // Sets initial state of the Q output to 1'b0 or 1'b1
    .SRTYPE("SYNC")         // Specifies "SYNC" or "ASYNC" set/reset
    ) clock_forward_inst (
        .Q(lctclk),           // 1-bit DDR output data
        .C0(clk40),           // 1-bit clock input
        .C1(~clk40),         // 1-bit clock input
        .CE(!lctrst),            // 1-bit clock enable input
        .D0(1'b0),            // 1-bit data input (associated with C0)
        .D1(1'b1),            // 1-bit data input (associated with C1)
        .R(!lctrst)          // 1-bit reset input
        //.S(1'b1) // 1-bit set input
    );

    // End of clock_forward_inst instantiation



/*
 * Comparator Injector
 */

// Intermodule Connections
wire [31:0] halfstrips;
wire [31:0] halfstrips_expect;

wire [31:0] halfstrips_errcnt;
wire [31:0] compout_errcnt;
wire [31:0] thresholds_errcnt;

wire compout_expect;
wire compout_last;
wire compout_errcnt_rst;
wire halfstrips_errcnt_rst;
wire compin_inject;

wire pulser_ready;

wire [2:0] bx_delay;
wire [3:0] pulse_width;

wire fire_pulse;

wire [31:0] active_strip_mask;

comparator_injector u_comparator_injector (
    .halfstrips                           ( halfstrips[31:0]         ),
    .halfstrips_expect                    ( halfstrips_expect[31:0]  ),
    .halfstrips_errcnt                    ( halfstrips_errcnt[31:0]  ),
    .thresholds_errcnt                    ( thresholds_errcnt[31:0]  ),
    .compout_errcnt                       ( compout_errcnt           ),
    .compout                              ( compout                  ),
    .compout_expect                       ( compout_expect           ),
    .compout_last                         ( compout_last             ),
    .active_strip_mask                    ( active_strip_mask        ),
    .compout_errcnt_rst                   ( compout_errcnt_rst       ),
    .halfstrips_errcnt_rst                ( halfstrips_errcnt_rst    ),
    .thresholds_errcnt_rst                ( thresholds_errcnt_rst    ),
    .compin_inject                        ( compin_inject            ),
    .compin                               ( compin                   ),
    .fire_pulse                           ( fire_pulse               ),
    .pulser_ready                         ( pulser_ready             ),
    .bx_delay                             ( bx_delay                 ),
    .pulse_width                          ( pulse_width              ),
    .pulse_en                             ( pulse_en                 ),
    .clk                                  ( clk40                    ));

/*
 *  FT245 USB-to-Serial Converter
 */

// Inter-module connects
wire _serial_wr;
wire _serial_rd;

wire [7:0] ft_byte_in;
wire [7:0] ft_byte_out;

ft245 u_ft245 (
    .clk          ( clk60       ), // 60 MHz FT232H clock

    ._txe         (_ft_txe      ), // Can TX
    ._rxf         (_ft_rxf      ), // Can RX

    ._rd          (_ft_rd       ), // Read Must Be low to be able to read
    ._wr          (_ft_wr       ), // Write must be low to write to usb

    ._oe          (_ft_oe       ), // Output enable, high to write to USB
    ._reset       (_ft_reset    ), // FTDI Reset, active low

    .data         ( ft_data     ), // Bidirectional FIFO data

    ._write_data  (_serial_wr   ), // put low if you want to write data
    ._read_data   (_serial_rd   ), // put low if you want to read data

    .data_to_pc   ( ft_byte_in ), // data to be written to pc
    .data_to_fpga ( ft_byte_out)  // data to be read out from pc
);


/*
 * VME Style Serial Interface
 */

wire triad_perist1;
wire [3:0] triad_persist;

// Instantiate the module
serial u_serial            (
    .adc_sclk              (  adc_sclk                ),
    ._adc_cs               ( _adc_cs                  ),
    .adc_mosi              (  adc_mosi                ),
    .adc_miso              (  adc_miso                ),

    ._pdac_en              ( _pdac_en                 ),
    .pdac_din              (  pdac_din                ),
    .pdac_sclk             (  pdac_sclk               ),

    .bx_delay              (  bx_delay[2:0]           ),
    .pulse_width           (  pulse_width[3:0]        ),
    .fire_pulse            (  fire_pulse              ),
    .pulser_ready          (  pulser_ready            ),
    .triad_persist         (  triad_persist[3:0]      ),
    .triad_persist1        (  triad_persist1          ),

    .halfstrips            (  halfstrips[31:0]        ),
    .halfstrips_expect     (  halfstrips_expect[31:0] ),

    .halfstrips_errcnt     (  halfstrips_errcnt[31:0] ),
    .halfstrips_errcnt_rst (  halfstrips_errcnt_rst   ),

    .thresholds_errcnt     ( thresholds_errcnt[31:0]  ),
    .thresholds_errcnt_rst ( thresholds_errcnt_rst    ),

    .compout_expect        (  compout_expect          ),
    .compout_last          (  compout_last            ),

    .compout_errcnt        (  compout_errcnt          ),
    .compout_errcnt_rst    (  compout_errcnt_rst      ),

    .compin_inject         (  compin_inject           ),

    .pktime                (  pktime[2:0]             ),
    .pkmode                (  pkmode[1:0]             ),
    .lctrst                (  lctrst                  ),

    ._cdac_en              ( _cdac_en                 ),
    .cdac_din              (  cdac_din                ),
    .cdac_sclk             (  cdac_sclk               ),
    .active_strip_mask     (  active_strip_mask       ),

    .mux_a0                (  mux_a0[15:0]            ),
    .mux_a1                (  mux_a1[15:0]            ),
    .mux_a0_next           (  mux_a0_next             ),
    .mux_a1_next           (  mux_a1_next             ),
    .mux_a0_prev           (  mux_a0_prev             ),
    .mux_a1_prev           (  mux_a1_prev             ),

    ._ddd_al               ( _ddd_al                  ),
    .ddd_mosi              (  ddd_mosi                ),
    .ddd_miso              (  ddd_miso                ),
    .ddd_sclk              (  ddd_sclk                ),

    ._reset                (_ft_reset                 ),
    .clk                   ( clk60                    ),
    ._serial_wr            (_serial_wr                ),
    ._serial_rd            (_serial_rd                ),

    ._ft_rxf               (_ft_rxf                   ),
    ._ft_wr                (_ft_wr                    ),
    ._ft_rd                (_ft_rd                    ),
    .ft_byte_out           ( ft_byte_out              ),
    .ft_byte_in            ( ft_byte_in               ),
    .serial_sump           ( serial_sump              ));

assign sump = serial_sump;


/*
 * Triad Decoder   FSMs to decode triads and map to half-strip hit register
 */

wire [7:0] tskip;   // Skipped triads

wire triad_skip;
assign triad_skip = (|tskip[0]) | (|tskip[1]) | (|tskip[2]) | (|tskip[3]) | (|tskip[4]) | (|tskip[5]);


reg   [3:0]   persist  = 0;            // Output persistence-1, ie 5 gives 6-clk width
reg           persist1 = 0;            // Output persistence is 1, use with  persist=0

always @ (posedge clk40)
begin
    persist  <= (triad_persist-1'b1);
    persist1 <= (triad_persist1==1 || triad_persist1==0);
end

genvar idistrip;
generate
for (idistrip=0; idistrip<=7; idistrip=idistrip+1)
begin: distrip_loop
    triad_decode utriad (
        .clock          ( clk40                               ),
        .reset          ( lctrst                              ),
        .persist        ( persist                             ),
        .persist1       ( persist1                            ),
        .triad          ( distrip[idistrip]                   ),
        .h_strip        ( halfstrips[3+idistrip*4:idistrip*4] ),
        .triad_skip     ( tskip[idistrip]                     ));
end
endgenerate

endmodule
