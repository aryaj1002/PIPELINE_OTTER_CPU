`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: Michael Wilson
// 
// Create Date: 02/01/2024 10:17:55 AM
// Design Name: 
// Module Name: Immediate_Generator
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


module Immediate_Generator(
    input [31:0] ir,
    output logic [31:0] U_type, I_type, S_type, B_type, J_type
    );
    
    // see page 16 of the OTTER Assembly Manual for reference
    assign U_type = {ir[31:12], {12{1'b0}}};
    assign I_type = {{21{ir[31]}}, ir[30:25], {ir[24:20]}};
    assign S_type = {{21{ir[31]}}, ir[30:25], ir[11:7]};
    assign B_type = {{20{ir[31]}}, ir[7], ir[30:25],  ir[11:8], 1'b0};
    assign J_type = {{12{ir[31]}}, ir[19:12], ir[20], ir[30:21], 1'b0};
    
endmodule
