`timescale 1ns / 1ps

module comparator_injector(
    input [31:0] halfstrips,
    input [31:0] halfstrips_expect,

    output reg [31:0] halfstrips_errcnt,
    output reg [31:0] compout_errcnt,

    input compout,
    input compout_expect,
    output reg compout_last,

    input compout_errcnt_rst,
    input halfstrips_errcnt_rst,

    input compin_inject,
    output reg compin,

    input fire_pulse,
    output reg pulser_ready,

    input [2:0] bx_delay,
    input [3:0] pulse_width,

    output reg pulse_en,

    input clk
);

reg [3:0] bx = 3'h0;
reg [1:0] state = 2'h0;
reg [1:0] next_state = 32'h0;

parameter [2:0] idle     = 2'h0;
parameter [2:0] pulseon  = 2'h1;
parameter [2:0] pulseoff = 2'h2;
parameter [2:0] readout  = 2'h3;

always @(posedge clk)
begin
    if (halfstrips_errcnt_rst)
        halfstrips_errcnt <= 1'b0;

    if (compout_errcnt_rst)
        compout_errcnt <= 1'b0;

    case (state)
        idle:
        begin
            if (fire_pulse && bx==0)
                state <= pulseon;

            bx           <= 1'b0;
            pulser_ready <= 1'b1;
            compin <= 0;
        end

        pulseon:
        begin
            pulse_en     <= 1'b1;
            pulser_ready <= 1'b0;
            bx <= 4'hF & (bx + 1'b1);

            if (bx==pulse_width)
                state <= pulseoff;

            compin <= (compin_inject) ? 1'b1 : 1'b0;
        end

        pulseoff:
        begin
            pulse_en <= 1'b0;
            bx       <= 4'hF & (bx + 1'b1);

            if (bx==bx_delay)
                state <= readout;
        end

        readout:
        begin
            if (halfstrips!=halfstrips_expect)
                halfstrips_errcnt <= 32'hFFFFFFFF & (halfstrips_errcnt + 1);

            if (compout!=compout_expect)
                compout_errcnt <= 32'hFFFFFFFF & (compout_errcnt + 1);

            compout_last <= compout;
            state <= idle;
        end

        default:
            state = idle;

    endcase
end
endmodule
