/*
 * ============================================================================
 *
 *  Name        :   M__CPUControl
 *  Author      :   Aditya Shevade
 *
 *  Description :   The main processor control signal generator.
 *
 *  TODO:
 *          1. Add support for arithmetic and logical shift right and left
 *          2. Add support for immediate subtraction (subi).
 *          3. Add support for unsigned addition and subtraction.
 *          4. For invalid opcode - branch to predefined address to investiage.
 *
 * ============================================================================
 */

module M__CPUControl (
    input   wire    [5:0]   opcode__i,
    output  wire            RegDst__o,
    output  wire            Branch__o,
    output  wire            MemRead__o,
    output  wire            MemWrite__o,
    output  wire            MemToReg__o,
    output  wire            ALUSrc__o,
    output  wire            RegWrite__o,
    output  wire    [2:0]   ALUOp__o
);

    logic   [9:0]   combined_control;

    always @ (opcode__i)
        case (opcode__i)
            6'b000000:  combined_control = 10'b1_0_0_0_0_0_1_100; // R-Type
            6'b001000:  combined_control = 10'b0_0_0_0_0_1_1_010; // ADDI
            6'b001100:  combined_control = 10'b0_0_0_0_0_1_1_000; // ANDI
            6'b001101:  combined_control = 10'b0_0_0_0_0_1_1_001; // ORI
            6'b001110:  combined_control = 10'b0_0_0_0_0_1_1_101; // XORI
            6'b101011:  combined_control = 10'b0_0_0_0_1_1_0_010; // SW
            6'b100011:  combined_control = 10'b0_0_1_1_0_1_1_010; // LW
            6'b000100:  combined_control = 10'b0_1_0_0_0_0_0_011; // BEQ
            default:    combined_control = 10'b0_0_0_0_0_0_0_111; // Invalid opcode
        endcase

    assign {RegDst__o, Branch__o, MemRead__o, MemToReg__o, MemWrite__o, ALUSrc__o, RegWrite__o, ALUOp__o} = combined_control;

endmodule
