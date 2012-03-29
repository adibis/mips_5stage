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
    .dataA__i      (),
    .dataB__i      (),
    .select__i     (),
    .data__o       ()
    );

M__ProgramCounter Program_Counter (
    .clock__i       (clock__i),
    .reset_n__i     (reset_n__i),
    .address__i     (),
    .address__o     (),
    .pcWrite__i     ()
    );

M__Adder PC_Add_4 (
    .dataA__i       (),
    .dataB__i       (32'h0000_0004),
    .data__o        ()
    );

//Instr_Memory Instr_Memory (
//    .address        (PCntr),
//    .instruction    (Instr_IF)
//    );

M__IFID_Reg IFID_Reg (
    .clock__i       (clock__i),
    .reset_n__i     (reset_n__i),
    .hazard__i      (),
    .flush__i       (),
    .PC_4__i        (),
    .instr__i       (),
    .PC_4__o        (),
    .instr__o       ()
    );

/*
 * ============================================================================
 * ==== Instruction Decode (ID) Stage
 * ============================================================================
 */

M__Adder PC_Add_Offset (
    .dataA__i       (),
    .dataB__i       (),
    .data__o        ()
    );

M__CPUControl CPU_Control (
    .opcode__i      (),
    .RegDst__o      (),
    .Branch__o      (),
    .MemRead__o     (),
    .MemToReg__o    (),
    .ALUOp__o       (),
    .MemWrite__o    (),
    .ALUSrc__o      (),
    .RegWrite__o    ()
    );

M__Mux2Mbit Control_Stall #(.WIDTH(10)) (
    .dataA__i       (10'b0),
    .dataB__i       (),
    .select__i      (),
    .data__o        ()
    );

M__RegFile Reg_File (
    .clock__i       (clock__i),
    .RegWrite__i    ()
    .AddrRs__i      (),
    .AddrRt__i      (),
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

Mux_2_5bit Mux_RegDst (
    .data_in_A      (Instr_EX[20:16]),
    .data_in_B      (Instr_EX[15:11]),
    .select         (RegDst_EX),
    .data_out       (Mux_RegDst_EX)
    );

Mux_2_32bit Mux_ALUSrc (
    .data_in_A      (Mux_B_ALUSrc),
    .data_in_B      (Immediate_EX),
    .select         (ALUSrc_EX),
    .data_out       (Mux_ALUSrc)
    );

Mux_3_32bit Mux_A_ALU (
    .data_in_A      (Rs_Data_Ex),
    .data_in_B      (Mux_MemToReg),
    .data_in_C      (ALUResult_MEM),
    .select         (Forward_A_ALU),
    .data_out       (Mux_A_ALUSrc)
    );

Mux_3_32bit Mux_B_ALU (
    .data_in_A      (Rt_Data_Ex),
    .data_in_B      (Mux_MemToReg),
    .data_in_C      (ALUResult_MEM),
    .select         (Forward_B_ALU),
    .data_out       (Mux_B_ALUSrc)
    );

ALU_Control ALU_Control (
    .ALU_Function   (Imediate_EX[5:0]),
    .ALUOp          (ALUOp_EX),
    .ALU_Ctrl       (ALU_Ctrl)
    );

ALU_Main ALU_Main (
    .data_in_A      (Mux_A_ALUSrc),
    .data_in_B      (Mux_ALUSrc),
    .ALU_Control    (ALU_Ctrl),
    .data_out       (ALUResult_EX),
    .Zero           (Zero)
    );

EX_MEM_Reg EX_MEM_Reg (
    .clock          (clock),
    .rst            (rst),
    .RegWrite_in    (RegWrite_EX),
    .MemToReg_in    (MemToReg_EX),
    .MemRead_in     (MemRead_EX),
    .MemWrite_in    (MemWrite_EX),
    .ALUData_in     (ALUResult_EX),
    .MemWriteData_in(Mux_B_ALUSrc),
    .WBReg_in       (Mux_RegDst_EX),

    .RegWrite_out   (RegWrite_MEM),
    .MemToReg_out   (MemToReg_MEM),
    .MemRead_out    (MemRead_MEM),
    .MemWrite_out   (MemWrite_MEM),
    .ALUData_out    (ALUResult_MEM),
    .MemWriteData_in(Rt_Data_MEM),
    .WBReg_out      (Mux_RegDst_MEM)
    );

/* ============================================================================
 * Memory Access (MEM) Stage
 * ============================================================================
 */

Data_Memory Data_Memory (
    .clock          (clock),
    .address        (ALUResult_MEM),
    .data_in        (Rt_Data_MEM),
    .MemRead        (MemRead_MEM),
    .MemWrite       (MemWrite_MEM),
    .data_out       (MemData_MEM)
    );

MEM_WB_Reg MEM_WB_Reg (
    .clock          (clock),
    .rst            (rst),
    .RegWrite_in    (RegWrite_MEM),
    .MemToReg_in    (MemToReg_MEM),
    .MemReadData_in (MemData_MEM),
    .ALUData_in     (ALUResult_MEM),
    .WBReg_in       (Mux_RegDst_MEM),

    .RegWrite_out   (RegWrite_WB),
    .MemToReg_out   (MemToReg_WB),
    .MemReadData_out(MemData_WB),
    .ALUData_out    (ALUResult_WB),
    .WBReg_in       (Mux_RegDst_WB)
    );

/* ============================================================================
 * Write Back (WB) Stage
 * ============================================================================
 */

Mux_2_32bit Mux_MemToReg (
    .data_in_A      (ALUResult_WB),
    .data_in_B      (MemData_WB),
    .select         (MemToReg_WB),
    .data_out       (Mux_MemToReg)
    );

/* ============================================================================
 * Data Forwarding
 * ============================================================================
 */

Forwarding_Unit Forwarding_Unit (
    .IFIDRegRs      (Instr_ID[25:21]),
    .IFIDRegRt      (Instr_ID[20:16]),
    .IDEXRegRs      (Instr_EX[25:21]),
    .IDEXRegRt      (Instr_EX[20:16]),
    .EXMEMRegRd     (RegWrite_MEM),
    .MEMWBRegRd     (Mux_RegDst_MEM),
    .EXMEMRegWrite  (RegWrite_WB),
    .MEMWBRegWrite  (Mux_RegDst_WB),
    .Branch         (Branch),
    .ALU_Forv_A     (Forward_A_ALU),
    .ALU_Forv_B     (Forward_B_ALU),
    .EQU_Forv_A     (Forward_A_EQ),
    .EQU_Forv_B     (Forward_B_EQ)
    );

/* ============================================================================
 * Hazard Detection
 * ============================================================================
 */

Hazard_Detection Hazard_Detection (
    .clock          (clock),
    .IDEXMemRead    (MemRead_EX),
    .IDEXRegWrite   (RegWrite_EX),
    .Branch         (Ctrl_Code[8]),
    .IFIDRegRs      (Instr_ID[25:21]),
    .IFIDRegRt      (Instr_ID[20:16]),
    .IDEXRegRd      (Mux_RegDst_EX),
    .Stall          (Stall)
    );

endmodule : M__MIPS_5_Stage
