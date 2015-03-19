`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    09:11:57 12/18/2014
// Design Name:
// Module Name:    serial
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
///////////////////////////////////////////////////////////////////////////////

module serial(
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
    input  wire compout,
    output wire compin,
    output wire lctclk,
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

    input wire clock40,

    input  wire _ft_reset,
    output wire _ft_oe,
    input  wire _ft_txe,
    input  wire _ft_rxf,
    input  wire  ft_clk,
    output wire _ft_wr,
    output wire _ft_siwu,
    output wire _ft_rd,

    inout[7:0] ft_data
);

//------------------------------------------------------------------------------
// ADR_COMP_CONFIG=0x01
//------------------------------------------------------------------------------

parameter ADR_COMP_CONFIG=2'h01;
// Write

reg [31:0] comp_config_wr;

initial
begin
    comp_config_wr [31:0] = 0;
end

assign  pktime[0] = comp_config_wr[0];
assign  pktime[1] = comp_config_wr[1];
assign  pktime[2] = comp_config_wr[2];

assign  pkmode[0] = comp_config_wr[3];
assign  pkmode[1] = comp_config_wr[4];

assign  lctrst    = comp_config_wr[5];

assign _cdac_en   = comp_config_wr[6];
assign  cdac_din  = comp_config_wr[7];
assign  cdac_sclk = comp_config_wr[8];

// Read

wire [31:0] comp_config_rd;
assign comp_config_rd[31:0] = comp_config_wr [31:0];

//------------------------------------------------------------------------------
// ADR_PULSE_CTRL=0x02
//------------------------------------------------------------------------------
parameter ADR_PULSE_CTRL = 2'h02;

// Write
reg [31:0] pulse_ctrl_wr;

initial
begin
    pulse_ctrl_wr[0]            = 1'b0; //  fire_pulse

    pulse_ctrl_wr[1]            = 1'b0; //  pulse_width [0]
    pulse_ctrl_wr[2]            = 1'b0; //  pulse_width [1]
    pulse_ctrl_wr[3]            = 1'b0; //  pulse_width [2]
    pulse_ctrl_wr[4]            = 1'b0; //  pulse_width [3]

    pulse_ctrl_wr[5]            = 1'b1; // _pulsedac_en
    pulse_ctrl_wr[6]            = 1'b0; //  pulsedac_din
    pulse_ctrl_wr[7]            = 1'b0; // _pulsedac_sclk

    pulse_ctrl_wr[8]            = 1'b0; //  halfstrips_errcnt_rst
    pulse_ctrl_wr[9]            = 1'b0; //  compout_errcnt_rst
    pulse_ctrl_wr[10]           = 1'b0; //  compin_inject

    pulse_ctrl_wr[11]           = 1'b0; //  bx_delay [0]
    pulse_ctrl_wr[12]           = 1'b0; //  bx_delay [1]
    pulse_ctrl_wr[13]           = 1'b0; //  bx_delay [2]

    pulse_ctrl_wr[14]           = 1'b0; // compout_expect

    pulse_ctrl_wr[31:14]        = 0;
end

assign  fire_pulse              = pulse_ctrl_wr[0];
assign  pulse_width             = pulse_ctrl_wr[4:1];

assign _pdac_en                 = pulse_ctrl_wr[5];
assign  pdac_din                = pulse_ctrl_wr[6];
assign  pdac_sclk               = pulse_ctrl_wr[7];

assign  halfstrips_errcnt_rst   = pulse_ctrl_wr[8];
assign  compout_errcnt_rst      = pulse_ctrl_wr[9];
assign  compin_inject           = pulse_ctrl_wr[10];

assign  bx_delay[0]             = pulse_ctrl_wr[11];
assign  bx_delay[1]             = pulse_ctrl_wr[12];
assign  bx_delay[2]             = pulse_ctrl_wr[13];

assign compout_expect           = pulse_ctrl_wr[14];

// Read
wire [31:0] pulse_ctrl_rd;
assign pulse_ctrl_rd [13:0]  = pulse_ctrl_wr[13:0];
assign pulse_ctrl_rd [14]    = pulser_ready;
assign pulse_ctrl_rd [31:15] = pulse_ctrl_wr[31:15];

//------------------------------------------------------------------------------
// ADR_MUX1=0x03
//------------------------------------------------------------------------------
parameter ADR_MUX1 = 2'h03;

// Write

reg [31:0] mux1_wr;

initial
begin
    mux1_wr[31:0] = 0;
end

assign  mux_a0_prev  = mux1_wr[0];
assign  mux_a1_prev  = mux1_wr[1];

assign  mux_a0_next  = mux1_wr[2];
assign  mux_a1_next  = mux1_wr[3];

//Read

wire [31:0] mux1_rd;
assign mux1_rd[31:0] = mux1_wr[31:0];  // All bits are R/W

//------------------------------------------------------------------------------
// ADR_MUX2=0x04
//------------------------------------------------------------------------------
parameter ADR_MUX2 = 2'h04;

// Write

reg [31:0] mux2_wr;

initial
begin
    mux2_wr[31:0] = 0;
end

assign mux_a0[0]   = mux2_wr[0];     // Mux 0 bit 0
assign mux_a1[0]   = mux2_wr[1];     // Mux 0 bit 1
assign mux_a0[1]   = mux2_wr[2];     // Mux 1 bit 0
assign mux_a1[1]   = mux2_wr[3];     // Mux 1 bit 1
assign mux_a0[2]   = mux2_wr[4];     // ...
assign mux_a1[2]   = mux2_wr[5];     // etc
assign mux_a0[3]   = mux2_wr[6];
assign mux_a1[3]   = mux2_wr[7];
assign mux_a0[4]   = mux2_wr[8];
assign mux_a1[4]   = mux2_wr[9];
assign mux_a0[5]   = mux2_wr[10];
assign mux_a1[5]   = mux2_wr[11];
assign mux_a0[6]   = mux2_wr[12];
assign mux_a1[6]   = mux2_wr[13];
assign mux_a0[7]   = mux2_wr[14];
assign mux_a1[7]   = mux2_wr[15];
assign mux_a0[8]   = mux2_wr[16];
assign mux_a1[8]   = mux2_wr[17];
assign mux_a0[9]   = mux2_wr[18];
assign mux_a1[9]   = mux2_wr[19];
assign mux_a0[10]  = mux2_wr[20];
assign mux_a1[10]  = mux2_wr[21];
assign mux_a0[11]  = mux2_wr[22];
assign mux_a1[11]  = mux2_wr[23];
assign mux_a0[12]  = mux2_wr[24];
assign mux_a1[12]  = mux2_wr[25];
assign mux_a0[13]  = mux2_wr[26];
assign mux_a1[13]  = mux2_wr[27];
assign mux_a0[14]  = mux2_wr[28];
assign mux_a1[14]  = mux2_wr[29];
assign mux_a0[15]  = mux2_wr[30];
assign mux_a1[15]  = mux2_wr[31];

// Read

wire [31:0] mux2_rd;
assign mux2_rd[31:0] = mux2_wr[31:0];  // All bits are R/W

//------------------------------------------------------------------------------
// ADR_HALFSTRIPS=0x05
//------------------------------------------------------------------------------

parameter ADR_HALFSTRIPS=2'h05;

wire [31:0] halfstrips_rd;
assign halfstrips_rd [31:0] = halfstrips [31:0];

//------------------------------------------------------------------------------
// ADR_HALFSTRIPS_EXPECT=0x06
//------------------------------------------------------------------------------

parameter ADR_HALFSTRIPS_EXPECT=2'h06;

reg [31:0] halfstrips_expect_wr;
initial
begin
    halfstrips_expect_wr = 32'b0;
end

wire [31:0] halfstrips_expect_rd;
assign halfstrips_expect_rd [31:0] = halfstrips_expect_wr [31:0];

//------------------------------------------------------------------------------
// ADR_HALFSTRIPS_ERRCNT=0x07
//------------------------------------------------------------------------------

parameter ADR_HALFSTRIPS_ERRCNT=2'h07;

wire [31:0] halfstrips_errcnt_rd;
assign halfstrips_errcnt_rd [31:0] = halfstrips_errcnt [31:0];

//------------------------------------------------------------------------------
// ADR_ADC=0x08
//------------------------------------------------------------------------------

parameter ADR_ADC = 2'h08;

// Write
reg  [31:0] adc_wr;

initial
begin
    adc_wr[0]           = 1'b0; //  adc_sclk
    adc_wr[1]           = 1'b0; //  adc_mosi
    adc_wr[2]           = 1'b1; // _adc_cs
    adc_wr[31:3]        = 0;
end

assign _adc_cs     = adc_wr[0];
assign  adc_mosi   = adc_wr[1];
assign  adc_sclk   = adc_wr[2];

// Read

wire [31:0] adc_rd;

assign adc_rd[0]  = _adc_cs;       // W/R
assign adc_rd[1]  =  adc_mosi;     // W/R
assign adc_rd[2]  =  adc_sclk;     // W/R
assign adc_rd[3]  =  adc_miso;     // R

assign adc_rd[31:4]  =  adc_wr[31:4];    // Unused

//------------------------------------------------------------------------------
// ADR_DDD=0x09
//------------------------------------------------------------------------------
parameter ADR_DDD = 2'h09;

// Write

reg  [31:0] ddd_wr;

initial begin
    ddd_wr[0]             = 0; // ddd serial clock
    ddd_wr[1]             = 0; // ddd serial out
    ddd_wr[2]             = 1; // ddd adr latch (active low)
end

assign  _ddd_al  = ddd_wr[0];    // Adr Latch (Active Low)
assign  ddd_mosi = ddd_wr[1];    // Serial In
assign  ddd_sclk = ddd_wr[2];    // Serial Clock

// Read

wire [31:0] ddd_rd;

assign ddd_rd[0]   = _ddd_al;    // R/W Addr Latch
assign ddd_rd[1]   =  ddd_mosi;         // R/W Serial Data In
assign ddd_rd[2]   =  ddd_sclk;       // R/W Clock
assign ddd_rd[3]   =  ddd_miso;
assign ddd_rd[31:4] = ddd_wr [31:4];


//------------------------------------------------------------------------------
// FTDI 245H Serial-USB Interface Control
//------------------------------------------------------------------------------

//reg [7:0] ft_data;
wire [7:0] ft_data_out;
reg [7:0] ft_data_in;

reg   serial_wr;
reg   serial_rd;
//wire _ft_txe;
//wire _ft_rxf;
//wire _ft_siwu;
//wire _ft_oe;
//wire _ft_wr;
//wire _ft_reset;
//wire _ft_rd;

ft245 u_ft245 (
    .clk(ft_clk),            // 60 MHz FT232H clock

    ._txe(_ft_txe),          // Can TX
    ._rxf(_ft_rxf),          // Can RX

    ._rd(_ft_rd),            // Read -- low to be able to read
    ._wr(_ft_wr),            // FIFO Buffer Write Enable, low to write to usb

    ._oe(_ft_oe),            // Output enable, high to write to USB
    ._reset(_ft_reset),       // FTDI Reset, active low

    .data(ft_data),          // Bidirectional FIFO data

    .data_av(serial_wr),     // put low if you want to write data
    .read_data(serial_rd),   // put high if you want to read data

    .data_in(ft_data_in),    // data to be written
    .data_out(ft_data_out)   // data to be read out
);

//------------------------------------------------------------------------------
// Readout of FTDI Chip
//------------------------------------------------------------------------------


parameter READ_CMD  = 8'hAA;
parameter WRITE_CMD = 8'h55;

reg[31:0] data_to_write;
reg[3:0] ibyte;

reg[3:0] cmd;
reg[3:0] adr;

reg[31:0] data_rd_buf;
reg[31:0] data_rd;


initial
begin
    ibyte       = 0;
    cmd         = 0;
    //cmd_buf     = 0;
    adr         = 0;
    //adr_buf     = 0;
    data_rd_buf = 0;
    data_rd     = 0;
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
reg [4:0] state; 
initial 
begin
    state = 4'h0; 
end

// uint8 -> uint32
always @(posedge ft_clk) begin
    if (_ft_reset) state <= idle; 
    else begin
        case (state)
            idle: if(!_ft_rxf) begin
                cmd <= ft_data_out[3:0]; 
                adr <= ft_data_out[7:0]; 
                if (ft_data_out[3:0]==READ_CMD) 
                    state <= rd1; 
                else if (ft_data_out[3:0]==WRITE_CMD) 
                    state <= wr1; 
                else 
                    state <= idle; 
            end

            rd1: if (!_ft_rxf) state <= rd2; 
            rd2: if (!_ft_rxf) state <= rd3; 
            rd3: if (!_ft_rxf) state <= rd4; 
            rd4: if (!_ft_rxf) state <= idle; 

            wr1: if (!_ft_txe) state <= wr2; 
            wr2: if (!_ft_txe) state <= wr3; 
            wr3: if (!_ft_txe) state <= wr4; 
            wr4: if (!_ft_txe) state <= idle; 

            default: state <= idle; 

        endcase
    end
end

always @(*)
begin
    case (state)
        rd1: 
        begin
            serial_wr  <= 0; 
            serial_rd  <= 1; 
            ft_data_in <= data_to_write[7:0];
        end
        rd2: ft_data_in <= data_to_write[15:8];
        rd3: ft_data_in <= data_to_write[23:16];
        rd4: ft_data_in <= data_to_write[31:24];

        wr1: 
        begin
            serial_wr  <= 1; 
            serial_rd  <= 0; 
            data_rd_buf[7:0]   <= ft_data_out;
        end
        wr2: data_rd_buf[15:8]  <= ft_data_out;
        wr3: data_rd_buf[23:16] <= ft_data_out;
        wr4: 
        begin 
            data_rd_buf[31:23] <= ft_data_out;
            data_rd <= data_rd_buf;
        end
    endcase
end

always @(*)
begin
    case(adr)
        ADR_COMP_CONFIG:         data_to_write  <= comp_config_rd;
        ADR_PULSE_CTRL:          data_to_write  <= pulse_ctrl_rd;
        ADR_MUX1:                data_to_write  <= mux1_rd;
        ADR_MUX2:                data_to_write  <= mux2_rd;
        ADR_HALFSTRIPS:          data_to_write  <= halfstrips_rd;
        ADR_HALFSTRIPS_EXPECT:   data_to_write  <= halfstrips_expect_rd;
        ADR_HALFSTRIPS_ERRCNT:   data_to_write  <= halfstrips_errcnt_rd;
        ADR_ADC:                 data_to_write  <= adc_rd;
        ADR_DDD:                 data_to_write  <= ddd_rd;
    endcase
end

wire wr_comp_config;
wire wr_pulse_ctrl;
wire wr_mux1;
wire wr_mux2;
wire wr_halfstrips_expect;
wire wr_adc;
wire wr_ddd;

assign wr_comp_config       = (adr==ADR_COMP_CONFIG);
assign wr_pulse_ctrl        = (adr==ADR_PULSE_CTRL);
assign wr_mux1              = (adr==ADR_MUX1);
assign wr_mux2              = (adr==ADR_MUX2);
assign wr_halfstrips_expect = (adr==ADR_HALFSTRIPS_EXPECT);
assign wr_adc               = (adr==ADR_ADC);
assign wr_ddd               = (adr==ADR_DDD);

always @ (*) begin
    if (wr_comp_config      ) comp_config_wr       <= data_rd;
    if (wr_pulse_ctrl       ) pulse_ctrl_wr        <= data_rd;
    if (wr_mux1             ) mux1_wr              <= data_rd;
    if (wr_mux2             ) mux2_wr              <= data_rd;
    if (wr_halfstrips_expect) halfstrips_expect_wr <= data_rd;
    if (wr_adc              ) adc_wr               <= data_rd;
    if (wr_ddd              ) ddd_wr               <= data_rd;
end

endmodule


//parameter [2:0]
//ALIGNED = 0,
//BYTE1   = 1,
//BYTE2   = 2,
//BYTE3   = 3,
//BYTE4   = 4,
//
//reg[7:0] byte;
//
//always @ (posedge ft_clk)
//begin
//    state <= next_state;
//end
//
//always @ (....)
//begin
//end
//
//always @ (posedge ft_clk)
//begin
//    byte = ft_data_out;
//    case (state)
//        IDLE:
//
//        READ_HEADER:
//        begin
//            cmd <= byte[3:0];
//            adr <= byte[7:4];
//            if (cmd==READ_CMD)
//                next_state = READ_DATA1;
//            else if (cmd==WRITE_CMD)
//                next_state = WRITE_DATA1;
//        end
//
//        READ_DATA1:
//        begin
//            data_rd_buf[7:0]   <= ft_data_out;
//            next_state = READ_DATA2;
//        end
//
//        READ_DATA2:
//        begin
//            data_rd_buf[15:8]  <= ft_data_out;
//            next_state = READ_DATA3;
//        end
//
//        READ_DATA3:
//        begin
//            data_rd_buf[23:16] <= ft_data_out;
//            next_state = READ_DATA4;
//        end
//
//        READ_DATA4:
//        begin
//            data_rd_buf[31:23] <= ft_data_out;
//            next_state = WAIT;
//        end
//
//        READ_DATA1:
//        begin
//            data_rd_buf[7:0]   <= ft_data_out;
//            next_state = READ_DATA2;
//        end
//
//        READ_DATA2:
//        begin
//            data_rd_buf[15:8]  <= ft_data_out;
//            next_state = READ_DATA3;
//        end
//
//        READ_DATA3:
//        begin
//            data_rd_buf[23:16] <= ft_data_out;
//            next_state = READ_DATA4;
//        end
//
//        READ_DATA4:
//        begin
//            data_rd_buf[31:23] <= ft_data_out;
//            next_state = WAIT;
//        end
//
//
//end

//// Read Serial Data from FT Chip and Update Register
//always @ (posedge ft_clk)
//begin
//    if (ibyte==0 && !_ft_rxf)
//    begin
//        serial_rd = 1'b1;
//        cmd <= ft_data_out[3:0];
//        adr <= ft_data_out[7:4];
//        if (ft_data_out[3:0]==READ_CMD | ft_data_out[3:0]==WRITE_CMD)
//        begin
//            ibyte <= ibyte + 1;
//            serial_rd <= 0;
//        end
//    end
//    else if (cmd == READ_CMD && !_ft_rxf)
//    begin
//        serial_wr <= 0;
//        serial_rd <= 1'b1;
//        case (ibyte)
//            1: data_rd_buf[7:0]   <= ft_data_out;
//            2: data_rd_buf[15:8]  <= ft_data_out;
//            3: data_rd_buf[23:16] <= ft_data_out;
//            4:
//            begin
//                data_rd_buf[31:23] <= ft_data_out;
//                data_rd <= data_rd_buf;
//            end
//        endcase
//        ibyte <= ibyte+1;
//    end
//    else if (cmd == WRITE_CMD && !_ft_txe)
//    begin
//        serial_wr <= 1;
//        case (ibyte)
//            1: ft_data_in <= data_to_write[7:0];
//            2: ft_data_in <= data_to_write[15:8];
//            3: ft_data_in <= data_to_write[23:16];
//            4: ft_data_in <= data_to_write[31:24];
//            5:
//            begin
//                serial_wr <= 0;
//                ibyte <= 0; 
//            end
//        endcase
//        ibyte <= ibyte+1;
//    end
//end
