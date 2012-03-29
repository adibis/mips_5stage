/* ============================================================================
 *
 *  Name        :   M__ALUMain
 *  Author      :   Aditya Shevade
 *
 *  Description :   The ALU of the MIPS processor. Receives the control bits
 *                  from the ALU_Control module.
 *                  Implemented Instructions: ADD, ADDI, SUB, AND, ANDI, OR,
 *                  ORI, SLT, LW, SW, BEQ.
 *
 * TODO:
 *          1. Add support for arithmetic and logical shift right and left.
 *          2. Add support for inversion, xor, nand, nor, etc.
 *          3. Add support for immediate subtraction (subi).
 *          4. Add support for unsigned addition and subtraction.
 *          5. Add support for SLTU (Set less than for unsigned numbers).
 *
 * ============================================================================
 */

module M__ALUMain (
    input   wire    [31:0]  dataA__i,
    input   wire    [31:0]  dataB__i,
    input   wire    [ 2:0]  ALUControl__o,  // Operation code
    output  logic   [31:0]  ALUResult__o,
    output  logic           Zero__o
    );

    always @ (dataA__i or dataB__i or ALUControl__o) begin
        case (ALUControl__o)
            3'b010: // ADD, LW, SW
            begin
                ALUResult__o = dataA__i + dataB__i;
            end

            3'b110: // SUB, BEQ
            begin
                ALUResult__o = dataA__i - dataB__i;
            end

            3'b000: // AND
            begin
                ALUResult__o = dataA__i & dataB__i;
            end

            3'b001: // OR
            begin
                ALUResult__o = dataA__i | dataB__i;
            end

            3'b111: // SLT
            begin
                if ((dataA__i - dataB__i) < 0)
                    ALUResult__o = 32'b1;
                else
                    ALUResult__o = 32'b0;
            end

            default:
            begin
                ALUResult__o =  32'b1;
                Zero__o      =   1'b0;
            end
        endcase

        // The zero signal is mainly used by the branch
        if (ALUResult__o == 32'b0) begin
            Zero__o = 1'b1;
        end else begin
            Zero__o = 1'b0;
        end

    end

endmodule : M__ALUMain
