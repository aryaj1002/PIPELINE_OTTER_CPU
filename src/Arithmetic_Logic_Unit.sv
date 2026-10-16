`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: Michael Wilson
// 
// Create Date: 02/01/2024 09:58:53 AM
// Design Name: 
// Module Name: Arithmetic_Logic_Unit
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


module Arithmetic_Logic_Unit(
    input [31:0] alu_srcA, alu_srcB,
    input [3:0] alu_fun,
    output logic [31:0] result
    );
    
    always_comb begin
        case (alu_fun)
            4'b0000: result = alu_srcA + alu_srcB;  // add
            4'b1000: result = alu_srcA - alu_srcB;  // sub
            4'b0110: result = alu_srcA | alu_srcB;  // or
            4'b0111: result = alu_srcA & alu_srcB;  // and
            4'b0100: result = alu_srcA ^ alu_srcB;  // xor
            4'b0101: result = alu_srcA >> alu_srcB[4:0]; // srl
            4'b0001 :result = alu_srcA << alu_srcB[4:0]; // sll
            4'b1101: result = $signed(alu_srcA) >>> alu_srcB[4:0];// sra
            4'b0010: result = $signed(alu_srcA) < $signed(alu_srcB); // slt
            4'b0011: result = $unsigned(alu_srcA) < $unsigned(alu_srcB);  // sltu
            4'b1001: result = alu_srcA;             // lui - copy
            default: result = 32'hDEADDEAD;         // make default value stick out
        endcase    
    end
endmodule
