`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: Michael Wilson
// 
// Create Date: 03/11/2024 11:32:12 AM
// Design Name: 
// Module Name: Control_Unit_Decoder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:  The control unit decoder asynchronously determines alu_fun and the select bits for the MUXes
//               It is in charge of telling what type of instruction will be used by looking at the
//                      opcode, funct3 bits, and outputs from the branch condition generator.
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module CU_DCDR(
    input [6:0] opcode,
    input [2:0] funct3,
    input ir_30, 
    input br_eq, br_lt, br_ltu,
    output logic [3:0] alu_fun,
    output logic alu_srcA,
    output logic [1:0] alu_srcB,
    output logic [1:0] pcSource, // only 2 bits becasue no interrupts
    output logic [1:0] rf_wr_sel
    );
    
    always_comb 
    begin
        // initialize all outputs to zero
        alu_fun = 4'b0;
        alu_srcA = 1'b0;
        alu_srcB = 2'b0;
        pcSource = 2'b0;
        rf_wr_sel = 2'b0;
        
        // use opcode to determine outputs
        case (opcode)
            // R-type -- alu ops
            7'b0110011: begin
                alu_fun = {ir_30, funct3};
                alu_srcA = 1'd0;
                alu_srcB = 2'd0;
                pcSource = 2'd0;
                rf_wr_sel = 2'd3;
            end
            
            
            // I-type -- jalr, load instructions, and 'i version' of alu ops
            7'b1100111: begin // jalr
                pcSource = 2'd1;
                rf_wr_sel = 2'd0;
            end
            
            7'b0000011: begin // lb, lh, lw
                alu_fun = 4'b0000;
                alu_srcA = 1'd0;
                alu_srcB = 2'd1; 
                rf_wr_sel = 2'd2;
            end
            
            7'b0010011: begin // 'i version' of alu ops
                if (funct3 == 3'b101) alu_fun = {ir_30, funct3};
                else alu_fun = {1'b0, funct3};
                
                alu_srcA = 1'd0;
                alu_srcB = 1'd1;
                pcSource = 2'd0;
                rf_wr_sel = 2'd3; 
            end
            
            
            // S-type -- store instructions
            7'b0100011: begin // sb, sh, and sw
                alu_fun = 4'b0000;
                alu_srcA = 1'd0;
                alu_srcB = 2'd2;
                pcSource = 2'd0;
            end
            
            
            // B-type -- branch instructions
            7'b1100011: begin // beq, bne, blt, bge, bltu, bgeu
                case (funct3)
                    // pcSource = 2 when branching and 0 when not branching
                    3'b000: if (br_eq)  pcSource = 2'd2;    // else leave as default of zero
                    3'b001: if (~br_eq) pcSource = 2'd2;    // "                           "
                    3'b100: if (br_lt)  pcSource = 2'd2;    // "                           "
                    3'b101: if (~br_lt) pcSource = 2'd2;    // "                           "
                    3'b110: if (br_ltu) pcSource = 2'd2;    // "                           "
                    3'b111: if(~br_ltu) pcSource = 2'd2;    // "                           "
                    default: pcSource = 2'd0;
                endcase
            end
            
            
            // U-type -- lui and auipc
            7'b0110111: begin // lui
                alu_fun = 4'b1001;
                alu_srcA = 1'd1;
                pcSource = 2'd0;
                rf_wr_sel = 2'd3;
            end
            
            7'b0010111: begin // auipc
                alu_fun = 4'b0000;
                alu_srcA = 1'd1;
                alu_srcB = 2'd3;
                pcSource = 2'd0;
                rf_wr_sel = 2'd3;
            end
            
            
            // J-type -- jal
            7'b1101111: begin
                pcSource = 2'd3;
                rf_wr_sel = 2'd0;
            end
            
            
            // default not needed becasue all outputs are defined at beginning of always comb
        endcase
        
    end
    
endmodule
