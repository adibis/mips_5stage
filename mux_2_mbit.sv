/*
 * ============================================================================
 *
 *  Name        :   M__Mux2Mbit
 *  Author      :   Aditya Shevade
 *
 *  Description :   A 2 input mux with each input M bit wide.
 *
 * ============================================================================
 */

module M__Mux2Mbit #(
    parameter   WIDTH   =   8
    )(
    input   wire    [(WIDTH - 1): 0]    dataA__i,
    input   wire    [(WIDTH - 1): 0]    dataB__i,
    input   wire                        select__i,
    output  wire    [(WIDTH - 1): 0]    data__o
    );

    assign data__o  = (select__i) ? dataB__i : dataA__i;

endmodule : M__Mux2Mbit
