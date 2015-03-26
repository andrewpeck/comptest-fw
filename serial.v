`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////

module serial
(
    // ADC Control
    output wire  adc_sclk,
    output wire _adc_cs,
    output wire  adc_mosi,
    input  wire  adc_miso,

    // Pulse Control
    output wire _pdac_en,
    output wire  pdac_din,
    output wire  pdac_sclk,

    output wire [2:0] bx_delay,
    output wire [3:0] pulse_width,
    output wire       fire_pulse,
    input  wire       pulser_ready,

    output wire [3:0] triad_persist,
    output wire       triad_persist1,

    // Halfstrips
    input  wire [31:0] halfstrips,
    output wire [31:0] halfstrips_expect,
    input  wire [31:0] halfstrips_errcnt,
    output wire        halfstrips_errcnt_rst,

    output wire compout_expect,
    input  wire [31:0] compout_errcnt,
    output wire        compout_errcnt_rst,
    output wire        compin_inject,

    // Comparator Config
    output wire [2:0] pktime,
    output wire [1:0] pkmode,
    output wire lctrst,

    output  wire _cdac_en,
    output  wire cdac_din,
    output  wire cdac_sclk,

    // Mux Ctrl
    output wire [15:0] mux_a0,
    output wire [15:0] mux_a1,

    output wire mux_a0_next,
    output wire mux_a1_next,

    output wire mux_a0_prev,
    output wire mux_a1_prev,

    output wire _ddd_al,
    output wire  ddd_mosi,
    input  wire  ddd_miso,
    output wire  ddd_sclk,

    input  wire  _reset,
    input  wire  _ft_rxf,
    input  wire   clk,
    input  wire  _ft_rd,
    input  wire  _ft_wr,
    output reg   _serial_wr,
    output reg   _serial_rd,

    input wire  [7:0] ft_byte_out,
    output reg  [7:0] ft_byte_in,

    output wire serial_sump
);

//------------------------------------------------------------------------------
// ADR_COMP_CONFIG=0x01
//------------------------------------------------------------------------------

parameter ADR_COMP_CONFIG=4'h01;
// Write

reg [31:0] comp_config_in = 32'h0;

assign  pktime[0] = comp_config_in[0];
assign  pktime[1] = comp_config_in[1];
assign  pktime[2] = comp_config_in[2];

assign  pkmode[0] = comp_config_in[3];
assign  pkmode[1] = comp_config_in[4];

assign  lctrst    = comp_config_in[5];

assign _cdac_en   = comp_config_in[6];
assign  cdac_din  = comp_config_in[7];
assign  cdac_sclk = comp_config_in[8];

// Read

wire [31:0] comp_config_out;
assign comp_config_out[31:0] = comp_config_in [31:0];

//------------------------------------------------------------------------------
// ADR_PULSE_CTRL=0x02
//------------------------------------------------------------------------------
parameter ADR_PULSE_CTRL = 4'h02;

// Write
reg [31:0] pulse_ctrl_in;

initial
begin
    pulse_ctrl_in[0]            = 1'b0; //  fire_pulse

    pulse_ctrl_in[1]            = 1'b0; //  pulse_width [0]
    pulse_ctrl_in[2]            = 1'b0; //  pulse_width [1]
    pulse_ctrl_in[3]            = 1'b0; //  pulse_width [2]
    pulse_ctrl_in[4]            = 1'b0; //  pulse_width [3]

    pulse_ctrl_in[5]            = 1'b1; // _pulsedac_en
    pulse_ctrl_in[6]            = 1'b0; //  pulsedac_din
    pulse_ctrl_in[7]            = 1'b0; // _pulsedac_sclk

    pulse_ctrl_in[8]            = 1'b0; //  halfstrips_errcnt_rst
    pulse_ctrl_in[9]            = 1'b0; //  compout_errcnt_rst
    pulse_ctrl_in[10]           = 1'b0; //  compin_inject

    pulse_ctrl_in[11]           = 1'b0; //  bx_delay [0]
    pulse_ctrl_in[12]           = 1'b0; //  bx_delay [1]
    pulse_ctrl_in[13]           = 1'b0; //  bx_delay [2]

    pulse_ctrl_in[14]           = 1'b0; // compout_expect


    pulse_ctrl_in[18:15]        = 1'b0; // triad_persist
    pulse_ctrl_in[19]           = 1'b0; // triad_persist1

    pulse_ctrl_in[31:20]        = 0;
end

assign  fire_pulse              = pulse_ctrl_in[0];
assign  pulse_width             = pulse_ctrl_in[4:1];

assign _pdac_en                 = pulse_ctrl_in[5];
assign  pdac_din                = pulse_ctrl_in[6];
assign  pdac_sclk               = pulse_ctrl_in[7];

assign  halfstrips_errcnt_rst   = pulse_ctrl_in[8];
assign  compout_errcnt_rst      = pulse_ctrl_in[9];
assign  compin_inject           = pulse_ctrl_in[10];

assign  bx_delay[0]             = pulse_ctrl_in[11];
assign  bx_delay[1]             = pulse_ctrl_in[12];
assign  bx_delay[2]             = pulse_ctrl_in[13];

assign  compout_expect           = pulse_ctrl_in[14];

assign  triad_persist            = pulse_ctrl_in [18:15];
assign  triad_persist1           = pulse_ctrl_in [19];

// Read
wire [31:0] pulse_ctrl_out;
assign pulse_ctrl_out [13:0]  = pulse_ctrl_in[13:0];
assign pulse_ctrl_out [14]    = pulser_ready;
assign pulse_ctrl_out [31:15] = pulse_ctrl_in[31:15];

//------------------------------------------------------------------------------
// ADR_MUX1=0x03
//------------------------------------------------------------------------------
parameter ADR_MUX1 = 4'h03;

// Write

reg [31:0] mux1_in = 32'h0;

assign  mux_a0_prev  = mux1_in[0];
assign  mux_a1_prev  = mux1_in[1];

assign  mux_a0_next  = mux1_in[2];
assign  mux_a1_next  = mux1_in[3];

//Read

wire [31:0] mux1_out;
assign mux1_out[31:0] = mux1_in[31:0];  // All bits are R/W

//------------------------------------------------------------------------------
// ADR_MUX2=0x04
//------------------------------------------------------------------------------
parameter ADR_MUX2 = 4'h04;

// Write

reg [31:0] mux2_in = 32'h0;

assign mux_a0[0]  = mux2_in[0];     // Mux 0 bit 0
assign mux_a1[0]  = mux2_in[1];     // Mux 0 bit 1
assign mux_a0[1]  = mux2_in[2];     // Mux 1 bit 0
assign mux_a1[1]  = mux2_in[3];     // Mux 1 bit 1
assign mux_a0[2]  = mux2_in[4];     // ...
assign mux_a1[2]  = mux2_in[5];     // etc
assign mux_a0[3]  = mux2_in[6];
assign mux_a1[3]  = mux2_in[7];
assign mux_a0[4]  = mux2_in[8];
assign mux_a1[4]  = mux2_in[9];
assign mux_a0[5]  = mux2_in[10];
assign mux_a1[5]  = mux2_in[11];
assign mux_a0[6]  = mux2_in[12];
assign mux_a1[6]  = mux2_in[13];
assign mux_a0[7]  = mux2_in[14];
assign mux_a1[7]  = mux2_in[15];
assign mux_a0[8]  = mux2_in[16];
assign mux_a1[8]  = mux2_in[17];
assign mux_a0[9]  = mux2_in[18];
assign mux_a1[9]  = mux2_in[19];
assign mux_a0[10] = mux2_in[20];
assign mux_a1[10] = mux2_in[21];
assign mux_a0[11] = mux2_in[22];
assign mux_a1[11] = mux2_in[23];
assign mux_a0[12] = mux2_in[24];
assign mux_a1[12] = mux2_in[25];
assign mux_a0[13] = mux2_in[26];
assign mux_a1[13] = mux2_in[27];
assign mux_a0[14] = mux2_in[28];
assign mux_a1[14] = mux2_in[29];
assign mux_a0[15] = mux2_in[30];
assign mux_a1[15] = mux2_in[31];

// Read

wire [31:0] mux2_out;
assign mux2_out[31:0] = mux2_in[31:0];  // All bits are R/W

//------------------------------------------------------------------------------
// ADR_HALFSTRIPS=0x05
//------------------------------------------------------------------------------

parameter ADR_HALFSTRIPS=4'h05;

wire [31:0] halfstrips_out;
assign halfstrips_out [31:0] = halfstrips [31:0];

//------------------------------------------------------------------------------
// ADR_HALFSTRIPS_EXPECT=0x06
//------------------------------------------------------------------------------

parameter ADR_HALFSTRIPS_EXPECT=4'h06;

reg [31:0] halfstrips_expect_in;
initial
begin
    halfstrips_expect_in = 32'b0;
end

wire [31:0] halfstrips_expect_out;
assign halfstrips_expect     [31:0] = halfstrips_expect_in [31:0];
assign halfstrips_expect_out [31:0] = halfstrips_expect    [31:0];

//------------------------------------------------------------------------------
// ADR_HALFSTRIPS_ERRCNT=0x07
//------------------------------------------------------------------------------

parameter ADR_HALFSTRIPS_ERRCNT=4'h07;

wire [31:0] halfstrips_errcnt_out;
assign halfstrips_errcnt_out [31:0] = halfstrips_errcnt [31:0];

//------------------------------------------------------------------------------
// ADR_COMPOUT_ERRCNT=0x0A
//------------------------------------------------------------------------------

parameter ADR_COMPOUT_ERRCNT = 4'h0A;
wire [31:0] compout_errcnt_out;
assign compout_errcnt_out [31:0] = compout_errcnt [31:0];

//------------------------------------------------------------------------------
// ADR_ADC=0x08
//------------------------------------------------------------------------------

parameter ADR_ADC = 4'h08;

// Write
reg  [31:0] adc_in;

initial
begin
    adc_in[0]    = 1'b0; //  adc_sclk
    adc_in[1]    = 1'b0; //  adc_mosi
    adc_in[2]    = 1'b1; // _adc_cs
    adc_in[31:3] = 0;
end

assign _adc_cs   = adc_in[0];
assign  adc_mosi = adc_in[1];
assign  adc_sclk = adc_in[2];

// Read

wire [31:0] adc_out;

assign adc_out[0] = _adc_cs;       // W/R
assign adc_out[1] =  adc_mosi;     // W/R
assign adc_out[2] =  adc_sclk;     // W/R
assign adc_out[3] =  adc_miso;     // R

assign adc_out[31:4]  =  adc_in[31:4];    // Unused

//------------------------------------------------------------------------------
// ADR_DDD=0x09
//------------------------------------------------------------------------------
parameter ADR_DDD = 4'h09;

// Write

reg  [31:0] ddd_in;

initial begin
    ddd_in[0]    = 1'b1; // ddd Adr Latch
    ddd_in[1]    = 1'b0; // ddd mosi
    ddd_in[2]    = 1'b0; // ddd_sclk
    ddd_in[31:3] = 1'b0;
end

assign  _ddd_al  = ddd_in[0];    // Adr Latch (Active Low)
assign  ddd_mosi = ddd_in[1];    // Serial In
assign  ddd_sclk = ddd_in[2];    // Serial Clock

// Read

wire [31:0] ddd_out;

assign ddd_out[0]    = _ddd_al;    // R/W Addr Latch
assign ddd_out[1]    =  ddd_mosi;  // R/W Serial Data In
assign ddd_out[2]    =  ddd_sclk;  // R/W Clock
assign ddd_out[3]    =  ddd_miso;
assign ddd_out[31:4] =  ddd_in [31:4];



//------------------------------------------------------------------------------
// FTDI 245H Serial-USB Interface Control
//------------------------------------------------------------------------------

//reg [7:0] ft_data;

//------------------------------------------------------------------------------
// Readout of FTDI Chip
//------------------------------------------------------------------------------

parameter READ_CMD  = 4'hA;
parameter WRITE_CMD = 4'h5;

reg[31:0] dword_out;
reg[3:0] ibyte;

reg[3:0] cmd;
reg[3:0] adr;
wire[3:0] reg_adr;

reg[31:0] dword_in;

/* Serial Read/Write State Machine */
initial
begin
    ibyte        <= 32'h0;
    cmd          <= 4'h0;
    adr          <= 4'hF;
    dword_in     <= 32'h0;
end

parameter idle = 4'h0;
parameter rd1  = 4'h1;
parameter rd2  = 4'h2;
parameter rd3  = 4'h3;
parameter rd4  = 4'h4;
parameter wr1  = 4'h5;
parameter wr2  = 4'h6;
parameter wr3  = 4'h7;
parameter wr4  = 4'h8;
parameter wr5  = 4'h9;

reg [3:0] serialstate = 4'h0;
reg update_serial = 4'h0;

always @ (posedge clk)
begin
    case (serialstate)
        /* Idle */
        idle:
        begin
            // Seq
            _serial_wr  <= 1'b1;
            _serial_rd  <= 1'b0;
            ft_byte_in  <= 8'h0;
            adr         <= ft_byte_out[7:4];

            // Combo
            if(!_ft_rxf)
            begin
                if (ft_byte_out[3:0]==READ_CMD)
                    serialstate <= rd1;
                else if (ft_byte_out[3:0]==WRITE_CMD)
                    serialstate <= wr1;
                else
                    serialstate <= idle;
            end
            else
                serialstate <= idle;
        end

        /* Read */
        rd1:
        begin
            // Seq
            update_serial <= 1'b0;
            _serial_wr    <= 1'b1;
            _serial_rd    <= 1'b0;
            ft_byte_in    <= dword_out[7:0];
            // Combo
            if (_ft_rd==0) serialstate <= rd2;
        end

        rd2:
        begin
            ft_byte_in <= dword_out[15:8];
            if (_ft_rd==0) serialstate <= rd3;
        end
        rd3:
        begin
            ft_byte_in <= dword_out[23:16];
            if (_ft_rd==0) serialstate <= rd4;   else serialstate <= rd3;
        end
        rd4:
        begin
            _serial_rd    <= 1'b1;
            ft_byte_in    <= dword_out[31:24];
            if (_ft_rd==0) serialstate <= idle;  else serialstate <= rd4;
        end

        /* Write */
        wr1: begin
             update_serial      <= 1'b0;
            _serial_wr          <= 1'b0;
            _serial_rd          <= 1'b1;
             dword_in    [7:0]  <= ft_byte_out[7:0];
            if (_ft_wr==0) serialstate <= wr2;   else serialstate <= wr1;
        end
        wr2:
        begin
            dword_in    [15:8]  <= ft_byte_out [7:0];
            if (_ft_wr==0) serialstate <= wr3;   else serialstate <= wr2;
        end
        wr3:
        begin
            dword_in    [23:16] <= ft_byte_out [7:0];
            if (_ft_wr==0) serialstate <= wr4;   else serialstate <= wr3;
        end
        wr4:
        begin
            dword_in    [31:24] <= ft_byte_out [7:0];
            if (_ft_wr==0) serialstate <= wr5;   else serialstate <= wr4;
        end
        wr5:
        begin
            _serial_wr  <= 1'b1;
            serialstate  <= idle;
            update_serial <= 1'b1;
        end

        /* This Should Never Happen */
        default:
        begin
            ft_byte_in   <= 8'h0;
            dword_in     <= 32'h0;
            serialstate   <= idle;
        end
    endcase
end

/* Out to PC */
always @(*)
begin
    case(adr)
        ADR_COMP_CONFIG:         dword_out  = comp_config_out;
        ADR_PULSE_CTRL:          dword_out  = pulse_ctrl_out;
        ADR_MUX1:                dword_out  = mux1_out;
        ADR_MUX2:                dword_out  = mux2_out;
        ADR_HALFSTRIPS:          dword_out  = halfstrips_out;
        ADR_HALFSTRIPS_EXPECT:   dword_out  = halfstrips_expect_out;
        ADR_HALFSTRIPS_ERRCNT:   dword_out  = halfstrips_errcnt_out;
        ADR_COMPOUT_ERRCNT:      dword_out  = compout_errcnt_out;
        ADR_ADC:                 dword_out  = adc_out;
        ADR_DDD:                 dword_out  = ddd_out;
        default:                 dword_out  = 32'hDEADBEEF;
    endcase
end

/* In from PC */

wire wr_comp_config       = (adr==ADR_COMP_CONFIG)       && (update_serial);
wire wr_pulse_ctrl        = (adr==ADR_PULSE_CTRL)        && (update_serial);
wire wr_mux1              = (adr==ADR_MUX1)              && (update_serial);
wire wr_mux2              = (adr==ADR_MUX2)              && (update_serial);
wire wr_halfstrips_expect = (adr==ADR_HALFSTRIPS_EXPECT) && (update_serial);
wire wr_adc               = (adr==ADR_ADC)               && (update_serial);
wire wr_ddd               = (adr==ADR_DDD)               && (update_serial);

always @ (posedge clk)
begin
    if (wr_comp_config)       comp_config_in       <= dword_in;
    if (wr_pulse_ctrl)        pulse_ctrl_in        <= dword_in;
    if (wr_mux1)              mux1_in              <= dword_in;
    if (wr_mux2)              mux2_in              <= dword_in;
    if (wr_halfstrips_expect) halfstrips_expect_in <= dword_in;
    if (wr_adc)               adc_in               <= dword_in;
    if (wr_ddd)               ddd_in               <= dword_in;
end

assign serial_sump = !(adc_in[31:3] | ddd_in [31:3] | mux1_in[31:4] | pulse_ctrl_in[31:15] | comp_config_in [31:9]);

endmodule
