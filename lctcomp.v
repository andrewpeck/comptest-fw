`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:12:19 12/04/2014 
// Design Name: 
// Module Name:    lctcomp 
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
module lctcomp(
    output wire  [1:0] pkmode, 
    output wire  [2:0] pktime, 
    input  wire  [7:0] distrip, 

    input  wire compout, 
    input  wire compin, 
    input  wire reset,
    input  wire clock
);
//-----------------------------------------------------------------------------
`define WIDTH 32
`define DEPTH 4
`define FCWIDTH 2
endmodule


module FIFO_topmodule
( 
    input Clk,
    input Rst,
    input [`WIDTH-1:0] DIn,
    input Write,
    input Read,
    input Clr,
    output Empty,
    output Full,
    output [`WIDTH-1:0] DOut,
    output Last,
    output SLast,
    output First
);

wire [`FCWIDTH-1:0] rd_wire,wr_wire;

FIFO_controller fifo1(
    .clk(Clk),
    .rst(Rst),
    .write(Write),
    .read(Read),
    .clr(Clr),

    .empty(Empty),
    .full(Full),
    .last(Last),
    .slast(SLast),
    .first(First),
    .rd_ptr(rd_wire),
    .wr_ptr(wr_wire)
);

FIFO_memblk fifo2(
    .clk(Clk),
    .write(Write),
    .read(Read),
    .rd_addr(rd_wire),
    .wr_addr(wr_wire),
    .datain(DIn),
    .dataout(DOut)
);



endmodule


`define WIDTH 32
`define DEPTH 4
`define FCWIDTH 2

module FIFO_controller(
    input clk,
    input rst,
    input write,
    input read,
    input clr,

    output reg empty,
    output reg full,
    output reg last,
    output reg slast,
    output reg first,
    output reg [`FCWIDTH-1:0] rd_ptr,
    output reg [`FCWIDTH-1:0] wr_ptr
);

//Write process
reg [`FCWIDTH:0] fcounter;

always @(posedge clk) 
    if (rst)
    begin 
        //  fcounter <= 0;
        //  rd_ptr <= 0;
        wr_ptr <= 0;
    end
    else if (clr)
    begin 
        //  fcounter <= 0;
        //  rd_ptr <= 0;
        wr_ptr <= 0;
    end
    else 
    begin
        if (write && (~full))
        begin
            wr_ptr <= wr_ptr+1;
            //  fcounter <= fcounter+1;
        end
        else 
        begin
            wr_ptr <= wr_ptr;
            //  fcounter <= fcounter;
        end
    end

    //Read process
    always @(posedge clk) 
        if (rst)
        begin 
            //  fcounter <= 0;
            rd_ptr <= 0;
            //  wr_ptr <= 0;
        end
        else if (clr)
        begin 
            //  fcounter <= 0;
            rd_ptr <= 0;
            //  wr_ptr <= 0;
        end
        else 
        begin
            if (read && (~empty))
            begin
                rd_ptr <= rd_ptr+1;
                //  fcounter <= fcounter-1;
            end
            else 
            begin
                rd_ptr <= rd_ptr;
                //  fcounter <= fcounter;
            end
        end


        always @(posedge clk) 
            if (rst)
            begin 
                fcounter <= 0;
            end
            else if (clr)
            begin 
                fcounter <= 0;
            end
            else 
            begin
                if ((write && (~full))&&~(read && (~empty)))
                begin
                    fcounter <= fcounter+1;
                end
                else if ((write && (~full))&&(read && (~empty)))
                begin
                    fcounter <= fcounter;
                end
                else if (~(write && (~full))&&(read && (~empty)))
                begin
                    fcounter <= fcounter-1;
                end

                else if (fcounter == `DEPTH+1)
                begin
                    fcounter <= 0;
                end
            end

            // Process for Status Signals
            always @(posedge clk)
                if (rst)
                begin 
                    empty <= 1'b1;
                    full <= 1'b0;
                    last <= 1'b0;
                    slast <= 1'b0;
                    first <= 1'b0;
                end
                else if (clr)
                begin 
                    empty <= 1'b1;
                    full <= 1'b0;
                    last <= 1'b0;
                    slast <= 1'b0;
                    first <= 1'b0;
                end
                else 
                begin
                    case (fcounter)
                        `DEPTH: begin 
                            empty <= 1'b0;
                            full <= 1'b1;
                            last <= 1'b0;
                            slast <= 1'b0;
                            first <= 1'b0;
                        end 
                        `DEPTH -1: begin 
                            empty <= 1'b0;
                            full <= 1'b0;
                            last <= 1'b1;
                            slast <= 1'b0;
                            first <= 1'b0;
                        end 
                        `DEPTH -2: begin 
                            empty <= 1'b0;
                            full <= 1'b0;
                            last <= 1'b0;
                            slast <= 1'b1;
                            first <= 1'b0;
                        end 
                        1: begin 
                            empty <= 1'b0;
                            full <= 1'b0;
                            last <= 1'b0;
                            slast <= 1'b0;
                            first <= 1'b1;
                        end 
                        0: begin 
                            empty <= 1'b1;
                            full <= 1'b0;
                            last <= 1'b0;
                            slast <= 1'b0;
                            first <= 1'b0;
                        end 
                        default: begin 
                            empty <= 1'b0;
                            full <= 1'b0;
                            last <= 1'b0;
                            slast <= 1'b0;
                            first <= 1'b0;
                        end 


                    endcase

                end

endmodule

//---------------------------
//FIFO MEMORY BLOCK--------------------

`define WIDTH 32
`define DEPTH 4
`define FCWIDTH 2

module FIFO_memblk(
    input clk,
    // input rst,
    // input clr,
    input write,
    input read,
    input [`FCWIDTH-1:0] rd_addr,
    input [`FCWIDTH-1:0] wr_addr,
    input [`WIDTH-1:0] datain,
    output reg [`WIDTH-1:0] dataout
);

reg [`WIDTH-1:0] MEMORY[0:`DEPTH-1];

always @(posedge clk)

begin 
    if (write)
        MEMORY[wr_addr] <= datain;
    else 
        MEMORY[wr_addr]<= MEMORY[wr_addr];
end


always @(posedge clk)

begin 
    if (read)
        dataout <= MEMORY[rd_addr];
    else 
        dataout <= 0;
end

endmodule

