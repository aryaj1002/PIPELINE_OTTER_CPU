`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: Michael Wilson
// 
// Create Date: 02/08/2024 11:13:52 AM
// Design Name: 
// Module Name: Branch_Address_Generator
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


module Branch_Conditional_Generator(
    input [31:0] rs1, rs2,
    output logic br_eq, br_lt, br_ltu
    );
    
    always_comb
    begin
        if (rs1 == rs2) br_eq = 1;                  // equality
        else br_eq = 0;
        
        if ($signed(rs1) < $signed(rs2)) br_lt = 1; // less than signed
        else br_lt = 0;
        
        if (rs1 < rs2) br_ltu = 1;                  // less than unsigned
        else br_ltu = 0;
    end
endmodule
