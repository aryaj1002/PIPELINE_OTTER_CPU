`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: Michael Wilson
//
// Create Date: 01/25/2024 09:14:09 AM
// Design Name: 
// Module Name: REG_FILE
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


module REG_FILE(
    input clk, en,
    input [4:0] adr1, adr2, wa,
    input [31:0] wd,
    output logic [31:0] rs1, rs2
    );
    
    // create 32x32 register - 32 registers each with 32 bits
    logic [31:0] ram [0:31];
    
    // initialize all registers to zero
    initial begin
        int i;
        for (i=0; i<32; i++) begin
            ram[i] = 0;
        end
    end
    
    // read data in adr1 and adr2 asynchronously
    assign rs1 = ram[adr1];
    assign rs2 = ram[adr2];
    
    // write to rd synchronously
    always_ff @ (negedge clk) begin
        if (en && (wa > 5'b00000)) ram[wa] <= wd;
    end
    
endmodule
