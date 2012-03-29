/*
 * ============================================================================
 *
 *  Name        :   M__ALUControl
 *  Author      :   Aditya Shevade
 *
 *  Description :   Generates control signals for the ALU.
 *
 *  Generating ALU Signals:
 *  -----------------------
 *  ALUOp        Function        ALUCtrl     Instr. Opcode
 *  -----        --------        -------     -------------
 *  010          xxxxxx          010         lw, sw, addi (same as add)
 *  011          xxxxxx          110         beq (same as sub)
 *  000          xxxxxx          000         andi (same as and)
 *  001          xxxxxx          001         ori (same as or)
 *  100          100000          010         add
 *  100          100010          110         sub
 *  100          100100          000         and
 *  100          100101          001         or
 *  100          101010          111         slt
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

module M__ALUControl (
    input   wire    [5:0]   ALUFunction__i,
    input   wire    [2:0]   ALUOp__i,
    output  logic   [2:0]   ALUCtrl__o
    );

    always @ (ALUOp__i or ALUFunction__i)
        case (ALUOp__i)
            3'b000:     ALUCtrl__o = 3'b000; // ANDI
            3'b001:     ALUCtrl__o = 3'b001; // ORI
            3'b010:     ALUCtrl__o = 3'b010; // LW/SW/ADDI
            3'b011:     ALUCtrl__o = 3'b110; // BEQ
            3'b100:
                case (ALU_function)
                    6'b100000:  ALUCtrl__o = 3'b010; // ADD
                    6'b100010:  ALUCtrl__o = 3'b110; // SUB
                    6'b100100:  ALUCtrl__o = 3'b000; // AND
                    6'b100101:  ALUCtrl__o = 3'b001; // OR
                    6'b101010:  ALUCtrl__o = 3'b111; // SLT
                    default:    ALUCtrl__o = 3'b110; // Invalid function
                endcase
            default:    ALUCtrl__o = 3'b110; // Invalid operation
        endcase

endmodule : M__ALUControl
