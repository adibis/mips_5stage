/*
 * ============================================================================
 *
 *  Name        :   M__IDEX_Reg
 *  Author      :   Aditya Shevade
 *
 *  Description :   Pipeline register between ID and EX stages.
 *
 * ============================================================================
 */

module M__IDEX_Reg (
    input   wire            clock__i,
    input   wire            reset_n__i,
    input   wire            RegWrite__i,
    input   wire            MemToReg__i,
    input   wire            MemRead__i,
    input   wire            MemWrite__i,
    input   wire            ALUSrc__i,
    input   wire    [ 2:0]  ALUOp__i,
    input   wire            RegDst__i,
    input   wire    [31:0]  RegRsData__i,
    input   wire    [31:0]  RegRtData__i,
    input   wire    [31:0]  Immediate__i,
    input   wire    [ 4:0]  InstrRsAddr__i,
    input   wire    [ 4:0]  InstrRtAddr__i,
    input   wire    [ 4:0]  InstrRdAddr__i,

    output  logic           RegWrite__o,
    output  logic           MemToReg__o,
    output  logic           MemRead__o,
    output  logic           MemWrite__o,
    output  logic           ALUSrc__o,
    output  logic   [ 2:0]  ALUOp__o,
    output  logic           RegDst__o,
    output  logic   [31:0]  RegRsData__o,
    output  logic   [31:0]  RegRtData__o,
    output  logic   [31:0]  Immediate__o,
    output  logic   [ 4:0]  InstrRsAddr__o,
    output  logic   [ 4:0]  InstrRtAddr__o,
    output  logic   [ 4:0]  InstrRdAddr__o
);

    always @(posedge clock__i or negedge reset_n__i) begin
        if (~reset_n__i) begin  // If reset, set everything to zero
            RegWrite__o     <=  1'b0;
            MemToReg__o     <=  1'b0;
            MemRead__o      <=  1'b0;
            MemWrite__o     <=  1'b0;
            ALUSrc__o       <=  1'b0;
            ALUOp__o        <=  3'b0;
            RegDst__o       <=  1'b0;
            RegRsData__o    <= 32'b0;
            RegRtData__o    <= 32'b0;
            Immediate__o    <= 32'b0;
            InstrRsAddr__o  <=  5'b0;
            InstrRtAddr__o  <=  5'b0;
            InstrRdAddr__o  <=  5'b0;
        end else begin          // If not reset then relay the input to output
            RegWrite__o     <= RegWrite__i;
            MemToReg__o     <= MemToReg__i;
            MemRead__o      <= MemRead__i;
            MemWrite__o     <= MemWrite__i;
            ALUSrc__o       <= ALUSrc__i;
            ALUOp__o        <= ALUOp__i;
            RegDst__o       <= RegDst__i;
            RegRsData__o    <= RegRsData__i;
            RegRtData__o    <= RegRtData__i;
            Immediate__o    <= Immediate__i;
            InstrRsAddr__o  <= InstrRsAddr__i;
            InstrRtAddr__o  <= InstrRtAddr__i;
            InstrRdAddr__o  <= InstrRdAddr__i;
        end
    end

endmodule : M__IDEX_Reg
