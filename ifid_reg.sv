/*
 * ============================================================================
 *
 *  Name        :   M__IFID_Reg
 *  Author      :   Aditya Shevade
 *
 *  Description :   Pipeline register between IF and ID stages.
 *
 * ============================================================================
 */

module M__IFID_Reg (
    input   wire            clock__i,
    input   wire            reset_n__i,
    input   wire            hazard__i,
    input   wire            flush__i,
    input   wire    [31:0]  PC_4__i,
    input   wire    [31:0]  instr__i,
    output  logic   [31:0]  PC_4__o,
    output  logic   [31:0]  instr__o
    );

    always @(posedge clock__i or negedge reset_n__i) begin
        if (~reset_n__i or flush__i) begin  // Reset or flush pipeline
            PC_4__o     <= 32'b0;
            instr__o    <= 32'b0;
        end else if (hazard__i) begin       // Hazard detected - stall pipeline
            PC_4__o     <= PC_4__o;         // Keep the PC and previous instruction
            instr__o    <= instr__o;
        end else begin
            PC_4__o     <= PC_4__i;         // Else relay the input to output
            instr__o    <= instr__i;
        end
    end

endmodule : M__IFID_Reg
