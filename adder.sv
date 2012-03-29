/*
 * ============================================================================
 *
 *  Name        :   M__Adder
 *  Author      :   Aditya Shevade
 *
 *  Description :   An M bit adder.
 *
 * ============================================================================
 */

module M__Adder #(
    parameter   WIDTH   =   32
    )(
    input   wire    [(WIDTH - 1): 0]    dataA__i,
    input   wire    [(WIDTH - 1): 0]    dataB__i,
    output  logic   [(WIDTH - 1): 0]    data__o
    );

    always @ (dataA__i or dataB__i)
        data__o = dataA__i + dataB__i;

endmodule : M__Adder
