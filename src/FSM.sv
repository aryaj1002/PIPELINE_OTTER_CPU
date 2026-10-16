`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: Michael Wilson
// 
// Create Date: 03/11/2024 11:31:56 AM
// Design Name: 
// Module Name: Control_Unit_FSM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:     The control unit FSM asynchronously determines the control signals used by the 
//                      Program Counter, Memory module, and Reg File by looking
//                      at the current state and opcode
//                  The four states are INIT, FETCH, EXEC, and WRITEBACK.
//                  The states are set at positive clock edges (synchronously).
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module CU_FSM(
    input CLK, RST, INTR,
    input [6:0] opcode,
    output logic PCWrite, regWrite, memWE2, memRDEN1, memRDEN2, reset 
    // no csr_WE or int_taken because no interrupts
    );
    
    typedef enum{INIT, FETCH, EXEC, WRITEBACK} STATES;
    STATES NS, PS;
    
    always_ff @ (posedge CLK) begin
        if (RST) begin
            PS <= INIT; end
        else begin
            PS <= NS; end
    end
    
    always_comb begin
        // initialize all outputs to zero
        PCWrite = 1'b0;
        regWrite = 1'b0;
        memWE2 = 1'b0;
        memRDEN1 = 1'b0;
        memRDEN2 = 1'b0;
        reset = 1'b0;
        
        // change control signals based on state
        case (PS)
            INIT: begin
                NS = FETCH;
                reset = 1'b1;
            end
            
            FETCH: begin
                NS = EXEC;
                memRDEN1 = 1'b1;
            end
            
            
            EXEC: begin
                // only go to WRITEBACK for load instructions, otherwise FETCH next instruction
                if (opcode == 7'b0000011) NS = WRITEBACK;
                else NS = FETCH;
                
                // EXEC state defaults
                PCWrite = 1'b1;     // override to zero for load instructions (need to WRITEBACK)
                regWrite = 1'b1;    // override to zero for load, store, and branch instructions - less cases/code this way
                
                //use opcode to determine outputs
                case (opcode)
                    // no unique outputs for R-type instructions (alu ops)
                
                    // I-type 
                    // unique outputs for load instructions, but not for jalr or 'i version' of alu ops
                    7'b0000011: begin // lb, lh, lw
                        PCWrite = 1'b0; // set to zero because going to WRITEBACK; not ready for next instruction yet
                        regWrite = 1'b0; 
                        memRDEN2 = 1'b1;
                    end
                    
                    // S-type -- store instructions
                    7'b0100011: begin // sb, sh, and sw
                        regWrite = 1'b0;
                        memWE2 = 1'b1;
                    end
                    
                    // B-type -- branch instructions
                    7'b1100011: begin // beq, bne, blt, bge, bltu, bgeu 
                        regWrite = 1'b0;
                    end
                    
                    // no unique outputs for U-type instructions (lui and auipc)
                    // no unique outputs for J-type instruction (jal)
                    // default case not needed becasue all outputs are defined

                endcase
            end
            
            
            WRITEBACK: 
            begin
                NS = FETCH;
                PCWrite = 1'b1;
                regWrite = 1'b1;
            end
            
            
            default: begin // set default state as INIT
                NS = INIT;
                // nothing more because all outputs are already defined at beginning of always_comb
            end
            
        endcase
        
    end
    
endmodule
