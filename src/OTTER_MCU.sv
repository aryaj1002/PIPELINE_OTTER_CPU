`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: Arya Jain
// 
// Create Date: 02/21/2024 11:50:30 AM
// Design Name: 
// Module Name: OTTER_pipeline
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


module OTTER_pipeline(
    input CLK, RST, INTR,
    input [31:0] IOBUS_IN,
    output logic IOBUS_WR,
    output logic [31:0] IOBUS_OUT, IOBUS_ADDR
    );
    
    // ---------------- PIPELINE REGISTER STRUCTS ----------------
    typedef struct packed {
        logic [31:0] instruction;
        logic [31:0] PC;
        logic [31:0] PC_PLUS4;
    } pipe_reg;  
    
    pipe_reg IF_DEC_reg;
        
    typedef struct packed {
        logic [31:0] instruction;  // carried forward - Memory/Writeback need opcode, rd, funct3, etc.
        logic [31:0] PC;           // carried forward - Execute's BAG needs this for branch/jal targets
        logic [31:0] PC_PLUS4;     // carried forward - Writeback's reg-file mux needs this
        logic [31:0] srcA;         // ALU-ready operand A (already muxed)
        logic [31:0] srcB;         // ALU-ready operand B (already muxed)
        logic [31:0] rs1;          // raw rs1 - needed by BCG and BAG (jalr)
        logic [31:0] rs2;          // raw rs2 - needed by BCG, and later by Memory (store data)
        logic [31:0] J_type;       // needed by BAG for jal target calc
        logic [31:0] B_type;       // needed by BAG for branch target calc
        logic [31:0] I_type;       // needed by BAG for jalr target calc
        logic [3:0]  alu_fun;
        logic [1:0]  rf_wr_sel;    // forwarded control bit - actual wd mux happens in Writeback
    } pipe_reg2;

    pipe_reg2 DEC_EXEC_reg;

    typedef struct packed {
        logic [31:0] instruction;  // Memory needs funct3 bits (size/sign); Writeback needs rd
        logic [31:0] PC_PLUS4;     // Writeback's wd mux (jal/jalr return address)
        logic [31:0] result;       // ALU output - data mem address, IOBUS_ADDR, or wd
        logic [31:0] rs2;          // store data (MEM_DIN2) and IOBUS_OUT
        logic [1:0]  rf_wr_sel;    // still riding along to Writeback
    } pipe_reg3;

    pipe_reg3 EXE_MEM_reg;

    typedef struct packed {
        logic [31:0] instruction;  // rd address (bits 11:7) travels with the data
        logic [31:0] PC_PLUS4;
        logic [31:0] result;
        logic [31:0] DOUT2;        // data read from memory (loads)
        logic [1:0]  rf_wr_sel;
    } pipe_reg4;

    pipe_reg4 MEM_WB_reg;


    // ---------------- DATA PATHS ----------------
    logic [31:0] pc, pc_plus4, jalr, branch, jal; // PC MUX inputs
    assign pc_plus4 = pc + 4;
    logic [31:0] pc_din;        // PC input
    
    logic [31:0] ir;            // DOUT1 of Memory module
    logic [31:0] DOUT2;         // Memory module output
    
    logic [31:0] wd;            // Reg File input
    logic [31:0] rs1, rs2;      // Reg File outputs
    
    logic [31:0] U_type, I_type, S_type, B_type, J_type; // immediate generator outputs
    
    logic br_eq, br_lt, br_ltu; // BCG outputs
    
    logic [31:0] srcA, srcB;    // ALU inputs
    logic [31:0] result;        // ALU output
    
    // (Top-Level) OTTER outputs
    assign IOBUS_OUT  = EXE_MEM_reg.rs2;
    assign IOBUS_ADDR = EXE_MEM_reg.result;
    // IOBUS_WR is set by Memory module
    
    
    // ---------------- CONTROL SIGNALS ----------------
    logic PCWrite, regWrite, memWE2, memRDEN1, memRDEN2, reset; 
    logic [3:0] alu_fun;
    logic alu_srcA;
    logic [1:0] alu_srcB, pcSource, rf_wr_sel;
    
    assign reset    = RST;
    assign PCWrite  = 1'b1;
    assign memRDEN1 = 1'b1;
    assign memRDEN2 = (EXE_MEM_reg.instruction[6:0] == 7'b0000011);   // load in Memory stage
    assign memWE2   = (EXE_MEM_reg.instruction[6:0] == 7'b0100011);   // store in Memory stage
    assign regWrite = (MEM_WB_reg.instruction[6:0] != 7'b0100011) &&  // not a store
                      (MEM_WB_reg.instruction[6:0] != 7'b1100011);    // not a branch
    
    
    // ---------------- MUXes ----------------
    always_comb
    begin
        // PC mux
        case(pcSource)
            2'd0: pc_din = pc_plus4;
            2'd1: pc_din = jalr;
            2'd2: pc_din = branch;
            2'd3: pc_din = jal;
            default: pc_din = 32'hDEADDEAD; // distinct value to stand out if default
        endcase
        
        // Reg File mux (Writeback stage - uses MEM_WB_reg)
        case(MEM_WB_reg.rf_wr_sel)
            2'd0: wd = MEM_WB_reg.PC_PLUS4;
            2'd1: wd = 32'b0;   // CSR_reg in diagram, not used because no interrupts
            2'd2: wd = MEM_WB_reg.DOUT2;
            2'd3: wd = MEM_WB_reg.result;
        endcase
        
        // ALU mux A
        case(alu_srcA)
            1'd0: srcA = rs1;
            1'd1: srcA = U_type;
        endcase
        
        // ALU mux B
        case(alu_srcB)
            2'd0: srcB = rs2;
            2'd1: srcB = I_type;
            2'd2: srcB = S_type;
            2'd3: srcB = IF_DEC_reg.PC;
        endcase
    end
    
    
    // ---------------- MODULES ----------------
    // FETCH
    Program_Counter PC(
        .reset(reset),
        .PCWrite(PCWrite), 
        .clk(CLK),
        .pc_din(pc_din),
        .pc(pc)
    );
    
    // FETCH (port 1) + MEMORY (port 2)
    Memory MEM(
        .MEM_CLK(CLK),
        .MEM_RDEN1(memRDEN1),
        .MEM_RDEN2(memRDEN2),
        .MEM_WE2(memWE2),
        .MEM_ADDR1(pc[15:2]), 
        .MEM_ADDR2(EXE_MEM_reg.result),
        .MEM_DIN2(EXE_MEM_reg.rs2),
        .MEM_SIZE(EXE_MEM_reg.instruction[13:12]),
        .MEM_SIGN(EXE_MEM_reg.instruction[14]), 
        .IO_IN(IOBUS_IN),
        .IO_WR(IOBUS_WR), 
        .MEM_DOUT1(ir), 
        .MEM_DOUT2(DOUT2)
    );
    
    // DECODE (read) + WRITEBACK (write)
    REG_FILE RF(
        .clk(CLK),
        .en(regWrite), 
        .adr1(IF_DEC_reg.instruction[19:15]), 
        .adr2(IF_DEC_reg.instruction[24:20]), 
        .wa(MEM_WB_reg.instruction[11:7]), 
        .wd(wd), 
        .rs1(rs1), 
        .rs2(rs2)
    );
    
    // EXECUTE
    Arithmetic_Logic_Unit ALU(
        .alu_srcA(DEC_EXEC_reg.srcA),
        .alu_srcB(DEC_EXEC_reg.srcB),
        .alu_fun(DEC_EXEC_reg.alu_fun),
        .result(result)
    );
    
    // DECODE
    Immediate_Generator IG(
        .ir(IF_DEC_reg.instruction),
        .U_type(U_type),
        .I_type(I_type),
        .S_type(S_type),
        .J_type(J_type),
        .B_type(B_type)
    );
    
    // EXECUTE
    Branch_Conditional_Generator BCG(
        .rs1(DEC_EXEC_reg.rs1),
        .rs2(DEC_EXEC_reg.rs2),
        .br_eq(br_eq),
        .br_lt(br_lt),
        .br_ltu(br_ltu)
    );
    
    Branch_Address_Generator BAG(
        .pc(DEC_EXEC_reg.PC),
        .J_type(DEC_EXEC_reg.J_type), 
        .B_type(DEC_EXEC_reg.B_type),
        .I_type(DEC_EXEC_reg.I_type),
        .rs1(DEC_EXEC_reg.rs1), 
        .jalr(jalr),
        .branch(branch),
        .jal(jal)
    );

    // DECODE
    CU_DCDR CU_DCDR (
        .opcode(IF_DEC_reg.instruction[6:0]), 
        .funct3(IF_DEC_reg.instruction[14:12]), 
        .ir_30(IF_DEC_reg.instruction[30]), 
        .br_eq(br_eq), 
        .br_lt(br_lt), 
        .br_ltu(br_ltu), 
        .alu_fun(alu_fun), 
        .alu_srcA(alu_srcA), 
        .alu_srcB(alu_srcB), 
        .pcSource(pcSource), 
        .rf_wr_sel(rf_wr_sel)
    );


    // ---------------- PIPELINE REGISTERS ----------------
    // Fetch -> Decode
    always_ff @ (posedge CLK) begin
        IF_DEC_reg.instruction <= ir;
        IF_DEC_reg.PC          <= pc;
        IF_DEC_reg.PC_PLUS4    <= pc_plus4;
    end 

    // Decode -> Execute
    always_ff @ (posedge CLK) begin
        DEC_EXEC_reg.instruction <= IF_DEC_reg.instruction;
        DEC_EXEC_reg.PC          <= IF_DEC_reg.PC;
        DEC_EXEC_reg.PC_PLUS4    <= IF_DEC_reg.PC_PLUS4;
        DEC_EXEC_reg.srcA        <= srcA;
        DEC_EXEC_reg.srcB        <= srcB;
        DEC_EXEC_reg.rs1         <= rs1;
        DEC_EXEC_reg.rs2         <= rs2;
        DEC_EXEC_reg.J_type      <= J_type;
        DEC_EXEC_reg.B_type      <= B_type;
        DEC_EXEC_reg.I_type      <= I_type;
        DEC_EXEC_reg.alu_fun     <= alu_fun;
        DEC_EXEC_reg.rf_wr_sel   <= rf_wr_sel;
    end
    
    // Execute -> Memory
    always_ff @ (posedge CLK) begin
        EXE_MEM_reg.instruction <= DEC_EXEC_reg.instruction;
        EXE_MEM_reg.PC_PLUS4    <= DEC_EXEC_reg.PC_PLUS4;
        EXE_MEM_reg.result      <= result;
        EXE_MEM_reg.rs2         <= DEC_EXEC_reg.rs2;
        EXE_MEM_reg.rf_wr_sel   <= DEC_EXEC_reg.rf_wr_sel;
    end

    // Memory -> Writeback
    always_ff @ (posedge CLK) begin
        MEM_WB_reg.instruction <= EXE_MEM_reg.instruction;
        MEM_WB_reg.PC_PLUS4    <= EXE_MEM_reg.PC_PLUS4;
        MEM_WB_reg.result      <= EXE_MEM_reg.result;
        MEM_WB_reg.DOUT2       <= DOUT2;
        MEM_WB_reg.rf_wr_sel   <= EXE_MEM_reg.rf_wr_sel;
    end
    
endmodule