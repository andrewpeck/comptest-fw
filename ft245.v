`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    16:34:09 12/04/2014
// Design Name:
// Module Name:    ft245
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

module ft245(
    input clk,

    // When high, do not write data into the FIFO. When low, data
    // can be written into the FIFO by driving WR# low. When in
    // synchronous mode, data is transferred on every clock that
    // TXE# and WR# are both low.
    input _txe,             // Can TX

    // When high, do not read data from the FIFO. When low, there
    // is data available in the FIFO which can be read by driving RD#
    // low. When in synchronous mode, data is transferred on every
    // clock that RXF# and RD# are both low. Note that the OE# pin
    // must be driven low at least 1 clock period before asserting
    // RD# low.
    input _rxf,             // Can RX

    // Enables the current FIFO data byte to be driven onto D0...D7
    // when RD# goes low. The next FIFO data byte (if available) is
    // fetched from the receive FIFO buffer each CLKOUT cycle until
    // RD# goes high.
    output reg _rd,         // Read -- low to be able to read

    // Enables the data byte on the D0...D7 pins to be written into
    // the transmit FIFO buffer when WR# is low. The next FIFO data
    // byte is written to the transmit FIFO buffer each CLKOUT cycle
    // until WR# goes high.
    output reg _wr,         // FIFO Buffer Write Enable, low to write to usb

    // Output enable when low to drive data onto D0-7. This should
    // be driven low at least 1 clock period before driving RD# low to
    // allow for data buffer turn-around.
    output reg _oe,              // Output enable, high to write to USB

    input      _reset,           // low for reset

    inout [7:0] data,   // Bidirectional FIFO data




    input   data_av,            // put low if you want to write data
    input   read_data,          // put high if you want to read data

    input   [7:0]     data_in,  // Input Register Buffer
    output  reg [7:0] data_out      // Output Register Buffer
);


//assign _rd = _rd;
//assign _wr = _wr;
//assign _oe = _oe;
//assign _reset = _reset;
//assign  data [7:0] = data[7:0]
//assign  data_av = data_av;
//assign  read_data = read_data;
//assign  data_in [7:0] = _data_in [7:0];
//assign  data_out [7:0] = _data_out [7:0];

// data Should Float When TXE# is high
assign data = (_txe) ? data_out : 'bz;

parameter [2:0]
Idle         = 0,
Next_isWrite = 1,
Write        = 2,
Next_isRead  = 3,
Read         = 4;

reg [2:0] state;
reg [2:0] next_state;

// Combinatorial Block
always @(*) begin
    case(state)
        Idle :
        begin
            if (data_av  ==1 && _txe==0) 
                next_state <= Next_isWrite;
            else if (read_data==1 && _rxf==0) 
                next_state <= Next_isRead;
            else 
                next_state <= Idle;
        end

        Next_isWrite :
        begin
            next_state <= Write;
        end

        Write :
        begin
            if (data_av==1 && _txe==0 && read_data==0) 
                next_state <= Write;
            else 
                next_state <= Idle;
        end

        Next_isRead :
        begin
            next_state <= Read;
        end

        Read :
        begin
            // put here a mode to stay in read mode if more data is available ?
            next_state <= Idle;
        end

        default :
        begin
            next_state <= Idle;
        end
    endcase
end

// Sequential Block
always @(posedge clk or negedge _reset) begin
    if (_reset == 0)
        state <= Idle;
    else
    begin
        state <= next_state;
        //data <= data_in;
    end
end

//Sequential Output Block
always @(*) begin
    case(state)
        Idle :
        begin
            _rd <= 1;
            _oe <= 1;
            _wr <= 1;
        end

        Next_isWrite :
        begin
            _rd <= 1;
            _oe <= 1;
            _wr <= 1;
        end

        Write :
        begin
            //data = data_in;
            _rd <= 1;
            _oe <= 1;
            if (_txe==0 && data_av==1)
                _wr <= 0; // the wr low can be used to trigger that the next byte is load into data_in
            else
                _wr <= 1;
        end

        Next_isRead :
        begin
            _rd <= 1;
            _oe <= 0;
            _wr <= 1;
        end

        Read :
        begin
            data_out <= data;
            _oe <= 0;
            _wr <= 1;
            if (_rxf == 0)
                _rd <= 0;
            else
                _rd <= 1;
        end

    endcase
end
endmodule

