/*
 * ============================================================================
 *
 *  Name        :   M__HazardDetect
 *  Author      :   Aditya Shevade
 *
 *  Description :   Hazard Detection unit. Stalls instructions in the ID stage
 *                  if there are ay conflicts.
 *
 * ============================================================================
 */

module M__HazardDetect (
    input   wire            clock__i,
    input   wire            reset_n__i,
    input   wire            IDEX_MemRead__i,
    input   wire            IDEX_RegWrite__i,
    input   wire            Branch__i,
    input   wire    [4:0]   IFID_RegRs__i,
    input   wire    [4:0]   IFID_RegRt__i,
    input   wire    [4:0]   IDEX_RegRd__i,
    output  logic           Stall__o
);

    logic   Stall__reg;     // Stall continues for one cycle after the condition was satiesfied.
                            // Using this registered value to keep Stall__o active for one
                            // additional cycle.

    always @(negedge clock__i or negedge reset_n__i) begin
        if (~reset_n__i) begin
            Stall__o    <=  1'b0;
            Stall__reg  <=  1'b0;
        end else begin
            Stall__o    <= 1'b0;

            if (Branch__i)
                if (IDEX_MemRead__i && ((IFID_RegRs__i == IDEX_RegRd__i) || (IFID_RegRt__i == IDEX_RegRd__i)))
                begin
                    Stall__o   <=  1'b1;
                    Stall__reg <=  1'b1;
                end
                else if (IDEX_RegWrite__i && ((IFID_RegRs__i == IDEX_RegRd__i) || (IFID_RegRt__i == IDEX_RegRd__i)))
                begin
                    Stall__o   <=  1'b1;
                    Stall__reg <=  1'b0;
                end
                else if (Stall__reg)
                begin
                    Stall__o   <=  1'b1;
                    Stall__reg <=  1'b0;
                end
            else if (IDEX_MemRead__i && ((IFID_RegRs__i == IDEX_RegRd__i) || (IFID_RegRt__i == IDEX_RegRd__i)))
            begin
                Stall__o   <=  1'b1;
                Stall__reg <=  1'b0;
            end
            else
                Stall__o   <= 1'b0;
        end
    end

endmodule : M__HazardDetect
