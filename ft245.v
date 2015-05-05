`timescale 1ns / 1ps

module ft245
(
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
    output reg _oe,                // Output enable, high to write to USB

    input      _reset,             // low for reset

    inout [7:0] data,              // Bidirectional FIFO data

    input   _write_data,           // put low if you want to write data
    input   _read_data,            // put low if you want to read data

    input   [7:0]     data_to_pc,  // Input Register Buffer
    output  reg [7:0] data_to_fpga // Output Register Buffer
);

// data Should Float When TXE# is high
assign data = (!_txe) ? data_to_pc : 8'bz;

parameter [2:0]
Idle         = 3'h0,
Next_isWrite = 3'h1,
Write        = 3'h2,
Next_isRead  = 3'h3,
Read         = 3'h4;

reg [2:0] ftstate;
reg [2:0] next_ftstate;

// Combinatorial Block
always @(*) begin
    case(ftstate)
        Idle :
        begin
            if (_write_data==0 && _txe==0)
                next_ftstate <= Next_isWrite;
            else if (_read_data==0 && _rxf==0)
                next_ftstate <= Next_isRead;
            else
                next_ftstate <= Idle;
        end

        Next_isWrite:
            next_ftstate <= Write;

        Write:
            next_ftstate <= (_write_data==0 && _txe==0) ? Write : Idle;
            //next_ftstate <= (_write_data==0 && _txe==0 && _read_data==1) ? Write : Idle;

        Next_isRead:
            next_ftstate <= Read;

        Read:
            next_ftstate <= Idle;
            // put here a mode to stay in read mode if more data is available ?

        default:
            next_ftstate <= Idle;
    endcase
end

// Sequential Block
always @(posedge clk) begin
    if (_reset==0)
        ftstate <= Idle;
    else
        ftstate <= next_ftstate;
end

//Sequential Output Block
always @(posedge clk) begin
    case(ftstate)
        Idle :
        begin
            _rd <= 1'b1;
            _oe <= 1'b1;
            _wr <= 1'b1;
        end

        Next_isWrite :
        begin
            _rd <= 1'b1;
            _oe <= 1'b1;
            _wr <= 1'b1;
        end

        Write :
        begin
            _rd <= 1'b1;
            _oe <= 1'b1;
            _wr <= 1'b0; // (!_txe && _write_data) ? 1'b0 : 1'b1;
            // the wr low can be used to trigger that the next byte is load
            // into data_to_pc
        end

        Next_isRead :
        begin
            // We do this here since we need to drive OE# low at least one
            // clock period before driving RD# low.
            _rd <= 1'b1;
            _oe <= 1'b0;
            _wr <= 1'b1;
        end

        Read :
        begin
            data_to_fpga <= data;
            _oe <= 1'b0;
            _wr <= 1'b1;
            _rd <= 1'b0; //(!_rxf) ? 1'b0 : 1'b1;
        end

        default:
        begin
            _rd <= 1'b1;
            _oe <= 1'b1;
            _wr <= 1'b1;
            data_to_fpga <= 8'h00;
        end

    endcase
end
endmodule
