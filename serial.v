`timescale 1ns / 1ps

module serial
(
    // ADC Control
    output wire  adc_sclk,
    output wire _adc_cs,
    output wire  adc_mosi,
    input  wire  adc_miso,

    // Dac Control

    output wire         pdac_update,
    output wire  [13:0] pdac_data,

    output wire         cdac_update,
    output wire  [13:0] cdac_data,

    // Pulse Control

    output wire [3:0] bx_delay,
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

    input  wire [31:0] thresholds_errcnt,
    output wire        thresholds_errcnt_rst,

    output wire        compout_expect,
    input  wire        compout_ff,
    input  wire [31:0] compout_errcnt,
    output wire        compout_errcnt_rst,
    output wire        compin_inject,

    // Comparator Config
    output wire [2:0] pktime,
    output wire [1:0] pkmode,
    output wire       lctrst,

    output wire [31:0] active_strip_mask,


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

    input  wire  _ft_rxf,
    input  wire  _ft_txe,
    input  wire   clk,
    input  wire  _ft_rd,
    input  wire  _ft_wr,

    output _ft_siwu,
    output  serial_wr,
    output  serial_rd,

    input   [7:0] ft_byte_out,
    output  [7:0] ft_byte_in
);
//------------------------------------------------------------------------------
// ADR_LOOPBACK=0x0
//------------------------------------------------------------------------------

parameter ADR_LOOPBACK=8'h0;

reg  [31:0] loopback_in = 32'h0;
wire [31:0] loopback_out = loopback_in;

//------------------------------------------------------------------------------
// ADR_COMP_CONFIG=0x1
//------------------------------------------------------------------------------

parameter ADR_COMP_CONFIG=8'h1;
// Write

reg [31:0] comp_config_in = 32'h0;

assign  pktime[0] = comp_config_in[0];
assign  pktime[1] = comp_config_in[1];
assign  pktime[2] = comp_config_in[2];

assign  pkmode[0] = comp_config_in[3];
assign  pkmode[1] = comp_config_in[4];

assign  lctrst    = comp_config_in[5];


// Read

wire [31:0] comp_config_out;
assign comp_config_out[31:0] = comp_config_in [31:0];

//------------------------------------------------------------------------------
// ADR_FIRE_PULSE=0xD
//------------------------------------------------------------------------------

parameter ADR_FIRE_PULSE = 8'hD;
reg  [31:0] fire_pulse_in = 32'b0;
wire [31:0] fire_pulse_out = fire_pulse_in;

assign  fire_pulse              = fire_pulse_in[0];
assign  halfstrips_errcnt_rst   = fire_pulse_in[1];
assign  compout_errcnt_rst      = fire_pulse_in[2];
assign  thresholds_errcnt_rst   = fire_pulse_in[3];

//------------------------------------------------------------------------------
// ADR_DAC=0xD
//------------------------------------------------------------------------------

parameter ADR_DAC = 8'hD;
reg[31:0] dac_in = 32'b0;

assign pdac     = dac_in[0];
assign pdac_data[13:0] = dac_in[14:1];
assign cdac     = dac_in[15];
assign cdac_data[13:0] = dac_in[29:16];

wire [31:0] dac_out = dac_in; // write only

////------------------------------------------------------------------------------
//// ADR_DAC=0xD1
////------------------------------------------------------------------------------
//
//initial
//begin
//dac_in[0]            = 1'b1; // _pulsedac_en
//dac_in[1]            = 1'b0; //  pulsedac_din
//dac_in[2]            = 1'b0; // _pulsedac_sclk
//
//dac_in[3]            = 1'b1; // _cdac_en
//dac_in[4]            = 1'b0; //  cdac_din
//dac_in[5]            = 1'b0; // _cdac_sclk
//end
//
//assign _pdac_en                 = dac_in[0];
//assign  pdac_din                = dac_in[1];
//assign  pdac_sclk               = dac_in[2];
//
//assign _cdac_en   = dac_in[3];
//assign  cdac_din  = dac_in[4];
//assign  cdac_sclk = dac_in[5];
//
//wire [31:0] dac_out = dac_in;

//------------------------------------------------------------------------------
// ADR_PULSE_CTRL=0x02
//------------------------------------------------------------------------------
parameter ADR_PULSE_CTRL = 8'h2;

// Write
reg [31:0] pulse_ctrl_in;

initial
begin
    pulse_ctrl_in[0]            = 1'b0; //  fire_pulse

    pulse_ctrl_in[1]            = 1'b0; //  pulse_width [0]
    pulse_ctrl_in[2]            = 1'b0; //  pulse_width [1]
    pulse_ctrl_in[3]            = 1'b0; //  pulse_width [2]
    pulse_ctrl_in[4]            = 1'b0; //  pulse_width [3]

    pulse_ctrl_in[5]            = 1'b1;
    pulse_ctrl_in[6]            = 1'b0;
    pulse_ctrl_in[7]            = 1'b0;

    pulse_ctrl_in[8]            = 1'b0;
    pulse_ctrl_in[9]            = 1'b0;
    pulse_ctrl_in[10]           = 1'b0; //  compin_inject

    pulse_ctrl_in[11]           = 1'b0; //  bx_delay [0]
    pulse_ctrl_in[12]           = 1'b0; //  bx_delay [1]
    pulse_ctrl_in[13]           = 1'b0; //  bx_delay [2]
    pulse_ctrl_in[14]           = 1'b0; //  bx_delay [3]


    pulse_ctrl_in[15]           = 1'b0; // compout_expect


    pulse_ctrl_in[19:16]        = 1'b0; // triad_persist
    pulse_ctrl_in[20]           = 1'b0; // triad_persist1

    pulse_ctrl_in[31:21]        = 0;
end

assign  pulse_width             = pulse_ctrl_in[4:1];
assign  compin_inject           = pulse_ctrl_in[10];



assign  bx_delay[0]             = pulse_ctrl_in[11];
assign  bx_delay[1]             = pulse_ctrl_in[12];
assign  bx_delay[2]             = pulse_ctrl_in[13];
assign  bx_delay[3]             = pulse_ctrl_in[14];

assign  compout_expect           = pulse_ctrl_in[14];

assign  triad_persist            = pulse_ctrl_in [18:15];
assign  triad_persist1           = pulse_ctrl_in [19];

// Read
wire [31:0] pulse_ctrl_out;
assign pulse_ctrl_out [19:0]  = pulse_ctrl_in[19:0];
assign pulse_ctrl_out [20]    = compout_ff;
assign pulse_ctrl_out [21]    = pulser_ready;
assign pulse_ctrl_out [31:22] = pulse_ctrl_in[31:22];

//------------------------------------------------------------------------------
// ADR_MUX1=0x03
//------------------------------------------------------------------------------
parameter ADR_MUX1 = 8'h3;

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
parameter ADR_MUX2 = 8'h04;

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

parameter ADR_HALFSTRIPS=4'h5;

wire [31:0] halfstrips_out;
assign halfstrips_out [31:0] = halfstrips [31:0];

//------------------------------------------------------------------------------
// ADR_HALFSTRIPS_EXPECT=0x06
//------------------------------------------------------------------------------

parameter ADR_HALFSTRIPS_EXPECT=4'h06;

reg  [31:0] halfstrips_expect_in = 32'b0;
wire [31:0] halfstrips_expect_out;

assign halfstrips_expect     [31:0] = halfstrips_expect_in [31:0];
assign halfstrips_expect_out [31:0] = halfstrips_expect    [31:0];

//------------------------------------------------------------------------------
// ADR_ACTIVE_STRIP_MASK=0xC
//------------------------------------------------------------------------------

parameter ADR_ACTIVE_STRIP_MASK = 4'hC;

reg  [31:0] active_strip_mask_in = 32'b0;
wire [31:0] active_strip_mask_out;

assign active_strip_mask     [31:0] = active_strip_mask_in [31:0];
assign active_strip_mask_out [31:0] = active_strip_mask    [31:0];

//------------------------------------------------------------------------------
// ADR_HALFSTRIPS_ERRCNT=0x7
//------------------------------------------------------------------------------

parameter ADR_HALFSTRIPS_ERRCNT=4'h7;

wire [31:0] halfstrips_errcnt_out;
assign halfstrips_errcnt_out [31:0] = halfstrips_errcnt [31:0];

//------------------------------------------------------------------------------
// ADR_COMPOUT_ERRCNT=0xA
//------------------------------------------------------------------------------

parameter ADR_COMPOUT_ERRCNT = 4'hA;
wire [31:0] compout_errcnt_out;
assign compout_errcnt_out [31:0] = compout_errcnt [31:0];

//------------------------------------------------------------------------------
// ADR_THRESHOLDS_ERRCNT=0xB
//------------------------------------------------------------------------------

parameter ADR_THRESHOLDS_ERRCNT = 4'hB;
wire [31:0] thresholds_errcnt_out;
assign thresholds_errcnt_out [31:0] = thresholds_errcnt [31:0];

//------------------------------------------------------------------------------
// ADR_ADC=0x08
//------------------------------------------------------------------------------

parameter ADR_ADC = 4'h08;

// Write
reg  [31:0] adc_in = 32'b0;

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

reg adc_miso_ff = 0;
always @ (negedge adc_sclk)
begin
    adc_miso_ff <= adc_miso;
end

assign adc_out[0] = _adc_cs;       // W/R
assign adc_out[1] =  adc_mosi;     // W/R
assign adc_out[2] =  adc_sclk;     // W/R
assign adc_out[3] =  adc_miso_ff;  // R

assign adc_out[31:4]  =  adc_in[31:4];    // Unused

//------------------------------------------------------------------------------
// ADR_DDD=0x9
//------------------------------------------------------------------------------
parameter ADR_DDD = 4'h9;

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

parameter PC_READ_CMD  = 8'hAA;
parameter PC_WRITE_CMD = 8'h55;

reg  [31:0] dword_out = 0;
reg  [31:0] dword_in  = 0;

reg [3:0] serial_state = 4'h0;

parameter idle    = 4'h0;
parameter command = 4'h1;
parameter address = 4'h2;
parameter read0   = 4'h3;
parameter read1   = 4'h4;
parameter read2   = 4'h5;
parameter read3   = 4'h6;
parameter write0  = 4'h7;
parameter write1  = 4'h8;
parameter write2  = 4'h9;
parameter write3  = 4'hA;

wire rx_data =  (cmd==PC_WRITE_CMD) // Data from PC
wire tx_data  = (cmd==PC_READ_CMD) // Data to PC

wire data_available = !(_ft_rxf);
wire can_read       = (!_ft_rxf && !_ft_rd);
wire can_write      = (!_ft_txe && !_ft_wr);

wire serial_wr = (serial_state==write1 || serial_state==write2 || serial_state==write3 || serial_state==write4);
wire serial_rd = (serial_state==idle || serial_state==address || serial_state==command || serial_state==read1 || serial_state==read2 || serial_state==read3 || serial_state==rd4);

wire update_serial <= (serial_state==idle);

reg cmd_ff = 0;
reg adr_ff = 0;
always @ (posedge clk)  begin
    cmd_ff <= (serial_state==command) ? ft_byte_out[7:0] : cmd_ff;
    adr_ff <= (serial_state==address) ? ft_byte_out[7:0] : adr_ff;
end

wire cmd = (serial_state==command) ? ft_byte_out[7:0] : cmd_ff;
wire adr = (serial_state==address) ? ft_byte_out[7:0] : adr_ff;

wire adr_valid = (adr<MXADR) && (adr>MNADR);

reg [7:0] readchar_0, readchar_1, readchar_2, readchar_3;
always @ (posedge clk) begin
    // latch previous chars to pack into data word
    readchar_0 <= (serial_state==read0) ? ft_byte_out[7:0] : readchar_0;
    readchar_1 <= (serial_state==read1) ? ft_byte_out[7:0] : readchar_1;
    readchar_2 <= (serial_state==read2) ? ft_byte_out[7:0] : readchar_2;

    dword_in [31:0] <= (serial_state==read3) ? (ft_byte_out[7:0], readchar_2, readchar_1, readchar_0) : dword_in[31:0];
end

assign ft_byte_in = (serial_state==read0) ? (dword_out[7:0] :
                    (serial_state==read1) ? (dword_out[15:8] :
                    (serial_state==read2) ? (dword_out[23:16] :
                    (serial_state==read2) ? (dword_out[31:24];

always @ (posedge clk)
begin
    case (serial_state)
        idle    : serial_state <= (data_available) ? address : idle;
        address : serial_state <= (adr_valid)      ? command : address;
        command : serial_state <= (tx_data)        ? write0  : (rx_data) ? read0 : idle;

        read0:   serial_state <= read1; /* Read (from PC) */
        read1:   serial_state <= read2;
        read2:   serial_state <= read3;
        read3:   serial_state <= idle;

        write0:  serial_state <= write1; /* Write (to PC)*/
        write1:  serial_state <= write2;
        write2:  serial_state <= write3;
        write3:  serial_state <= write4;

        siwu:    serial_state <= (siwu_counter[4]) ? idle : siwu;
        default: serial_state <= idle;
    endcase
end

reg [4:0] siwu_counter=0;
always @(posedge clock) begin
    siwu_counter <= (serial_state==siwu) ? siwu_counter+1 : 0;
end

assign _ft_siwu <= !(serial_state = siwu);

/* Out to PC */
always @(*)
begin
    case(adr)
        ADR_LOOPBACK:            dword_out  = loopback_out;
        ADR_COMP_CONFIG:         dword_out  = comp_config_out;
        ADR_PULSE_CTRL:          dword_out  = pulse_ctrl_out;
        ADR_FIRE_PULSE:          dword_out  = fire_pulse_out;
        ADR_MUX1:                dword_out  = mux1_out;
        ADR_MUX2:                dword_out  = mux2_out;
        ADR_HALFSTRIPS:          dword_out  = halfstrips_out;
        ADR_HALFSTRIPS_EXPECT:   dword_out  = halfstrips_expect_out;
        ADR_HALFSTRIPS_ERRCNT:   dword_out  = halfstrips_errcnt_out;
    		ADR_THRESHOLDS_ERRCNT:   dword_out  = thresholds_errcnt_out;
        ADR_COMPOUT_ERRCNT:      dword_out  = compout_errcnt_out;
        ADR_ADC:                 dword_out  = adc_out;
        ADR_DDD:                 dword_out  = ddd_out;
        ADR_DAC:                 dword_out  = dac_out;
        ADR_ACTIVE_STRIP_MASK:   dword_out  = active_strip_mask_out;
        default:                 dword_out  = 32'hDEADBEEF;
    endcase
end

/* In from PC */

wire wr_loopback          = (adr==ADR_LOOPBACK)          && (update_serial);
wire wr_comp_config       = (adr==ADR_COMP_CONFIG)       && (update_serial);
wire wr_pulse_ctrl        = (adr==ADR_PULSE_CTRL)        && (update_serial);
wire wr_mux1              = (adr==ADR_MUX1)              && (update_serial);
wire wr_mux2              = (adr==ADR_MUX2)              && (update_serial);
wire wr_halfstrips_expect = (adr==ADR_HALFSTRIPS_EXPECT) && (update_serial);
wire wr_adc               = (adr==ADR_ADC)               && (update_serial);
wire wr_ddd               = (adr==ADR_DDD)               && (update_serial);
wire wr_active_strip_mask = (adr==ADR_ACTIVE_STRIP_MASK) && (update_serial);
wire wr_dac               = (adr==ADR_DAC              ) && (update_serial);
wire wr_fire_pulse        = (adr==ADR_FIRE_PULSE)        && (update_serial);

always @ (posedge clk)
begin
    if (wr_loopback)          loopback_in          <= dword_in;
    if (wr_comp_config)       comp_config_in       <= dword_in;
    if (wr_pulse_ctrl)        pulse_ctrl_in        <= dword_in;
    if (wr_fire_pulse)        fire_pulse_in        <= dword_in;
    if (wr_mux1)              mux1_in              <= dword_in;
    if (wr_mux2)              mux2_in              <= dword_in;
    if (wr_halfstrips_expect) halfstrips_expect_in <= dword_in;
    if (wr_adc)               adc_in               <= dword_in;
    if (wr_ddd)               ddd_in               <= dword_in;
    if (wr_active_strip_mask) active_strip_mask_in <= dword_in;
    if (wr_dac)               dac_in               <= dword_in;
end

//----------------------------------------------------------------------------------------------------------------------
endmodule
//----------------------------------------------------------------------------------------------------------------------
