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
wire    Branch_Zero, PCWrite, IFIDWrite, Stall, Branch, Branch_Taken, Zero;
wire    RegDst_ID, MemRead_ID, MemToReg_ID, MemWrite_ID, ALUSrc_ID, RegWrite_ID;
wire    RegDst_EX, MemRead_EX, MemToReg_EX, MemWrite_EX, ALUSrc_EX, RegWrite_EX;
wire    MemRead_MEM, MemToReg_MEM, MemWrite_MEM, RegWrite_MEM;
wire    MemToReg_WB, RegWrite_WB;

wire    [ 1:0]  Forward_ALU_A, Forward_ALU_B, Forward_EQ_A, Forward_EQ_B;
wire    [ 2:0]  ALUOp_ID, ALUOp_EX, ALUCtrl;
wire    [ 4:0]  Mux_RegDst_EX, Mux_RegDst_WB, Mux_RegDst_MEM;
wire    [ 9:0]  Ctrl_Code;
wire    [31:0]  PC_Four_IF, PC_Four_ID, PC_Offset, Mux_Branch, PCntr, Instr_IF, Instr_ID, Instr_EX
                Rs_Data_ID, Rt_Data_ID, Data_Offset, Mux_MemToReg, Immediate_ID, Immediate_EX,
                Mux_ALUSrc,Rs_Data_EX, Rt_Data_EX, ALUResult_MEM, MUX_A_ALUSrc, MUX_B_ALUSrc,
                ALUResult_EX, MUX_A_EQSrc, MUX_B_EQSrc, Rt_Data_MEM, MEM_Data_MEM, MEM_Data_WB,
                ALUResult_WB;

assign Data_Offset = Immediate_ID << 2;
assign Branch_Zero = Branch & Branch_Taken;

// ============================================================================
// ==== END ==== Check these signals later. Naming scheme too complicated.
// ============================================================================

/*
 * ============================================================================
 * ==== Instruction Fetch (IF) Stage
 * ============================================================================
 */

M__Mux2Mbit MUX_Branch #(.WIDTH(32)) (
    .dataA__i      (ProgramCounter_4_IF),
    .dataB__i      (ProgramCounterOffset_IF),
    .select__i     (BranchZero_IF),
    .data__o       (BranchMuxResult_IF)
    );

M__ProgramCounter Program_Counter (
    .clock__i       (clock__i),
    .reset_n__i     (reset_n__i),
    .address__i     (BranchMuxResult_IF),
    .address__o     (ProgramCounter_IF),
    .pcWrite__i     ()
    );

M__Adder PC_Add_4 (
    .dataA__i       (ProgramCounter_IF),
    .dataB__i       (32'h0000_0004),
    .data__o        (ProgramCounter_4_IF)
    );

//Instr_Memory Instr_Memory (
//    .address        (),
//    .instruction    ()
//    );

M__IFID_Reg IFID_Reg (
    .clock__i       (clock__i),
    .reset_n__i     (reset_n__i),
    .hazard__i      (),
    .flush__i       (),
    .PC_4__i        (ProgramCounter_4_IF),
    .instr__i       (Instruction_IF),
    .PC_4__o        (ProgramCounter_4_ID),
    .instr__o       (Instruction_ID)
    );

/*
 * ============================================================================
 * ==== Instruction Decode (ID) Stage
 * ============================================================================
 */

M__Adder PC_Add_Offset (
    .dataA__i       (ProgramCounter_4_ID),
    .dataB__i       (Offset),
    .data__o        (ProgramCounterOffset_IF)
    );

M__CPUControl CPU_Control (
    .opcode__i      (Instruction_ID[31:26]),
    .RegDst__o      (CtrlCode[9]),
    .Branch__o      (CtrlCode[8]),
    .MemRead__o     (CtrlCode[7]),
    .MemToReg__o    (CtrlCode[6]),
    .ALUOp__o       (CtrlCode[5:3]),
    .MemWrite__o    (CtrlCode[2]),
    .ALUSrc__o      (CtrlCode[1]),
    .RegWrite__o    (CtrlCode[0])
    );

M__Mux2Mbit Control_Stall #(.WIDTH(10)) (
    .dataA__i       (10'b0),
    .dataB__i       (CtrlCode),
    .select__i      (),
    .data__o        ({RegDst_ID, Branch_ID, MemRead_ID, MemToReg_ID, ALUOp_ID,
                        MemWrite_ID, ALUSrc_ID, RegWrite_ID})
    );

M__RegFile Reg_File (
    .clock__i       (clock__i),
    .RegWrite__i    ()
    .AddrRs__i      (Instruction_ID[25:21]),
    .AddrRt__i      (Instruction_ID[20:16]),
    .AddrRd__i      (),
    .DataRd__i      (),
    .DataRs__o      (),
    .DataRt__o      (),
    );

M__Mux3Mbit Mux_A_EQ #(.WIDTH(32)) (
    .dataA__i       (),
    .dataB__i       (),
    .dataC__i       (),
    .select__i      (),
    .data__o        ()
    );

M__Mux3Mbit Mux_B_EQ #(.WIDTH(32)) (
    .dataA__i       (),
    .dataB__i       (),
    .dataC__i       (),
    .select__i      (),
    .data__o        ()
    );

M__EqualityCheck EqualityCheck #(.WIDTH(32)) (
    .dataA__i       (),
    .dataB__i       (),
    .data__o        ()
    );

M__SignExtend Sign_Extend #(.WIDTH_I(16), .WIDTH_O(32)) (
    .data__i        (),
    .data__o        ()
    );

M__IDEX_Reg ID_EX_Reg (
    .clock__i       (clock__i),
    .reset_n__i     (reset_n__i),
    .RegWrite__i    (),
    .MemToReg__i    (),
    .MemRead__i     (),
    .MemWrite__i    (),
    .ALUSrc__i      (),
    .ALUOp__i       (),
    .RegDst__i      (),
    .RegRsData__i   (),
    .RegRtData__i   (),
    .Immediate__i   (),
    .InstrRsAddr__i (),
    .InstrRtAddr__i (),
    .InstrRdAddr__i (),

    .RegWrite__o    (),
    .MemToReg__o    (),
    .MemRead__o     (),
    .MemWrite__o    (),
    .ALUSrc__o      (),
    .ALUOp__o       (),
    .RegDst__o      (),
    .RegRsData__o   (),
    .RegRtData__o   (),
    .Immediate__o   (),
    .InstrRsAddr__o (),
    .InstrRtAddr__o (),
    .InstrRdAddr__o ()
    );

/*
 * ============================================================================
 * ==== Instruction Execute (EX) Stage
 * ============================================================================
 */

M__Mux2Mbit Mux_RegDst #(.WIDTH(5)) (
    .dataA__i       (),
    .dataB__i       (),
    .select__i      (),
    .data__o        ()
    );

M__Mux2Mbit Mux_ALUSrc #(.WIDTH(32)) (
    .dataA__i       (),
    .dataB__i       (),
    .select__i      (),
    .data__o        ()
    );

M__Mux3Mbit Mux_A_ALU #(.WIDTH(32)) (
    .dataA__i       (),
    .dataB__i       (),
    .dataC__i       (),
    .select__i      (),
    .data__o        ()
    );

M__Mux3Mbit Mux_B_ALU #(.WIDTH(32)) (
    .dataA__i       (),
    .dataB__i       (),
    .dataC__i       (),
    .select__i      (),
    .data__o        ()
    );

M__ALUControl ALU_Control (
    .ALUFunction__i (),
    .ALUOp__i       (),
    .ALUCtrl__o     ()
    );

M__ALUMain ALU_Main (
    .dataA__i       (),
    .dataB__i       (),
    .ALUControl__i  (),
    .data__o        (),
    .Zero__o        ()
    );

M__EXMEM_Reg EX_MEM_Reg (
    .clock__i       (clock__i),
    .reset_n__i     (reset_n__i),
    .RegWrite__i    (),
    .MemToReg__i    (),
    .MemRead__i     (),
    .MemWrite__i    (),
    .ALUData__i     (),
    .MemWriteData__i(),
    .WBReg__i       (),

    .RegWrite__o    (),
    .MemToReg__o    (),
    .MemRead__o     (),
    .MemWrite__o    (),
    .ALUData__o     (),
    .MemWriteData__o(),
    .WBReg__o       ()
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
    .RegWrite__i    (),
    .MemToReg__i    (),
    .MemReadData__i (),
    .ALUData__i     (),
    .WBReg__i       (),

    .RegWrite__o    (),
    .MemToReg__o    (),
    .MemReadData__o (),
    .ALUData__o     (),
    .WBReg__o       ()
    );

/*
 * ============================================================================
 * ==== Write Back (WB) Stage
 * ============================================================================
 */

M__Mux2Mbit Mux_MemToReg #(.WIDTH(32)) (
    .dataA__i       (),
    .dataB__i       (),
    .select__i      (),
    .data__o        ()
    );

/*
 * ============================================================================
 * ==== Data Forwarding
 * ============================================================================
 */

M__ForwardingUnit Forwarding_Unit (
    .IFID_RegRs__i      (),
    .IFID_RegRt__i      (),
    .IDEX_RegRs__i      (),
    .IDEX_RegRt__i      (),
    .EXMEM_RegRd__i     (),
    .MEMWB_RegRd__i     (),
    .EXMEM_RegWrite__i  (),
    .MEMWB_RegWrite__i  (),
    .Branch__i          (),
    .ALUForvA__o        (),
    .ALUForvB__o        (),
    .EQUForvA__o        (),
    .EQUForvB__o        ()
    );

/*
 * ============================================================================
 * ==== Hazard Detection
 * ============================================================================
 */

M__HazardDetect Hazard_Detect (
    .clock__i           (clock__i),
    .IDEX_MemRead__i    (),
    .IDEX_RegWrite__i   (),
    .Branch__i          (),
    .IFID_RegRs__i      (),
    .IFID_RegRt__i      (),
    .IDEX_RegRd__i      (),
    .Stall__o           ()
    );

endmodule : M__MIPS_5_Stage
