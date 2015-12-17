/*
 * ============================================================================
 *
 *  Name        :   M__MIPS_5_Stage
 *  Author      :   Aditya Shevade
 *
 *  Description :   Top level 5 stage MIPS pipelined CPU core module
 *
 * ============================================================================
 */

module M__MIPS_5_Stage (
    input   wire            clock__i,           // Clock input
    input   wire            reset_n__i,         // Reset signal
    input   wire    [31:0]  instrData__i,       // Instruction read from instruction memory
    input   wire    [31:0]  memDataRead__i,     // Data read from data memory

    output  wire    [31:0]  instrAddr__o,       // Instruction address (Program Counter)
    output  wire    [31:0]  memAddr__o,         // Data memory address
    output  wire    [31:0]  memDataWrite__o,    // Data to write in data memory
    output  wire            memRead__o,         // Data memory read signal
    output  wire            memWrite__o         // Data memory write signal
    );

// ============================================================================
// ==== Check these signals later. Naming scheme too complicated.
// ============================================================================
wire    [ 1:0]  Forward_ALU_A, Forward_ALU_B, Forward_EQ_A, Forward_EQ_B;
wire    [ 2:0]  ALUOp_ID, ALUOp_EX, ALUCtrl;
wire    [ 4:0]  RegDst_addr_EX, RegDst_addr_WB, RegDst_addr_MEM;
wire    [ 9:0]  CtrlCode;
wire    [31:0]  PC_Four_IF, PC_Four_ID, PC_Offset_IF, PC_Next_IF, PC_Branch_IF;
wire    [31:0]  Mux_Branch, PCntr, Instr_IF, Instr_ID, Instr_EX,
                RegRsData_ID, RegRsData_EX, RegRtData_ID, RegRtData_EX, Data_Offset, Immediate_ID, Immediate_EX,
                mux_ALUSrc,Rs_Data_EX, Rt_Data_EX, ALUResult_MEM, MUX_A_ALUSrc, MUX_B_ALUSrc,
                ALUResult_EX, MUX_A_EQSrc, MUX_B_EQSrc, Rt_Data_MEM, MEM_Data_MEM, MEM_Data_WB,
                ALUResult_WB;

wire    [31:0]  MemToReg_Data_Result, MemReadData_WB;
wire    [31:0]  Instruction_IF, Instruction_ID, Instruction_EX;

// ============================================================================
// ==== END ==== Check these signals later. Naming scheme too complicated.
// ============================================================================

// Program Control Signals
wire    PCSrc, BranchTaken, Branch_ID, Zero, Stall;
wire    RegDst_ctl_ID, MemRead_ID, MemToReg_ID,
                        MemWrite_ID, ALUSrc_ID, RegWrite_ID;
wire    RegDst_ctl_EX, MemRead_EX, MemToReg_EX,
                        MemWrite_EX, ALUSrc_EX, RegWrite_EX;
wire    MemRead_MEM, MemToReg_MEM, MemWrite_MEM, RegWrite_MEM;
wire    MemToReg_WB, RegWrite_WB;

// Muxed output signals
assign Data_Offset = Immediate_ID << 2;
assign PCSrc = Branch_ID & BranchTaken;


/*
 * ============================================================================
 * ==== Instruction Fetch (IF) Stage
 * ============================================================================
 */

M__Mux2Mbit #(.WIDTH(32)) MUX_Branch (
    .dataA__i      (PC_Four_IF),       // PC + 4 (next instruction)
    .dataB__i      (PC_Offset_IF),   // PC + Branch offset
    .select__i     (PCSrc),                     // Branch taken (1) or not (0)
    .data__o       (PC_Branch_IF)                  // PC for the next instruction
    );

// Generate a new instruction every clock cycle.
// If stalled, the current address stays so no new instruction is fetched.
M__ProgramCounter Program_Counter (
    .clock__i       (clock__i),
    .reset_n__i     (reset_n__i),
    .address__i     (PC_Branch_IF),                // Result of the branch mux
    .address__o     (PC_Next_IF),        // Next PC if not stalling
    .pcWrite__i     ((~Stall))                  // Pipeline stall signal
    );

M__Adder PC_Add_4 (
    .dataA__i       (PC_Next_IF),        // Current instruction
    .dataB__i       (32'h0000_0004),            // Word offset (byte memory)
    .data__o        (PC_Four_IF)       // Next instruction
    );

//Instr_Memory Instr_Memory (
//    .address        (ProgramCounterIF),
//    .instruction    (Instruction_IF)
//    );

// Inputs:
//      Stall   : To decide whether to pass new inputs (1) or not (0).
//      PCSrc   : Pipeline flush signal. If branch taken outputs should be 0.
//      PC+4    : For calculating the branch offsets.
//      Instr   : Instruction code (OP code).
M__IFID_Reg IFID_Reg (
    .clock__i       (clock__i),
    .reset_n__i     (reset_n__i),
    .hazard__i      ((Stall)),              // Pipeline stall signal
    .flush__i       (PCSrc),                // Pipeline flush signal (branch taken)
    .PC_4__i        (PC_Four_IF),           // PC + 4
    .instr__i       (Instruction_IF),       // Instruction
    .PC_4__o        (PC_Four_ID),
    .instr__o       (Instruction_ID)
    );

/*
 * ============================================================================
 * ==== Instruction Decode (ID) Stage
 * ============================================================================
 */

// Calculate the branch address for JUMP instruction (PC + 4 + (offset << 2))
M__Adder PC_Add_Offset (
    .dataA__i       (PC_Four_ID),
    .dataB__i       ((Immediate_ID << 2)),      // Immediate address
    .data__o        (PC_Offset_IF)           // Offset (jump)
    );

// Generate CPU control logic (instruction decoding).
M__CPUControl CPU_Control (
    .opcode__i      (Instruction_ID[31:26]),            // Instruction OPcode
    .RegDst__o      (CtrlCode[9]),
    .Branch__o      (CtrlCode[8]),
    .MemRead__o     (CtrlCode[7]),
    .MemToReg__o    (CtrlCode[6]),
    .ALUOp__o       (CtrlCode[5:3]),
    .MemWrite__o    (CtrlCode[2]),
    .ALUSrc__o      (CtrlCode[1]),
    .RegWrite__o    (CtrlCode[0])
    );

// Decide whether to Stall (all 0) or pass control out to next stage.
M__Mux2Mbit #(.WIDTH(10)) Control_Stall (
    .dataA__i       (10'b0),
    .dataB__i       (CtrlCode),
    .select__i      (Stall),
    .data__o        ({RegDst_ctl_ID, Branch_ID, MemRead_ID, MemToReg_ID, ALUOp_ID,
                        MemWrite_ID, ALUSrc_ID, RegWrite_ID})
    );

// dual read single write port register file.
M__RegFile Reg_File (
    .clock__i       (clock__i),
    .rst_n__i       (reset_n__i),
    .RegWrite__i    (RegWrite_WB),
    .AddrRs__i      (Instruction_ID[25:21]),
    .AddrRt__i      (Instruction_ID[20:16]),
    .AddrRd__i      (RegDst_addr_WB),
    .DataRd__i      (MemToReg_Data_Result),
    .DataRs__o      (RegRsData_ID),
    .DataRt__o      (RegRtData_ID)
    );

// Forwarding logic.
M__Mux3Mbit #(.WIDTH(32)) Mux_A_EQ (
    .dataA__i       (RegRsData_ID),
    .dataB__i       (MemToReg_Data_Result),
    .dataC__i       (ALUResult_MEM),
    .select__i      (Forward_ALU_A),
    .data__o        (MUX_A_EQSrc)
    );

// Forwarding logic.
M__Mux3Mbit #(.WIDTH(32)) Mux_B_EQ (
    .dataA__i       (RegRtData_ID),
    .dataB__i       (MemToReg_Data_Result),
    .dataC__i       (ALUResult_MEM),
    .select__i      (Forward_ALU_B),
    .data__o        (MUX_B_EQSrc)
    );

M__EqualityCheck #(.WIDTH(32)) EqualityCheck (
    .dataA__i       (MUX_A_EQSrc),
    .dataB__i       (MUX_B_EQSrc),
    .result__o      (BranchTaken)
    );

M__SignExtend #(.WIDTH_I(16), .WIDTH_O(32)) Sign_Extend (
    .data__i        (Instruction_ID[15:0]),
    .data__o        (Immediate_ID)
    );

M__IDEX_Reg ID_EX_Reg (
    .clock__i       (clock__i),
    .reset_n__i     (reset_n__i),
    .RegWrite__i    (RegWrite_ID),
    .MemToReg__i    (MemToReg_ID),
    .MemRead__i     (MemRead_ID),
    .MemWrite__i    (MemWrite_ID),
    .ALUSrc__i      (ALUSrc_ID),
    .ALUOp__i       (ALUOp_ID),
    .RegDst__i      (RegDst_ctl_ID),
    .RegRsData__i   (RegRsData_ID),
    .RegRtData__i   (RegRtData_ID),
    .Immediate__i   (Immediate_ID),
    .InstrRsAddr__i (Instruction_ID[25:21]),
    .InstrRtAddr__i (Instruction_ID[20:16]),
    .InstrRdAddr__i (Instruction_ID[15:11]),

    .RegWrite__o    (RegWrite_EX),
    .MemToReg__o    (MemToReg_EX),
    .MemRead__o     (MemRead_EX),
    .MemWrite__o    (MemWrite_EX),
    .ALUSrc__o      (ALUSrc_EX),
    .ALUOp__o       (ALUOp_EX),
    .RegDst__o      (RegDst_ctl_EX),
    .RegRsData__o   (RegRsData_EX),
    .RegRtData__o   (RegRtData_EX),
    .Immediate__o   (Immediate_EX),
    .InstrRsAddr__o (Instruction_EX[25:21]),
    .InstrRtAddr__o (Instruction_EX[20:16]),
    .InstrRdAddr__o (Instruction_EX[15:11])
    );

/*
 * ============================================================================
 * ==== Instruction Execute (EX) Stage
 * ============================================================================
 */

// Rd is destination of reg type instructions [15:11].
// Rt is destination otherwise [20:16].
M__Mux2Mbit #(.WIDTH(5)) Mux_RegDst (
    .dataA__i       (Instruction_EX[20:16]),
    .dataB__i       (Instruction_EX[15:11]),
    .select__i      (RegDst_ctl_EX),
    .data__o        (RegDst_addr_EX)
    );

// Forwarding between
//      original source
//      final result from retiring instruction
//      result from the previous instruction (currently in MEM stage)
M__Mux3Mbit #(.WIDTH(32)) Mux_A_ALU (
    .dataA__i       (RegRsData_EX),
    .dataB__i       (MemToReg_Data_Result),
    .dataC__i       (ALUResult_MEM),
    .select__i      (Forward_ALU_A),
    .data__o        (MUX_A_ALUSrc)
    );

// Forwarding between
//      original source
//      final result from retiring instruction
//      result from the previous instruction (currently in MEM stage)
M__Mux3Mbit #(.WIDTH(32)) Mux_B_ALU (
    .dataA__i       (RegRtData_EX),
    .dataB__i       (MemToReg_Data_Result),
    .dataC__i       (ALUResult_MEM),
    .select__i      (Forward_ALU_B),
    .data__o        (MUX_B_ALUSrc)
    );

// Check whether the input to ALU is immediate value or register data.
M__Mux2Mbit #(.WIDTH(32)) Mux_ALUSrc (
    .dataA__i       (MUX_B_ALUSrc),
    .dataB__i       (Immediate_EX),
    .select__i      (ALUSrc_EX),
    .data__o        (mux_ALUSrc)
    );

// LSB bits in the instruction are ALU codes.
// ALU OP comes from instruction decode (Control Logic)
M__ALUControl ALU_Control (
    .ALUFunction__i (Immediate_EX[5:0]),
    .ALUOp__i       (ALUOp_EX),
    .ALUCtrl__o     (ALUCtrl)
    );

M__ALUMain ALU_Main (
    .dataA__i       (MUX_A_ALUSrc),
    .dataB__i       (mux_ALUSrc),
    .ALUCtrl__i     (ALUCtrl),
    .ALUResult__o   (ALUResult_EX),
    .Zero__o        (Zero)
    );

M__EXMEM_Reg EX_MEM_Reg (
    .clock__i       (clock__i),
    .reset_n__i     (reset_n__i),
    .RegWrite__i    (RegWrite_EX),
    .MemToReg__i    (MemToReg_EX),
    .MemRead__i     (MemRead_EX),
    .MemWrite__i    (MemWrite_EX),
    .ALUData__i     (ALUResult_EX),
    .MemWriteData__i(MUX_B_ALUSrc),
    .WBReg__i       (RegDst_addr_EX),

    .RegWrite__o    (RegWrite_MEM),
    .MemToReg__o    (MemToReg_MEM),
    .MemRead__o     (MemRead_MEM),
    .MemWrite__o    (MemWrite_MEM),
    .ALUData__o     (ALUResult_MEM),
    .MemWriteData__o(memDataWrite__o),
    .WBReg__o       (RegDst_addr_MEM)
    );

/*
 * ============================================================================
 * ==== Memory Access (MEM) Stage
 * ============================================================================
 */

//Data_Memory Data_Memory (
//    .clock          (clock),
//    .address        (ALUResult_MEM),
//    .data_in        (Rt_Data_MEM),
//    .MemRead        (MemRead_MEM),
//    .MemWrite       (MemWrite_MEM),
//    .data_out       (MemData_MEM)
//    );

M__MEMWB_Reg MEM_WB_Reg (
    .clock__i       (clock__i),
    .reset_n__i     (reset_n__i),
    .RegWrite__i    (RegWrite_MEM),
    .MemToReg__i    (MemToReg_MEM),
    .MemReadData__i (memDataRead__i),
    .ALUData__i     (ALUResult_MEM),
    .WBReg__i       (RegDst_addr_MEM),

    .RegWrite__o    (RegWrite_WB),
    .MemToReg__o    (MemToReg_WB),
    .MemReadData__o (MemReadData_WB),
    .ALUData__o     (ALUResult_WB),
    .WBReg__o       (RegDst_addr_WB)
    );

/*
 * ============================================================================
 * ==== Write Back (WB) Stage
 * ============================================================================
 */

M__Mux2Mbit #(.WIDTH(32)) Mux_MemToReg (
    .dataA__i       (ALUResult_WB),
    .dataB__i       (MemReadData_WB),
    .select__i      (MemToReg_WB),
    .data__o        (MemToReg_Data_Result)
    );

/*
 * ============================================================================
 * ==== Data Forwarding
 * ============================================================================
 */

M__ForwardingUnit Forwarding_Unit (
    .reset_n__i         (reset_n__i),
    .IFID_RegRs__i      (Instruction_ID[25:21]),
    .IFID_RegRt__i      (Instruction_ID[20:16]),
    .IDEX_RegRs__i      (Instruction_EX[25:21]),
    .IDEX_RegRt__i      (Instruction_EX[20:16]),
    .EXMEM_RegRd__i     (RegDst_addr_MEM),
    .MEMWB_RegRd__i     (RegDst_addr_WB),
    .EXMEM_RegWrite__i  (RegWrite_MEM),
    .MEMWB_RegWrite__i  (RegWrite_WB),
    .Branch__i          (Branch_ID),
    .ALUForvA__o        (Forward_ALU_A),
    .ALUForvB__o        (Forward_ALU_B),
    .EQUForvA__o        (Forward_EQ_A),
    .EQUForvB__o        (Forward_EQ_B)
    );

/*
 * ============================================================================
 * ==== Hazard Detection
 * ============================================================================
 */

M__HazardDetect Hazard_Detect (
    .clock__i           (clock__i),
    .reset_n__i         (reset_n__i),
    .IDEX_MemRead__i    (MemRead_EX),
    .IDEX_RegWrite__i   (RegWrite_EX),
    .Branch__i          (CtrlCode[8]),
    .IFID_RegRs__i      (Instruction_ID[25:21]),
    .IFID_RegRt__i      (Instruction_ID[20:16]),
    .IDEX_RegRd__i      (RegDst_addr_EX),
    .Stall__o           (Stall)
    );

endmodule : M__MIPS_5_Stage
