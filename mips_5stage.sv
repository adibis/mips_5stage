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
wire    PCSrc, PCWrite, IFIDWrite, Stall, Branch, Branch_Taken, Zero;
wire    RegDst_ctl_ID, MemRead_ID, MemToReg_ID, MemWrite_ID, ALUSrc_ID, RegWrite_ID;
wire    RegDst_ctl_EX, MemRead_EX, MemToReg_EX, MemWrite_EX, ALUSrc_EX, RegWrite_EX;
wire    MemRead_MEM, MemToReg_MEM, MemWrite_MEM, RegWrite_MEM;
wire    MemToReg_WB, RegWrite_WB;

wire    [ 1:0]  Forward_ALU_A, Forward_ALU_B, Forward_EQ_A, Forward_EQ_B;
wire    [ 2:0]  ALUOp_ID, ALUOp_EX, ALUCtrl;
wire    [ 4:0]  RegDst_addr_EX, RegDst_addr_WB, RegDst_addr_MEM;
wire    [ 9:0]  Ctrl_Code;
wire    [31:0]  PC_Four_IF, PC_Four_ID, PC_Offset_IF;
wire    [31:0]  Mux_Branch, PCntr, Instr_IF, Instr_ID, Instr_EX
                Rs_Data_ID, Rt_Data_ID, Data_Offset, Mux_MemToReg, Immediate_ID, Immediate_EX,
                Mux_ALUSrc,Rs_Data_EX, Rt_Data_EX, ALUResult_MEM, MUX_A_ALUSrc, MUX_B_ALUSrc,
                ALUResult_EX, MUX_A_EQSrc, MUX_B_EQSrc, Rt_Data_MEM, MEM_Data_MEM, MEM_Data_WB,
                ALUResult_WB;

assign Data_Offset = Immediate_ID << 2;
assign PCSrc = Branch_ID & BranchTaken;

// ============================================================================
// ==== END ==== Check these signals later. Naming scheme too complicated.
// ============================================================================

// Program Control Signals
wire    PCSrc, BranchTaken, Branch_ID, Zero, Stall;
wire    RegDst_ctl_ID, Branch_ID, MemRead_ID, MemToReg_ID, ALUOp_ID,
                        MemWrite_ID, ALUSrc_ID, RegWrite_ID;
wire    RegDst_ctl_EX, MemRead_EX, MemToReg_EX, ALUOp_EX,
                        MemWrite_EX, ALUSrc_EX, RegWrite_EX;
wire    MemRead_MEM, MemToReg_MEM, MemWrite_MEM, RegWrite_MEM;
wire    MemToReg_WB, RegWrite_WB;

// Muxed output signals

/*
 * ============================================================================
 * ==== Instruction Fetch (IF) Stage
 * ============================================================================
 */

M__Mux2Mbit MUX_Branch #(.WIDTH(32)) (
    .dataA__i      (PC_Four_IF),       // PC + 4 (next instruction)
    .dataB__i      (PC_Offset_IF),   // PC + Branch offset
    .select__i     (PCSrc),                     // Branch taken (1) or not (0)
    .data__o       (PCNext_IF)                  // PC for the next instruction
    );

// Generate a new instruction every clock cycle.
// If stalled, the current address stays so no new instruction is fetched.
M__ProgramCounter Program_Counter (
    .clock__i       (clock__i),
    .reset_n__i     (reset_n__i),
    .address__i     (PCNext_IF),                // Result of the branch mux
    .address__o     (PC_IF),        // Next PC if not stalling
    .pcWrite__i     ((~Stall))                  // Pipeline stall signal
    );

M__Adder PC_Add_4 (
    .dataA__i       (PC_IF),        // Current instruction
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
    .dataB__i       ((Instruction_ID[15:0] << 2)),      // Immediate address
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
M__Mux2Mbit Control_Stall #(.WIDTH(10)) (
    .dataA__i       (10'b0),
    .dataB__i       (CtrlCode),
    .select__i      (Stall),
    .data__o        ({RegDst_ctl_ID, Branch_ID, MemRead_ID, MemToReg_ID, ALUOp_ID,
                        MemWrite_ID, ALUSrc_ID, RegWrite_ID})
    );

// dual read single write port register file.
M__RegFile Reg_File (
    .clock__i       (clock__i),
    .RegWrite__i    (RegWrite_WB)
    .AddrRs__i      (Instruction_ID[25:21]),
    .AddrRt__i      (Instruction_ID[20:16]),
    .AddrRd__i      (RegDst_addr_WB),
    .DataRd__i      (MemToReg_Data_Result),
    .DataRs__o      (RegRsData_ID),
    .DataRt__o      (RegRtData_ID),
    );

// Forwarding logic.
M__Mux3Mbit Mux_A_EQ #(.WIDTH(32)) (
    .dataA__i       (RegRsData_ID),
    .dataB__i       (MemToReg_Data_Result),
    .dataC__i       (ALUData_MEM),
    .select__i      (ALUForv_A),
    .data__o        (Mux_A_Equ)
    );

// Forwarding logic.
M__Mux3Mbit Mux_B_EQ #(.WIDTH(32)) (
    .dataA__i       (RegRtData_ID),
    .dataB__i       (MemToReg_Data_Result),
    .dataC__i       (ALUData_MEM),
    .select__i      (ALUForv_B),
    .data__o        (Mux_B_Equ)
    );

M__EqualityCheck EqualityCheck #(.WIDTH(32)) (
    .dataA__i       (Mux_A_Equ),
    .dataB__i       (Mux_B_Equ),
    .data__o        (BranchTaken)
    );

M__SignExtend Sign_Extend #(.WIDTH_I(16), .WIDTH_O(32)) (
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
M__Mux2Mbit Mux_RegDst #(.WIDTH(5)) (
    .dataA__i       (Instruction_EX[20:16]),
    .dataB__i       (Instruction_EX[15:11]),
    .select__i      (RegDst_ctl_EX),
    .data__o        (RegDst_addr_EX)
    );

// Forwarding between
//      original source
//      final result from retiring instruction
//      result from the previous instruction (currently in MEM stage)
M__Mux3Mbit Mux_A_ALU #(.WIDTH(32)) (
    .dataA__i       (RegRsData_EX),
    .dataB__i       (MemToReg_Data_Result),
    .dataC__i       (ALUData_MEM),
    .select__i      (ALUForv_A),
    .data__o        (mux_ALUSrc_A)
    );

// Forwarding between
//      original source
//      final result from retiring instruction
//      result from the previous instruction (currently in MEM stage)
M__Mux3Mbit Mux_B_ALU #(.WIDTH(32)) (
    .dataA__i       (RegRtData_EX),
    .dataB__i       (MemToReg_Data_Result),
    .dataC__i       (ALUData_MEM),
    .select__i      (ALUForv_B),
    .data__o        (mux_ALUSrc_B)
    );

// Check whether the input to ALU is immediate value or register data.
M__Mux2Mbit Mux_ALUSrc #(.WIDTH(32)) (
    .dataA__i       (mux_ALUSrc_B),
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
    .dataA__i       (mux_ALUSrc_A),
    .dataB__i       (mux_ALUSrc),
    .ALUCtrl__i     (ALUCtrl),
    .ALUResult__o   (ALUData_EX),
    .Zero__o        (Zero)
    );

M__EXMEM_Reg EX_MEM_Reg (
    .clock__i       (clock__i),
    .reset_n__i     (reset_n__i),
    .RegWrite__i    (RegWrite_EX),
    .MemToReg__i    (MemToReg_EX),
    .MemRead__i     (MemRead_EX),
    .MemWrite__i    (MemWrite_EX),
    .ALUData__i     (ALUData_EX),
    .MemWriteData__i(MemWriteData_EX),
    .WBReg__i       (RegDst_addr_EX),

    .RegWrite__o    (RegWrite_MEM),
    .MemToReg__o    (MemToReg_MEM),
    .MemRead__o     (MemRead_MEM),
    .MemWrite__o    (MemWrite_MEM),
    .ALUData__o     (ALUData_MEM),
    .MemWriteData__o(memDataWrite__o),
    .WBReg__o       (WBReg_MEM)
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
    .ALUData__i     (ALUData_MEM),
    .WBReg__i       (WBReg_MEM),

    .RegWrite__o    (RegWrite_WB),
    .MemToReg__o    (MemToReg_WB),
    .MemReadData__o (MemReadData_WB),
    .ALUData__o     (ALUData_WB),
    .WBReg__o       (RegDst_addr_WB)
    );

/*
 * ============================================================================
 * ==== Write Back (WB) Stage
 * ============================================================================
 */

M__Mux2Mbit Mux_MemToReg #(.WIDTH(32)) (
    .dataA__i       (ALUData_WB),
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
    .IFID_RegRs__i      (Instruction_ID[25:21]),
    .IFID_RegRt__i      (Instruction_ID[20:16]),
    .IDEX_RegRs__i      (Instruction_EX[25:21]),
    .IDEX_RegRt__i      (Instruction_EX[20:16]),
    .EXMEM_RegRd__i     (WBReg_MEM),
    .MEMWB_RegRd__i     (RegDst_addr_WB),
    .EXMEM_RegWrite__i  (RegWrite_MEM),
    .MEMWB_RegWrite__i  (RegWrite_WB),
    .Branch__i          (Branch_ID),
    .ALUForvA__o        (ALUForv_A),
    .ALUForvB__o        (ALUForv_B),
    .EQUForvA__o        (EQUForv_A),
    .EQUForvB__o        (EQUForv_B)
    );

/*
 * ============================================================================
 * ==== Hazard Detection
 * ============================================================================
 */

M__HazardDetect Hazard_Detect (
    .clock__i           (clock__i),
    .IDEX_MemRead__i    (MemRead_EX),
    .IDEX_RegWrite__i   (RegWrite_EX),
    .Branch__i          (CtrlCode[8]),
    .IFID_RegRs__i      (Instruction_ID[25:21]),
    .IFID_RegRt__i      (Instruction_ID[20:16]),
    .IDEX_RegRd__i      (RegDst_addr_EX),
    .Stall__o           (Stall)
    );

endmodule : M__MIPS_5_Stage
