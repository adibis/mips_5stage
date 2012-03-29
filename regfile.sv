/*
 * ============================================================================
 *
 *  Name        :   M__RegFile
 *  Author      :   Aditya Shevade
 *
 *  Description :   The general purpose Register file for the MIPS core.
 *                  Contains 32X32 bit registers.
 *
 * ============================================================================
 */

module M__RegFile (
    input   wire            clock__i,
    input   wire            RegWrite__i,
    input   wire    [ 4:0]  AddrRs__i,
    input   wire    [ 4:0]  AddrRt__i,
    input   wire    [ 4:0]  AddrRd__i,
    input   wire    [31:0]  DataRd__i,
    output  wire    [31:0]  DataRs__o,
    output  wire    [31:0]  DataRt__o
);

    logic   [31:0]  Register_File   [0:31];

    always @ (negedge clock__i) begin
        if (RegWrite__i)
            Register_File[AddrRd__i] <= DataRd__i;
    end

    assign  DataRs__o = (AddrRs__i == 5'b0) ? 32'b0 : Register_File[AddrRs__i];
    assign  DataRt__o = (AddrRt__i == 5'b0) ? 32'b0 : Register_File[AddrRt__i];

endmodule : M__RegFile
