// Testbench: AHB_TOP - Full system
// Tests all three slaves with single and burst transfers
// All data inputs randomised
// Observe all bus signals and slave register contents in waveform

`timescale 1ns/1ps

module TB_AHB_TOP;

    // ─── Clock & Reset ────────────────────────────────────────────
    reg HCLK;
    reg HRESETn;

    initial HCLK = 0;
    always #5 HCLK = ~HCLK;    // 100 MHz

    // ─── Control inputs ───────────────────────────────────────────
    reg         START;
    reg  [31:0] ADDR;
    reg  [31:0] WDATA;
    reg         WRITE;
    reg         BURST_EN;

    // ─── Outputs ──────────────────────────────────────────────────
    wire        DONE;
    wire [31:0] RDATA_CAP;
    wire        HRESP_CAP;

    // ─── DUT ──────────────────────────────────────────────────────
    AHB_TOP DUT (
        .HCLK      (HCLK),
        .HRESETn   (HRESETn),
        .START     (START),
        .ADDR      (ADDR),
        .WDATA     (WDATA),
        .WRITE     (WRITE),
        .BURST_EN  (BURST_EN),
        .DONE      (DONE),
        .RDATA_CAP (RDATA_CAP),
        .HRESP_CAP (HRESP_CAP)
    );

    // ─── Task: issue one transfer, wait for DONE ──────────────────
    task SEND;
        input [31:0] T_ADDR;
        input [31:0] T_WDATA;
        input        T_WRITE;
        input        T_BURST;
    begin
        @(negedge HCLK);
        ADDR     = T_ADDR;
        WDATA    = T_WDATA;
        WRITE    = T_WRITE;
        BURST_EN = T_BURST;
        START    = 1'b1;
        @(negedge HCLK);
        START    = 1'b0;
        @(posedge DONE);
        @(posedge HCLK);
    end
    endtask

    // ─── Main stimulus ────────────────────────────────────────────
    initial begin
        START    = 0;
        ADDR     = 0;
        WDATA    = 0;
        WRITE    = 0;
        BURST_EN = 0;
        HRESETn  = 0;
        repeat (4) @(posedge HCLK);
        HRESETn  = 1;
        repeat (2) @(posedge HCLK);

        // ── Single writes to Slave 0 (0 wait states) ─────────────
        repeat (4) begin
            SEND(32'h0000_0000 + ($random & 32'h0000_000C), $random, 1, 0);
        end
        repeat (2) @(posedge HCLK);

        // ── Single reads from Slave 0 ─────────────────────────────
        repeat (4) begin
            SEND(32'h0000_0000 + ($random & 32'h0000_000C), $random, 0, 0);
        end
        repeat (2) @(posedge HCLK);

        // ── Single writes to Slave 1 (1 wait state) ──────────────
        repeat (4) begin
            SEND(32'h0000_0100 + ($random & 32'h0000_000C), $random, 1, 0);
        end
        repeat (2) @(posedge HCLK);

        // ── Single reads from Slave 1 ─────────────────────────────
        repeat (4) begin
            SEND(32'h0000_0100 + ($random & 32'h0000_000C), $random, 0, 0);
        end
        repeat (2) @(posedge HCLK);

        // ── Single writes to Slave 2 (2 wait states) ─────────────
        repeat (4) begin
            SEND(32'h0000_0200 + ($random & 32'h0000_000C), $random, 1, 0);
        end
        repeat (2) @(posedge HCLK);

        // ── Single reads from Slave 2 ─────────────────────────────
        repeat (4) begin
            SEND(32'h0000_0200 + ($random & 32'h0000_000C), $random, 0, 0);
        end
        repeat (2) @(posedge HCLK);

        // ── 4-beat burst writes to Slave 0 ───────────────────────
        repeat (4) begin
            SEND(32'h0000_0000, $random, 1, 1);
        end
        repeat (2) @(posedge HCLK);

        // ── 4-beat burst reads from Slave 0 ──────────────────────
        repeat (4) begin
            SEND(32'h0000_0000, $random, 0, 1);
        end
        repeat (2) @(posedge HCLK);

        // ── 4-beat burst writes to Slave 1 ───────────────────────
        repeat (4) begin
            SEND(32'h0000_0100, $random, 1, 1);
        end
        repeat (2) @(posedge HCLK);

        // ── 4-beat burst writes to Slave 2 ───────────────────────
        repeat (4) begin
            SEND(32'h0000_0200, $random, 1, 1);
        end
        repeat (2) @(posedge HCLK);

        // ── Random transfers across all slaves ────────────────────
        repeat (16) begin
            SEND({22'b0, $random, 2'b00},   // aligned addr in 0x000-0x2FF
                $random,
                $random,
                $random);            
        end

        repeat (5) @(posedge HCLK);
        $finish;
    end

    // ─── Timeout ─────────────────────────────────────────────────
    initial begin
        #500000;
        $finish;
    end

endmodule