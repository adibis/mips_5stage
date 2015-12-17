/*
 * ============================================================================
 *
 *  Name        :   M__EXMEM_Reg
 *  Author      :   Aditya Shevade
 *
 *  Description :   Pipeline register between EX and MEM stages.
 *
 * ============================================================================
 */

module M__EXMEM_Reg (
    input   wire            clock__i,
    input   wire            reset_n__i,
    input   wire            RegWrite__i,
    input   wire            MemToReg__i,
    input   wire            MemRead__i,
    input   wire            MemWrite__i,
    input   wire    [31:0]  ALUData__i,
    input   wire    [31:0]  MemWriteData__i,
    input   wire    [ 4:0]  WBReg__i,

    output  logic           RegWrite__o,
    output  logic           MemToReg__o,
    output  logic           MemRead__o,
    output  logic           MemWrite__o,
    output  logic   [31:0]  ALUData__o,
    output  logic   [31:0]  MemWriteData__o,
    output  logic   [ 4:0]  WBReg__o
    );

    always @(posedge clock__i or negedge reset_n__i) begin
        if(~reset_n__i) begin
            RegWrite__o     <=  1'b0;
            MemToReg__o     <=  1'b0;
            MemRead__o      <=  1'b0;
            MemWrite__o     <=  1'b0;
            ALUData__o      <= 32'b0;
            MemWriteData__o <= 32'b0;
            WBReg__o        <=  5'b0;
        end else begin
            RegWrite__o     <= RegWrite__i;
            MemToReg__o     <= MemToReg__i;
            MemRead__o      <= MemRead__i;
            MemWrite__o     <= MemWrite__i;
            ALUData__o      <= ALUData__i;
            MemWriteData__o <= MemWriteData__i;
            WBReg__o        <= WBReg__i;
        end
    end

endmodule : M__EXMEM_Reg
