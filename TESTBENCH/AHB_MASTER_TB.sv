// Testbench: AHB_MASTER
// Uses a simple slave stub to respond with HREADY and HRDATA
// Tests:
//   1. Single write to each slave region
//   2. Single read from each slave region
//   3. 4-beat burst write
//   4. 4-beat burst read
//   5. Back-to-back transfers with random data
// Observe HADDR, HTRANS, HWRITE, HWDATA, HRDATA, HREADY, DONE on waveform

`timescale 1ns/1ps

module AHB_MASTER_TB;

    // ─── Clock & Reset ────────────────────────────────────────────
    reg HCLK;
    reg HRESETn;

    initial HCLK = 0;
    always #5 HCLK = ~HCLK;    // 100 MHz

    // ─── Master control inputs ────────────────────────────────────
    reg         START;
    reg  [31:0] ADDR;
    reg  [31:0] WDATA;
    reg         WRITE;
    reg         BURST_EN;

    // ─── Master AHB outputs ───────────────────────────────────────
    wire [31:0] HADDR;
    wire [1:0]  HTRANS;
    wire        HWRITE;
    wire [2:0]  HBURST;
    wire [31:0] HWDATA;
    wire        DONE;
    wire [31:0] RDATA_CAP;
    wire        HRESP_CAP;

    // ─── Slave stub signals ───────────────────────────────────────
    reg  [31:0] HRDATA;
    reg         HREADY;
    reg         HRESP;

    // ─── DUT ──────────────────────────────────────────────────────
    AHB_MASTER DUT (
        .HCLK     (HCLK),
        .HRESETn  (HRESETn),
        .START    (START),
        .ADDR     (ADDR),
        .WDATA    (WDATA),
        .WRITE    (WRITE),
        .BURST_EN (BURST_EN),
        .HADDR    (HADDR),
        .HTRANS   (HTRANS),
        .HWRITE   (HWRITE),
        .HBURST   (HBURST),
        .HWDATA   (HWDATA),
        .HRDATA   (HRDATA),
        .HREADY   (HREADY),
        .HRESP    (HRESP),
        .RDATA_CAP(RDATA_CAP),
        .HRESP_CAP(HRESP_CAP),
        .DONE     (DONE)
    );

    // ─── Slave stub: responds with random HRDATA ──────────────────
    // Mimics wait states: 0 wait for S0, 1 for S1, 2 for S2
    reg [1:0] WAIT_CNT;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HREADY   <= 1'b1;
            HRDATA   <= 32'b0;
            HRESP    <= 1'b0;
            WAIT_CNT <= 2'b0;
        end else begin
            if (HREADY) begin
                // Determine wait states from address region
                if (HADDR >= 32'h0000_0100 && HADDR <= 32'h0000_01FF) begin
                    // Slave 1 - 1 wait state
                    HREADY   <= 1'b0;
                    WAIT_CNT <= 2'd0;
                end else if (HADDR >= 32'h0000_0200 && HADDR <= 32'h0000_02FF) begin
                    // Slave 2 - 2 wait states
                    HREADY   <= 1'b0;
                    WAIT_CNT <= 2'd1;
                end else begin
                    // Slave 0 - 0 wait states
                    HREADY <= 1'b1;
                end
                HRDATA <= $random;
                HRESP  <= 1'b0;
            end else begin
                if (WAIT_CNT == 2'd0) begin
                    HREADY <= 1'b1;
                    HRDATA <= $random;
                end else begin
                    WAIT_CNT <= WAIT_CNT - 1;
                end
            end
        end
    end

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
        START = 1'b0;
        // Wait for DONE
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
        HRESETn = 1;
        repeat (2) @(posedge HCLK);

        // ── Single writes to all 3 slave regions ──────────────────
        repeat (4) begin
            SEND(32'h0000_0000 + ($random & 32'h000000FC), $random, 1, 0);
        end
        repeat (4) begin
            SEND(32'h0000_0100 + ($random & 32'h000000FC), $random, 1, 0);
        end
        repeat (4) begin
            SEND(32'h0000_0200 + ($random & 32'h000000FC), $random, 1, 0);
        end

        repeat (2) @(posedge HCLK);

        // ── Single reads from all 3 slave regions ─────────────────
        repeat (4) begin
            SEND(32'h0000_0000 + ($random & 32'h000000FC), $random, 0, 0);
        end
        repeat (4) begin
            SEND(32'h0000_0100 + ($random & 32'h000000FC), $random, 0, 0);
        end
        repeat (4) begin
            SEND(32'h0000_0200 + ($random & 32'h000000FC), $random, 0, 0);
        end

        repeat (2) @(posedge HCLK);

        // ── 4-beat burst writes ───────────────────────────────────
        repeat (4) begin
            SEND(32'h0000_0000, $random, 1, 1);
        end

        repeat (2) @(posedge HCLK);

        // ── 4-beat burst reads ────────────────────────────────────
        repeat (4) begin
            SEND(32'h0000_0000, $random, 0, 1);
        end

        repeat (2) @(posedge HCLK);

        // ── Back-to-back random transfers ─────────────────────────
        repeat (12) begin
            SEND($random & 32'h000002FC, $random, $random, $random & 1);
        end

        repeat (5) @(posedge HCLK);
        $finish;
    end

    // ─── Timeout ─────────────────────────────────────────────────
    initial begin
        #200000;
        $finish;
    end

endmodule