// Testbench: AHB_DECODER
// Drives HADDR across all slave regions and unmapped space
// Uses random offsets within each region
// Observe HSEL0/1/2 on waveform - only one should be high at a time

`timescale 1ns/1ps

module AHB_DECODER_TB;

    reg  [31:0] HADDR;
    wire        HSEL0;
    wire        HSEL1;
    wire        HSEL2;

    AHB_DECODER DUT (
        .HADDR (HADDR),
        .HSEL0 (HSEL0),
        .HSEL1 (HSEL1),
        .HSEL2 (HSEL2)
    );

    reg [7:0] RAND_OFFSET;

    initial begin
        HADDR = 32'h0;
        #10;

        // ── Slave 0 region: random addresses within 0x000-0x0FF ──
        repeat (4) begin
            RAND_OFFSET = $random;
            HADDR = 32'h0000_0000 | RAND_OFFSET;
            #10;
        end

        // ── Slave 1 region: random addresses within 0x100-0x1FF ──
        repeat (4) begin
            RAND_OFFSET = $random;
            HADDR = 32'h0000_0100 | RAND_OFFSET;
            #10;
        end

        // ── Slave 2 region: random addresses within 0x200-0x2FF ──
        repeat (4) begin
            RAND_OFFSET = $random;
            HADDR = 32'h0000_0200 | RAND_OFFSET;
            #10;
        end

        // ── Unmapped region: all HSEL should be 0 ────────────────
        repeat (4) begin
            HADDR = 32'h0000_0300 | ($random & 32'h0000_FFFF);
            #10;
        end

        // ── Boundary addresses ────────────────────────────────────
        HADDR = 32'h0000_0000; #10;   // first of S0
        HADDR = 32'h0000_00FF; #10;   // last  of S0
        HADDR = 32'h0000_0100; #10;   // first of S1
        HADDR = 32'h0000_01FF; #10;   // last  of S1
        HADDR = 32'h0000_0200; #10;   // first of S2
        HADDR = 32'h0000_02FF; #10;   // last  of S2
        HADDR = 32'h0000_0300; #10;   // first unmapped

        #20;
        $finish;
    end

endmodule