`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: Michael Wilson
// 
// Create Date: 01/18/2024 09:17:40 AM
// Design Name: 
// Module Name: Program_Counter
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


module Program_Counter(
    input reset, PCWrite, clk,
    input [31:0] pc_din,
    output logic [31:0] pc
    );
    
    always_ff @ (posedge clk, posedge reset)
    begin
        if(reset) pc <= 32'h00000000;
        else if (PCWrite) pc <= pc_din;
        //no else; hold if not resetting or writing
    end
endmodule
