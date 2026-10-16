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


module Branch_Address_Generator(
    input [31:0] pc, J_type, B_type, I_type, rs1,
    output logic [31:0] jalr, branch, jal
    );
    
    assign jalr = $signed(rs1) + $signed(I_type);
    assign branch = pc + $signed(B_type);
    assign jal = pc + $signed(J_type); 
    
endmodule
