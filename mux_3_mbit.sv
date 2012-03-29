/*
 * ============================================================================
 *
 *  Name        :   M__Mux3Mbit
 *  Author      :   Aditya Shevade
 *
 *  Description :   A 3 input mux with each input M bit wide.
 *
 * ============================================================================
 */

module M__Mux3Mbit #(
    parameter   WIDTH   =   8
    )(
    input   wire    [(WIDTH - 1): 0]    dataA__i,
    input   wire    [(WIDTH - 1): 0]    dataB__i,
    input   wire    [(WIDTH - 1): 0]    dataC__i,
    input   wire              [1: 0]    select__i,
    output  wire    [(WIDTH - 1): 0]    data__o
    );

    assign data__o  = (select__i[1]) ? dataC__i : ((select__i[0]) ? dataB__i : dataA__i);

endmodule : M__Mux3Mbit
