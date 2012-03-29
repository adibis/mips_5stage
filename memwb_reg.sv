/*
 * ============================================================================
 *
 *  Name        :   M__MEMWB_Reg
 *  Author      :   Aditya Shevade
 *
 *  Description :   Pipeline register between MEM and WB stages.
 *
 * ============================================================================
 */

module M__MEMWB_Reg (
    input   wire            clock__i,
    input   wire            reset_n__i,
    input   wire            RegWrite__i,
    input   wire            MemToReg__i,
    input   wire    [31:0]  MemReadData__i,
    input   wire    [31:0]  ALUData__i,
    input   wire    [ 4:0]  WBReg__i,

    output  logic           RegWrite__o,
    output  logic           MemToReg__o,
    output  logic   [31:0]  MemReadData__o,
    output  logic   [31:0]  ALUData__o,
    output  logic   [ 4:0]  WBReg__o
);

    always @(posedge clock__i or negedge reset_n__i) begin
        if(~reset_n__i) begin
            RegWrite__o     <=  1'b0;
            MemtoReg__o     <=  1'b0;
            MemReadData__o  <= 32'b0;
            ALUData__o      <= 32'b0;
            WBReg__o        <=  5'b0;
        end else begin
            RegWrite__o     <= RegWrite__i;
            MemtoReg__o     <= MemtoReg__i;
            MemReadData__o  <= MemReadData__i;
            ALUData__o      <= ALUData__i;
            WBReg__o        <= WBReg__i;
        end
    end

endmodule : M__MEMWB_Reg
