/*
 * ============================================================================
 *
 *  Name        :   M__ForwardingUnit
 *  Author      :   Aditya Shevade
 *
 *  Description :   Used for forwarding data between stages.
 *
 * ============================================================================
 */

module M__ForwardingUnit (
    input   wire            reset_n__i,
    input   wire    [4:0]   IFID_RegRs__i,
    input   wire    [4:0]   IFID_RegRt__i,
    input   wire    [4:0]   IDEX_RegRs__i,
    input   wire    [4:0]   IDEX_RegRt__i,
    input   wire    [4:0]   EXMEM_RegRd__i,
    input   wire    [4:0]   MEMWB_RegRd__i,
    input   wire            EXMEM_RegWrite__i,
    input   wire            MEMWB_RegWrite__i,
    input   wire            Branch__i,
    output  logic   [1:0]   ALUForvA__o,
    output  logic   [1:0]   ALUForvB__o,
    output  logic   [1:0]   EQUForvA__o,
    output  logic   [1:0]   EQUForvB__o
);

    always @ (negedge reset_n__i) begin
        if (~reset_n__i) begin
            ALUForvA__o  =   2'b00;
            ALUForvB__o  =   2'b00;
            EQUForvA__o  =   2'b00;
            EQUForvB__o  =   2'b00;
        end
    end

    always @(IFID_RegRs__i or IFID_RegRt__i or IDEX_RegRs__i or IDEX_RegRt__i or EXMEM_RegRd__i or MEMWB_RegRd__i or EXMEM_RegWrite__i or MEMWB_RegWrite__i) begin
        if (reset_n__i) begin
            if (EXMEM_RegWrite__i && (EXMEM_RegRd__i != 5'b0) && (EXMEM_RegRd__i == IDEX_RegRs__i))
                ALUForvA__o  <=  2'b10;
            else if (MEMWB_RegWrite__i && (MEMWB_RegRd__i != 5'b0) && (MEMWB_RegRd__i == IDEX_RegRs__i))
                ALUForvA__o  <=  2'b01;
            else
                ALUForvA__o  <=  2'b00;

            if (EXMEM_RegWrite__i && (EXMEM_RegRd__i != 5'b0) && (EXMEM_RegRd__i == IDEX_RegRt__i))
                ALUForvB__o  <=  2'b10;
            else if (MEMWB_RegWrite__i && (MEMWB_RegRd__i != 5'b0) && (MEMWB_RegRd__i == IDEX_RegRt__i))
                ALUForvB__o  <=  2'b01;
            else
                ALUForvB__o  <=  2'b00;

            if (Branch__i) begin
                if (EXMEM_RegWrite__i && (EXMEM_RegRd__i != 5'b0) && (EXMEM_RegRd__i == IFID_RegRs__i))
                    EQUForvA__o  <=  2'b10;
                else if (MEMWB_RegWrite__i && (MEMWB_RegRd__i != 5'b0) && (MEMWB_RegRd__i == IFID_RegRs__i))
                    EQUForvA__o  <=  2'b01;
                else
                    EQUForvA__o  <=  2'b00;

                if (EXMEM_RegWrite__i && (EXMEM_RegRd__i != 5'b0) && (EXMEM_RegRd__i == IFID_RegRt__i))
                    EQUForvB__o  <=  2'b10;
                else if (MEMWB_RegWrite__i && (MEMWB_RegRd__i != 5'b0) && (MEMWB_RegRd__i == IFID_RegRt__i))
                    EQUForvB__o  <=  2'b01;
                else
                    EQUForvB__o  <=  2'b00;
            end
        end
    end

endmodule : M__ForwardingUnit
