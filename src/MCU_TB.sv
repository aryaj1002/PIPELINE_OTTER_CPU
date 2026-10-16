`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: Michael Wilson
// 
// Create Date: 02/27/2024 11:19:55 AM
// Design Name: 
// Module Name: MCU_TB
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module MCU_TB();

// inputs and outputs
logic CLK, RST, INTR;
logic [31:0] IOBUS_IN;
logic IOBUS_WR;
logic [31:0] IOBUS_OUT, IOBUS_ADDR;

OTTER_pipeline UUT (
    .CLK(CLK),
    .RST(RST),
    .INTR(INTR), 
    .IOBUS_IN(IOBUS_IN), 
    .IOBUS_OUT(IOBUS_OUT),
    .IOBUS_ADDR(IOBUS_ADDR), 
    .IOBUS_WR(IOBUS_WR)
);
               
// create 20ns clock for 50MHz
always begin
    CLK = 0; #10;
    CLK = 1; #10;
end
// initialize I/O
initial begin
    RST = 1'b1;
    INTR = 1'b0; // not used -- no interrupts
    IOBUS_IN = 32'b0;
    
    #20
    RST = 0;
end 

endmodule
