/*
 * ============================================================================
 *
 *  Name        :   M__ProgramCounter
 *  Author      :   Aditya Shevade
 *
 *  Description :   The program counter.
 *
 * ============================================================================
 */

module M__ProgramCounter (
    input   wire            clock__i,
    input   wire            reset_n__i,
    input   wire            pcWrite__i,
    input   wire    [31:0]  address__i,
    output  logic   [31:0]  address__o
    );

    always @ (posedge clock__i or negedge reset_n__i)
        if (~reset_n__i)
            address__o  <=  32'b0;
        else if (pc_write)
            address__o  <=  address__i;

endmodule : M__ProgramCounter
