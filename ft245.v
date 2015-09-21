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

    //input      _reset,             // low for reset

    inout [7:0] data,              // Bidirectional FIFO data

    input   write_data,           // put high if you want to write data
    input   read_data,            // put high if you want to read data

    input       [7:0]     data_to_pc,  // Input Register Buffer
    output  reg [7:0]     data_to_fpga // Output Register Buffer
);

// data Should Float When writing out
assign data = (!_wr) ? data_to_pc : 8'bz;

initial
begin
    _oe               = 1'b1;
    _wr               = 1'b1;
    _rd               = 1'b1;
    data_to_fpga[7:0] = 8'hBA;
end

wire can_write_data = (write_data && !_txe);
wire can_read_data  = (read_data && !_rxf);

assign _wr = (ftstate==Write) ? 1'b0 : 1'b1;
assign _oe = (ftstage==Read)  ? 1'b0 : 1'b1;

always @(posedge clk) begin
    data_to_fpga <= (ft_state==Read) ? data : data_to_fpga;
end

parameter [2:0]
Idle         = 3'h0,
Write        = 3'h2,
Next_isRead  = 3'h3,
Read         = 3'h4;

reg [2:0] ftstate;

always @(posedge clk) begin
    case (ftstate)
        Idle:  ftstate <= can_read_data ? (Read) : (can_write_data ? Write : Idle);
        Write: ftstate <= (write_data) ? Write : Idle; // data_to_pc
        Read:  ftstate <= (read_data) ? Read : Idle;
    endcase
end

//----------------------------------------------------------------------------------------------------------------------
endmodule
//----------------------------------------------------------------------------------------------------------------------
