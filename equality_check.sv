/*
 * ============================================================================
 *
 *  Name        :   M__EqualityCheck
 *  Author      :   Aditya Shevade
 *
 *  Description :   A generic equality checker returns 1 if equal else zero.
 *
 * ============================================================================
 */

module M__EqualityCheck #(
    parameter   WIDTH   =   32
    ) (
    input   wire    [(WIDTH - 1): 0]    dataA__i,
    input   wire    [(WIDTH - 1): 0]    dataB__i,
    output  wire                        result__o
    );

    assign result__o =   (dataA__i == dataB__i) ? 1'b1 : 1'b0;

endmodule : M__EqualityCheck
