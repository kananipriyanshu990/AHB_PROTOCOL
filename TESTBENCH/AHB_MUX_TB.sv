// Testbench: AHB_MUX
// Drives random HRDATA/HREADYOUT/HRESP per slave
// Toggles HSEL to verify correct routing to master
// Observe HRDATA, HREADY, HRESP on waveform

`timescale 1ns/1ps

module AHB_MUX_TB;

    reg HSEL0,      HSEL1,      HSEL2;
    reg [31:0] HRDATA0,    HRDATA1,    HRDATA2;
    reg HREADYOUT0, HREADYOUT1, HREADYOUT2;
    reg HRESP0,     HRESP1,     HRESP2;

    wire [31:0] HRDATA;
    wire HREADY;
    wire HRESP;

    AHB_MUX DUT (
        .HSEL0      (HSEL0),
        .HSEL1      (HSEL1),
        .HSEL2      (HSEL2),
        .HRDATA0    (HRDATA0),
        .HRDATA1    (HRDATA1),
        .HRDATA2    (HRDATA2),
        .HREADYOUT0 (HREADYOUT0),
        .HREADYOUT1 (HREADYOUT1),
        .HREADYOUT2 (HREADYOUT2),
        .HRESP0     (HRESP0),
        .HRESP1     (HRESP1),
        .HRESP2     (HRESP2),
        .HRDATA     (HRDATA),
        .HREADY     (HREADY),
        .HRESP      (HRESP)
    );

    initial begin
        // Initial state - no slave selected
        HSEL0 = 0; HSEL1 = 0; HSEL2 = 0;
        HRDATA0    = 0; HRDATA1    = 0; HRDATA2    = 0;
        HREADYOUT0 = 1; HREADYOUT1 = 1; HREADYOUT2 = 1;
        HRESP0     = 0; HRESP1     = 0; HRESP2     = 0;
        #20;

        // ── No slave selected - default output ────────────────────
        HSEL0 = 0; HSEL1 = 0; HSEL2 = 0;
        #20;

        // ── Slave 0 selected - random data each cycle ─────────────
        HSEL0 = 1; HSEL1 = 0; HSEL2 = 0;
        repeat (8) begin
            HRDATA0    = $random;
            HREADYOUT0 = $random;
            HRESP0     = $random;
            #20;
        end
        HSEL0 = 0; #20;

        // ── Slave 1 selected - random data each cycle ─────────────
        HSEL0 = 0; HSEL1 = 1; HSEL2 = 0;
        repeat (8) begin
            HRDATA1    = $random;
            HREADYOUT1 = $random;
            HRESP1     = $random;
            #20;
        end
        HSEL1 = 0; #20;

        // ── Slave 2 selected - random data each cycle ─────────────
        HSEL0 = 0; HSEL1 = 0; HSEL2 = 1;
        repeat (8) begin
            HRDATA2    = $random;
            HREADYOUT2 = $random;
            HRESP2     = $random;
            #20;
        end
        HSEL2 = 0; #20;

        // ── Back to back slave switching ──────────────────────────
        repeat (12) begin
            // Randomise all slave outputs each step
            HRDATA0    = $random; HREADYOUT0 = $random; HRESP0 = $random;
            HRDATA1    = $random; HREADYOUT1 = $random; HRESP1 = $random;
            HRDATA2    = $random; HREADYOUT2 = $random; HRESP2 = $random;
            // Pick one slave at a time
            case ($random % 4)
                0 : begin HSEL0 = 1; HSEL1 = 0; HSEL2 = 0; end
                1 : begin HSEL0 = 0; HSEL1 = 1; HSEL2 = 0; end
                2 : begin HSEL0 = 0; HSEL1 = 0; HSEL2 = 1; end
                3 : begin HSEL0 = 0; HSEL1 = 0; HSEL2 = 0; end // unmapped
            endcase
            #20;
        end

        // ── Back to no slave ──────────────────────────────────────
        HSEL0 = 0; HSEL1 = 0; HSEL2 = 0;
        #20;

        $finish;
    end

endmodule