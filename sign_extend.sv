/*
 * ============================================================================
 *
 *  Name        :   M__SignExtend
 *  Author      :   Aditya Shevade
 *
 *  Description :   Sign extension module that extends an M bit signed number
 *                  to an N bit signed number.
 *
 * ============================================================================
 */

module M__SignExtend #(
    parameter   WIDTH_I =   16,
                WIDTH_O =   32
    )(
    input   wire    [(WIDTH_I - 1): 0]  data__i,
    output  wire    [(WIDTH_O - 1): 0]  data__o
    );

    assign data__o =   {{(WIDTH_O - WIDTH_I){data__i[(WIDTH_I - 1)]}}, data__i};

endmodule : M__SignExtend
