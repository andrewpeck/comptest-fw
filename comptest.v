`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    12:10:08 12/04/2014
// Design Name:
// Module Name:    comptest
// Project Name:
// Target Devices:
// Tool versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module comptest (
    // Data Delay Chip
    output _ddd_al,
    input  ddd_miso,
    output ddd_mosi,
    output ddd_sclk,

    // Serial Interface
    input  _ft_reset,
    input  _ft_oe,
    input  _ft_txe,
    input  _ft_rxf,
    input  ft_clk,
    output _ft_wr,
    output _ft_siwu,
    output _ft_rd,

    // Pulse Generation
    output  pdac_sclk,
    output  pdac_din,
    output  _pdac_en,
    output  pulse_en,

    input pulse_trig,

    // Comparator Threshold DAC
    output  cdac_sclk,
    output  cdac_din,
    output  _cdac_en,

    // bidirectional 8 bit data bus
    inout   [7:0] ft_data,

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
    input   [7:0] distrip
);

//------------------------------------------------------------------------------
// Inter-module connections
//------------------------------------------------------------------------------


//wire halfstrips_expect;
//reg[31:0] halfstrips_errcnt;
//reg[31:0] compout_errcnt;

//------------------------------------------------------------------------------
// 40 MHz Clock Generation
//------------------------------------------------------------------------------
wire dcm_rst;
wire dcm_islocked;
wire clock40;
wire clock100;

dcm uclkgen
(
    // Clock in ports
    .CLK_IN1(ft_clk), // IN
    // Clock out ports
    .CLK_OUT1(clock100),   // OUT
    .CLK_OUT2(clock40),    // OUT
    // Status and control signals
    .RESET(dcm_rst),       // IN
    .LOCKED(dcm_islocked)
);


//------------------------------------------------------------------------------
// Comparator Injector
//------------------------------------------------------------------------------

wire [31:0] halfstrips;
wire [31:0] halfstrips_expect;

wire [31:0] halfstrips_errcnt;
wire [31:0] compout_errcnt;

wire compout_expect;
wire compout_errcnt_rst;
wire halfstrips_errcnt_rst;
wire compin_inject;

wire pulser_ready;

wire [2:0] bx_delay;
wire [3:0] pulse_width;

wire fire_pulse;

comparator_injector u_comparator_injector (
    .halfstrips                           ( halfstrips[31:0]        ) ,
    .halfstrips_expect                    ( halfstrips_expect[31:0] ) ,
    .halfstrips_errcnt                    ( halfstrips_errcnt[31:0] ) ,
    .compout_errcnt                       ( compout_errcnt[31:0]    ) ,
    .compout                              ( compout                 ) ,
    .compout_expect                       ( compout_expect          ) ,
    .compout_errcnt_rst                   ( compout_errcnt_rst      ) ,
    .halfstrips_errcnt_rst                ( halfstrips_errcnt_rst   ) ,
    .compin_inject                        ( compin_inject           ) ,
    .compin                               ( compin                  ) ,
    .fire_pulse                           ( fire_pulse              ) ,
    .pulser_ready                         ( pulser_ready            ) ,
    .bx_delay                             ( bx_delay                ) ,
    .pulse_width                          ( pulse_width             ) ,
    .pulse_en                             ( pulse_en                ) ,
    .clock40                              ( clock40                 )
                                                                    ) ;


//------------------------------------------------------------------------------
// Serial Port
//------------------------------------------------------------------------------

// Instantiate the module
serial u_serial            (
    .adc_sclk              ( adc_sclk                ) ,
    ._adc_cs               ( _adc_cs                 ) ,
    .adc_mosi              ( adc_mosi                ) ,
    .adc_miso              ( adc_miso                ) ,
    ._pdac_en              ( _pdac_en                ) ,
    .pdac_din              ( pdac_din                ) ,
    .pdac_sclk             ( pdac_sclk               ) ,
    .bx_delay              ( bx_delay[2:0]           ) ,
    .pulse_width           ( pulse_width[3:0]        ) ,
    .fire_pulse            ( fire_pulse              ) ,
    .pulser_ready          ( pulser_ready            ) ,
    .halfstrips            ( halfstrips[31:0]        ) ,
    .halfstrips_expect     ( halfstrips_expect[31:0] ) ,
    .halfstrips_errcnt     ( halfstrips_errcnt[31:0] ) ,
    .halfstrips_errcnt_rst ( halfstrips_errcnt_rst   ) ,
    .compout_expect        ( compout_expect          ) ,
    .compout_errcnt        ( compout_errcnt[31:0]    ) ,
    .compout_errcnt_rst    ( compout_errcnt_rst      ) ,
    .compin_inject         ( compin_inject           ) ,
    .pktime                ( pktime[2:0]             ) ,
    .pkmode                ( pkmode[1:0]             ) ,
    .compout               ( compout                 ) ,
    .compin                ( compin                  ) ,
    .lctclk                ( lctclk                  ) ,
    .lctrst                ( lctrst                  ) ,
    ._cdac_en              ( _cdac_en                ) ,
    .cdac_din              ( cdac_din                ) ,
    .cdac_sclk             ( cdac_sclk               ) ,
    .mux_a0                ( mux_a0[15:0]            ) ,
    .mux_a1                ( mux_a1[15:0]            ) ,
    .mux_a0_next           ( mux_a0_next             ) ,
    .mux_a1_next           ( mux_a1_next             ) ,
    .mux_a0_prev           ( mux_a0_prev             ) ,
    .mux_a1_prev           ( mux_a1_prev             ) ,
    ._ddd_al               ( _ddd_al                 ) ,
    .ddd_mosi              ( ddd_mosi                ) ,
    .ddd_miso              ( ddd_miso                ) ,
    .ddd_sclk              ( ddd_sclk                ) ,
    .clock40               ( clock40                 ) ,
    ._ft_reset             ( _ft_reset                ) ,
    ._ft_oe                ( _ft_oe                  ) ,
    ._ft_txe               ( _ft_txe                 ) ,
    ._ft_rxf               ( _ft_rxf                 ) ,
    .ft_clk                ( ft_clk                  ) ,
    ._ft_wr                ( _ft_wr                  ) ,
    ._ft_siwu              ( _ft_siwu                ) ,
    ._ft_rd                ( _ft_rd                  ) ,
    .ft_data               ( ft_data[7:0]            )
                                                     ) ;

//------------------------------------------------------------------------------
// Triad Decoder   FSMs to decode triads and map to half-strip hit register
//------------------------------------------------------------------------------

wire [7:0] tskip;   // Skipped triads

wire triad_skip;
assign triad_skip = (|tskip[0]) | (|tskip[1]) | (|tskip[2]) | (|tskip[3]) | (|tskip[4]) | (|tskip[5]);

reg   [3:0]   persist  = 0;            // Output persistence-1, ie 5 gives 6-clk width
reg           persist1 = 1;           // Output persistence is 1, use with  persist=0

genvar idistrip;
generate
for (idistrip=0; idistrip<=7; idistrip=idistrip+1)
begin: distrip_loop
    triad_decode utriad (clock40, lctrst, persist, persist1,
    distrip[idistrip],halfstrips[3+idistrip*4:idistrip*4],tskip[idistrip]);
end
endgenerate

//------------------------------------------------------------------------------
// The bitter end
//------------------------------------------------------------------------------

endmodule


//------------------------------------------------------------------------------
// Decode Triads into a 32bit Distrip Hit Register
//------------------------------------------------------------------------------
// reg [2:0] triad0;
// reg [2:0] triad1;
// reg [2:0] triad2;
// reg [2:0] triad3;
// reg [2:0] triad4;
// reg [2:0] triad5;
// reg [2:0] triad6;
// reg [2:0] triad7;
//
// // need to loop in 40Mhz Clock Cycles and assign from distrip_rd[7:0] into
// // these registers
//
// reg [32:0] halfstrips;
//
// // Decode Distrip Triad into Half-strip Mapping
// function [4:0] decode_triad;
//     input [3:0] triad;
//     reg   [3:0] hs;
//     case (triad)
//         3'b000: hs = 4'b0000;
//         3'b001: hs = 4'b0000;
//         3'b010: hs = 4'b0000;
//         3'b011: hs = 4'b0000;
//         3'b100: hs = 4'b0001;
//         3'b101: hs = 4'b0010;
//         3'b110: hs = 4'b0100;
//         3'b111: hs = 4'b1000;
//     endcase
//     decode_triad [4:0] = hs [4:0];
// endfunction
//
// reg [1:0] i = 0;
