/* ============================================================================
 *
 *  Name        :   TB__ALUMain
 *  Author      :   Aditya Shevade
 *
 *  Description :   Testbench for the ALU of the MIPS processor.
 *
 *  TODO        :   1. Add checks for Zero.
 *                  2. Generate dataA and dataB randomly.
 *                  3. Add assertions.
 *
 * ============================================================================
 */

module TB__ALUMain;

    logic   [31:0]  dataA;
    logic   [31:0]  dataB;
    logic   [ 2:0]  ALUCtrl;
    wire    [31:0]  ALUResult;
    wire            Zero;

    integer         cntr;

    M__ALUMain DUT (
        .dataA__i       (dataA),
        .dataB__i       (dataB),
        .ALUCtrl__i     (ALUCtrl),
        .ALUResult__o   (ALUResult),
        .Zero__o        (Zero)
    );

    initial begin
        for (cntr = 0; cntr < 8; cntr = cntr + 1) begin
            ALUCtrl =   cntr;
            dataA   =   //TODO: Random;
            dataB   =   //TODO: Random;

            case (cntr)
                0: begin
                    if (ALUResult == dataA & dataB) begin
                        $display ("The ALU is working as expected");
                    end else begin
                        $display ("The ALU has erros");
                    end
                end
                1: begin
                    if (ALUResult == dataA | dataB) begin
                        $display ("The ALU is working as expected");
                    end else begin
                        $display ("The ALU has erros");
                    end
                end
                2: begin
                    if (ALUResult == dataA + dataB) begin
                        $display ("The ALU is working as expected");
                    end else begin
                        $display ("The ALU has erros");
                    end
                end
                3: begin
                    if (ALUResult == dataA ^ dataB) begin
                        $display ("The ALU is working as expected");
                    end else begin
                        $display ("The ALU has erros");
                    end
                end
                4: begin
                    if (ALUResult == 32'b1) begin
                        $display ("The ALU is working as expected");
                    end else begin
                        $display ("The ALU has erros");
                    end
                end
                5: begin
                    if (ALUResult == 32'b1) begin
                        $display ("The ALU is working as expected");
                    end else begin
                        $display ("The ALU has erros");
                    end
                end
                6: begin
                    if (ALUResult == dataA - dataB) begin
                        $display ("The ALU is working as expected");
                    end else begin
                        $display ("The ALU has erros");
                    end
                end
                7: begin
                    if (((dataA - dataB) < 0) and (ALUResult == 32'b1)) begin
                        $display ("The ALU is working as expected");
                    if (((dataA - dataB) > 0) and (ALUResult == 32'b0)) begin
                        $display ("The ALU is working as expected");
                    end else begin
                        $display ("The ALU has erros");
                    end
                end
                default: begin
                    if (ALUResult == 32'b1) begin
                        $display ("The ALU is working as expected");
                    end else begin
                        $display ("The ALU has erros");
                    end
                end
            endcase

            #10;

        end // for
    end // initial
endmoule : TB__ALUMain
