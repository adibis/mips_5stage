// UCA 2010
//=========================================================
// Pipelined MIPS CPU
//=========================================================
// Supported instructions
// R-type: add, sub, and, or, slt
// I-type: addi, andi, ori, lw, sw, beq
//
//=========================================================
// Input/Output Signals:
// positive-edge triggered clock    clk
// active low asynchronous reset    rst_n
//
//=========================================================
// Wire/Reg Specifications:
// control signals                  RegDST, Branch, MemRead,
//                                  MemtoReg, ALUOp, MemWrite,   
//                                  ALUSrc, RegWrite
// MUX output signals               MUX_RegDST, MUX_ALUSrc, 
//                                  MUX_Branch, MUX_MemtoReg
//
//=========================================================

module Pipelined_CPU(
    clk,
    rst_n
);

// input/output declaration
input   clk, rst_n;

// Wire/Reg declaration
wire        Branch_Zero, PCWrite, IFIDWrite,
            Stall, RegDST_ID, Branch, MemRead_ID, MemtoReg_ID, MemWrite_ID, ALUSrc_ID, RegWrite_ID, Branch_Taken, 
            RegWrite_EX, MemtoReg_EX, MemRead_EX, MemWrite_EX, ALUSrc_EX, RegDST_EX, Zero, 
	    RegWrite_MEM, MemtoReg_MEM, MemRead_MEM, MemWrite_MEM,
	    RegWrite_WB, MemtoReg_WB;
wire [1:0]  ForwardA_ALU, ForwardB_ALU, ForwardA_EQ, ForwardB_EQ;
wire [2:0]  ALUOp_ID, ALUOp_EX, ALUCtrl;
wire [4:0]  mux_RegDST_EX, mux_RegDST_WB, mux_RegDST_MEM;
wire [9:0]  Ctrl_Code;
wire [31:0] PC_4_IF, PC_Offset, mux_Branch, pc, Instr_IF, PC_4_ID, Instr_ID, Rs_Data_ID, Rt_Data_ID,
            Offset, mux_MemtoReg, Immediate_ID, Immediate_EX, Instr_EX,
            mux_ALUSrc, Rs_Data_EX, Rt_Data_EX, ALUResult_MEM, muxA_ALUsrc, muxB_ALUsrc, ALUResult_EX, muxA_EQsrc, muxB_EQsrc,
	    Rt_Data_MEM, MemData_MEM, MemData_WB, ALUResult_WB;
assign Offset = Immediate_ID << 2;
assign Branch_Zero = Branch & Branch_Taken;
  
// IF: Instruction fetch

MUX_2x32bit MUX_Branch(    
    .data0_in	(PC_4_IF),
    .data1_in	(PC_Offset),
    .select		(Branch_Zero),
    .data_out	(mux_Branch)
);

PC PC(
    .clk        (clk),
    .rst_n      (rst_n),
    .pc_in      (mux_Branch),
    .pc_out     (pc),
    .pcWrite	   (~Stall)
);

Adder PC_Add_4(
    .data1_in   (pc),
    .data2_in   (32'd4),
    .data_out   (PC_4_IF)
);

Instr_Memory Instr_Memory(
    .addr       (pc), 
    .instr      (Instr_IF)
);

IF_ID IF_ID(
	.clk		(clk),
	.rst		(rst_n),
	.PC_4_in	(PC_4_IF),
	.instr_in	(Instr_IF),
	.hazard_in	(~Stall),
	.flush_in	(Branch_Zero),
	.PC_4_out	(PC_4_ID),
	.instr_out	(Instr_ID)
);

// ID: Instruction decode

Adder PC_Add_Offset(
    .data1_in   (PC_4_ID),
    .data2_in   (Offset),
    .data_out   (PC_Offset)
);

Control Control(
    .opcode     (Instr_ID[31:26]),
    .RegDst     (Ctrl_Code[9]),
    .Branch     (Ctrl_Code[8]),
    .MemRead    (Ctrl_Code[7]),
    .MemtoReg   (Ctrl_Code[6]),
    .ALUOp      (Ctrl_Code[5:3]),
    .MemWrite   (Ctrl_Code[2]),
    .ALUSrc     (Ctrl_Code[1]),
    .RegWrite   (Ctrl_Code[0])
);

MUX_10bit Control_Stall(
	.data1_in	(10'b0),
	.data2_in	(Ctrl_Code),
	.select_in	(Stall),
	.data_out	({RegDST_ID, Branch, MemRead_ID, MemtoReg_ID, ALUOp_ID, MemWrite_ID,
					ALUSrc_ID, RegWrite_ID})
);

Register_File Register_File(
    .clk        (clk),
    .Rs_addr    (Instr_ID[25:21]),
    .Rt_addr    (Instr_ID[20:16]),
    .Rd_addr    (mux_RegDST_WB), 
    .Rd_data    (mux_MemtoReg),
    .RegWrite   (RegWrite_WB), 
    .Rs_data    (Rs_Data_ID), 
    .Rt_data    (Rt_Data_ID) 
);

MUX_3x32bit MUX_A_EQ(    
    .data0_in	(Rs_Data_ID),
    .data1_in	(mux_MemtoReg),
    .data2_in	(ALUResult_MEM),
    .select		(ForwardA_ALU),
    .data_out	(muxA_EQsrc)
);

MUX_3x32bit MUX_B_EQ(    
    .data0_in	(Rt_Data_ID),
    .data1_in	(mux_MemtoReg),
    .data2_in	(ALUResult_MEM),
    .select		(ForwardB_ALU),
    .data_out	(muxB_EQsrc)
);

Equal Equal(
    .input1		(muxA_EQsrc),
    .input2		(muxB_EQsrc),
    .result		(Branch_Taken)
);

Signed_Extend Signed_Extend(
    .data_in    (Instr_ID[15:0]),
    .data_out   (Immediate_ID)
);

ID_EX ID_EX(
	.clk					(clk),
	.rst					(rst_n),
	.RegWrite_in			(RegWrite_ID),
	.MemtoReg_in			(MemtoReg_ID),
	.MemRead_in				(MemRead_ID),
	.MemWrite_in			(MemWrite_ID),
	.ALUSrc_in				(ALUSrc_ID),
	.ALUOp_in				(ALUOp_ID),
	.RegDst_in				(RegDST_ID),
	.RegRsData_in			(Rs_Data_ID),
	.RegRtData_in			(Rt_Data_ID),
	.Immediate_in			(Immediate_ID),
	.instr_Rs_addr_in		(Instr_ID[25:21]),
	.instr_Rt_addr_in		(Instr_ID[20:16]),
	.instr_Rd_addr_in		(Instr_ID[15:11]),
	.RegWrite_out			(RegWrite_EX),
	.MemtoReg_out			(MemtoReg_EX),
	.MemRead_out			(MemRead_EX),
	.MemWrite_out			(MemWrite_EX),
	.ALUSrc_out				(ALUSrc_EX),
	.ALUOp_out				(ALUOp_EX),
	.RegDst_out				(RegDST_EX),
	.RegRsData_out			(Rs_Data_EX),
	.RegRtData_out			(Rt_Data_EX),
	.Immediate_out			(Immediate_EX),
	.instr_Rs_addr_out		(Instr_EX[25:21]),
	.instr_Rt_addr_out		(Instr_EX[20:16]),
	.instr_Rd_addr_out		(Instr_EX[15:11])
);


// EX: Execute

MUX_5bit MUX_RegDst(
    .data1_in   (Instr_EX[20:16]),
    .data2_in   (Instr_EX[15:11]),
    .select     (RegDST_EX),
    .data_out   (mux_RegDST_EX)
);

MUX_2x32bit MUX_ALUSrc(
    .data0_in   (muxB_ALUsrc),
    .data1_in   (Immediate_EX),
    .select     (ALUSrc_EX),
    .data_out   (mux_ALUSrc)
);

MUX_3x32bit MUX_A_ALU(    
    .data0_in	(Rs_Data_EX),
    .data1_in	(mux_MemtoReg),
    .data2_in	(ALUResult_MEM),
    .select		(ForwardA_ALU),
    .data_out	(muxA_ALUsrc)
);

MUX_3x32bit MUX_B_ALU(    
    .data0_in	(Rt_Data_EX),
    .data1_in	(mux_MemtoReg),
    .data2_in	(ALUResult_MEM),
    .select		(ForwardB_ALU),
    .data_out	(muxB_ALUsrc)
);

ALU_Control ALU_Control(
    .funct      (Immediate_EX[5:0]),
    .ALUOp      (ALUOp_EX),
    .ALUCtrl    (ALUCtrl)
);
  
ALU ALU(
    .data1_in   (muxA_ALUsrc),
    .data2_in   (mux_ALUSrc),
    .ALUCtrl    (ALUCtrl),
    .data       (ALUResult_EX),
    .Zero       (Zero)
);

EX_MEM EX_MEM(
	.clk				(clk),
	.rst				(rst_n),
	.RegWrite_in		(RegWrite_EX),	// WB
	.MemtoReg_in		(MemtoReg_EX),	// WB
	.MemRead_in			(MemRead_EX),		// M
	.MemWrite_in		(MemWrite_EX),	// M
	.ALUData_in			(ALUResult_EX),
	.MemWriteData_in	(muxB_ALUsrc),
	.WBregister_in		(mux_RegDST_EX),
	.RegWrite_out		(RegWrite_MEM),	// WB
	.MemtoReg_out		(MemtoReg_MEM),	// WB
	.MemRead_out		(MemRead_MEM),	// M
	.MemWrite_out		(MemWrite_MEM),
	.ALUData_out		(ALUResult_MEM),
	.MemWriteData_out	(Rt_Data_MEM),
	.WBregister_out		(mux_RegDST_MEM)
);


// MEM: Memory access

Data_Memory Data_Memory(
    .clk        (clk),
    .addr       (ALUResult_MEM),
    .data_in    (Rt_Data_MEM),
    .MemRead    (MemRead_MEM),
    .MemWrite   (MemWrite_MEM),
    .data_out   (MemData_MEM)
);

MEM_WB MEM_WB(
	.clk			(clk),
	.rst			(rst_n),
	.RegWrite_in	(RegWrite_MEM),	// WB
	.MemtoReg_in	(MemtoReg_MEM),	// WB
	.MemData_in		(MemData_MEM),
	.ALUData_in		(ALUResult_MEM),
	.WBregister_in	(mux_RegDST_MEM),
	.RegWrite_out	(RegWrite_WB),	// WB
	.MemtoReg_out	(MemtoReg_WB),	// WB
	.MemData_out	(MemData_WB),
	.ALUData_out	(ALUResult_WB),
	.WBregister_out (mux_RegDST_WB)
);


// WB: Write back

MUX_2x32bit MUX_MemtoReg(
    .data0_in   (ALUResult_WB),
    .data1_in   (MemData_WB),
    .select     (MemtoReg_WB),
    .data_out   (mux_MemtoReg)
);


// Forwarding

Forwarding Forwarding(
    .IfIdRegRs (Instr_ID[25:21]),
    .IfIdRegRt (Instr_ID[20:16]),
    .IdExRegRs		(Instr_EX[25:21]),
    .IdExRegRt		(Instr_EX[20:16]),
    .ExMemRegWrite	(RegWrite_MEM),
    .ExMemRegRd		(mux_RegDST_MEM),
    .MemWbRegWrite	(RegWrite_WB),
    .MemWbRegRd		(mux_RegDST_WB),
    .Branch (Branch),
    .ForwardA_ALU (ForwardA_ALU),	
    .ForwardB_ALU (ForwardB_ALU), 
    .ForwardA_EQ (ForwardA_EQ),
    .ForwardB_EQ (ForwardB_EQ)
);

// Hazard Detection

Hazard_Detection Hazard_Detection(
    .IFIDRegRs		(Instr_ID[25:21]),
    .IFIDRegRt		(Instr_ID[20:16]),
    .IDEXMemRead	(MemRead_EX),
    .IDEXRegDST (mux_RegDST_EX),
    .Branch (Ctrl_Code[8]),
    .IDEXRegWrite (RegWrite_EX),
    .Stall			(Stall),
    .clk (clk)
);

endmodule