// Testbench: AHB_SLAVE
// Three DUT instances with WAIT_STATES = 0, 1, 2
// Tests: reset, write all 4 regs, read back, back-to-back transfers
// No self-checking - observe waveforms in Vivado

`timescale 1ns/1ps

module AHB_SLAVE_TB;

    // ─── Clock & Reset ────────────────────────────────────────────
    reg HCLK;
    reg HRESETn;

    initial HCLK = 0;
    always #5 HCLK = ~HCLK;    // 100 MHz

    // ─── DUT Signals - Slave 0 (0 wait states) ───────────────────
    reg S0_HSEL;
    reg [31:0] S0_HADDR;
    reg S0_HWRITE;
    reg S0_HREADY;
    reg [1:0] S0_HTRANS;
    reg [31:0]S0_HWDATA;
    wire [31:0] S0_HRDATA;
    wire S0_HREADYOUT;
    wire S0_HRESP;

    // ─── DUT Signals - Slave 1 (1 wait state) ────────────────────
    reg S1_HSEL;
    reg [31:0] S1_HADDR;
    reg S1_HWRITE;
    reg S1_HREADY;
    reg [1:0]  S1_HTRANS;
    reg [31:0] S1_HWDATA;
    wire [31:0] S1_HRDATA;
    wire S1_HREADYOUT;
    wire S1_HRESP;

    // ─── DUT Signals - Slave 2 (2 wait states) ───────────────────
    reg S2_HSEL;
    reg [31:0] S2_HADDR;
    reg S2_HWRITE;
    reg S2_HREADY;
    reg [1:0] S2_HTRANS;
    reg [31:0] S2_HWDATA;
    wire [31:0] S2_HRDATA;
    wire S2_HREADYOUT;
    wire S2_HRESP;

    // ─── DUT Instantiations ───────────────────────────────────────
    AHB_SLAVE #(.WAIT_STATES(0)) 
    DUT_S0 (.HCLK      (HCLK),
            .HRESETn   (HRESETn),
            .HSEL      (S0_HSEL),
            .HADDR     (S0_HADDR),
            .HWRITE    (S0_HWRITE),
            .HREADY    (S0_HREADY),
            .HTRANS    (S0_HTRANS),
            .HWDATA    (S0_HWDATA),
            .HRDATA    (S0_HRDATA),
            .HREADYOUT (S0_HREADYOUT),
            .HRESP     (S0_HRESP));

    AHB_SLAVE #(.WAIT_STATES(1)) 
    DUT_S1 (.HCLK      (HCLK),
            .HRESETn   (HRESETn),
            .HSEL      (S1_HSEL),
            .HADDR     (S1_HADDR),
            .HWRITE    (S1_HWRITE),
            .HREADY    (S1_HREADY),
            .HTRANS    (S1_HTRANS),
            .HWDATA    (S1_HWDATA),
            .HRDATA    (S1_HRDATA),
            .HREADYOUT (S1_HREADYOUT),
            .HRESP     (S1_HRESP));

    AHB_SLAVE #(.WAIT_STATES(2)) 
    DUT_S2 (.HCLK      (HCLK),
            .HRESETn   (HRESETn),
            .HSEL      (S2_HSEL),
            .HADDR     (S2_HADDR),
            .HWRITE    (S2_HWRITE),
            .HREADY    (S2_HREADY),
            .HTRANS    (S2_HTRANS),
            .HWDATA    (S2_HWDATA),
            .HRDATA    (S2_HRDATA),
            .HREADYOUT (S2_HREADYOUT),
            .HRESP     (S2_HRESP));

    // ─── HTRANS encoding ─────────────────────────────────────────
    localparam IDLE   = 2'b00;
    localparam NONSEQ = 2'b10;

    // ─── Task: idle all inputs ────────────────────────────────────
    task IDLE_ALL;
    begin
        S0_HSEL = 0; S0_HADDR = 0; S0_HWRITE = 0;
        S0_HREADY = 1; S0_HTRANS = IDLE; S0_HWDATA = 0;

        S1_HSEL = 0; S1_HADDR = 0; S1_HWRITE = 0;
        S1_HREADY = 1; S1_HTRANS = IDLE; S1_HWDATA = 0;

        S2_HSEL = 0; S2_HADDR = 0; S2_HWRITE = 0;
        S2_HREADY = 1; S2_HTRANS = IDLE; S2_HWDATA = 0;
    end
    endtask

    // ─── Task: single AHB write ───────────────────────────────────
    // Drives address phase, then data phase, waits for HREADYOUT
    task AHB_WRITE;
        input [1:0]  SLV;
        input [31:0] ADDR;
        input [31:0] DATA;
    begin
        @(negedge HCLK);
        case (SLV)
            2'd0 : begin
                S0_HSEL = 1; S0_HADDR = ADDR;
                S0_HWRITE = 1; S0_HTRANS = NONSEQ; S0_HREADY = 1;
            end
            2'd1 : begin
                S1_HSEL = 1; S1_HADDR = ADDR;
                S1_HWRITE = 1; S1_HTRANS = NONSEQ; S1_HREADY = 1;
            end
            2'd2 : begin
                S2_HSEL = 1; S2_HADDR = ADDR;
                S2_HWRITE = 1; S2_HTRANS = NONSEQ; S2_HREADY = 1;
            end
        endcase

        @(posedge HCLK); #1;

        case (SLV)
            2'd0 : begin
                S0_HWDATA = DATA; S0_HTRANS = IDLE;
                @(posedge HCLK);
                while (!S0_HREADYOUT) @(posedge HCLK);
                S0_HSEL = 0;
            end
            2'd1 : begin
                S1_HWDATA = DATA; S1_HTRANS = IDLE;
                @(posedge HCLK);
                while (!S1_HREADYOUT) @(posedge HCLK);
                S1_HSEL = 0;
            end
            2'd2 : begin
                S2_HWDATA = DATA; S2_HTRANS = IDLE;
                @(posedge HCLK);
                while (!S2_HREADYOUT) @(posedge HCLK);
                S2_HSEL = 0;
            end
        endcase
    end
    endtask

    // ─── Task: single AHB read ────────────────────────────────────
    task AHB_READ;
        input [1:0]  SLV;
        input [31:0] ADDR;
    begin
        @(negedge HCLK);
        case (SLV)
            2'd0 : begin
                S0_HSEL = 1; S0_HADDR = ADDR;
                S0_HWRITE = 0; S0_HTRANS = NONSEQ; S0_HREADY = 1;
            end
            2'd1 : begin
                S1_HSEL = 1; S1_HADDR = ADDR;
                S1_HWRITE = 0; S1_HTRANS = NONSEQ; S1_HREADY = 1;
            end
            2'd2 : begin
                S2_HSEL = 1; S2_HADDR = ADDR;
                S2_HWRITE = 0; S2_HTRANS = NONSEQ; S2_HREADY = 1;
            end
        endcase

        @(posedge HCLK); #1;

        case (SLV)
            2'd0 : begin
                S0_HTRANS = IDLE;
                @(posedge HCLK);
                while (!S0_HREADYOUT) @(posedge HCLK);
                S0_HSEL = 0;
            end
            2'd1 : begin
                S1_HTRANS = IDLE;
                @(posedge HCLK);
                while (!S1_HREADYOUT) @(posedge HCLK);
                S1_HSEL = 0;
            end
            2'd2 : begin
                S2_HTRANS = IDLE;
                @(posedge HCLK);
                while (!S2_HREADYOUT) @(posedge HCLK);
                S2_HSEL = 0;
            end
        endcase
    end
    endtask

    // ─── Stimulus variables ───────────────────────────────────────
    reg [31:0] ADDR_VAR;
    reg [31:0] DATA_VAR;

    // ─── Main stimulus ────────────────────────────────────────────
    initial begin
        IDLE_ALL();
        HRESETn = 0;
        repeat (4) @(posedge HCLK);
        HRESETn = 1;
        repeat (2) @(posedge HCLK);

        // ── Slave 0: write 4 regs, read back ─────────────────────
        ADDR_VAR = 32'h0000_0000;
        repeat (4) begin
            AHB_WRITE(0, ADDR_VAR, $random);
            ADDR_VAR = ADDR_VAR + 4;
        end
        repeat (2) @(posedge HCLK);
        ADDR_VAR = 32'h0000_0000;
        repeat (4) begin
            AHB_READ(0, ADDR_VAR);
            ADDR_VAR = ADDR_VAR + 4;
        end
        repeat (2) @(posedge HCLK);

        // ── Slave 1: write 4 regs, read back ─────────────────────
        ADDR_VAR = 32'h0000_0100;
        repeat (4) begin
            AHB_WRITE(1, ADDR_VAR, $random);
            ADDR_VAR = ADDR_VAR + 4;
        end
        repeat (2) @(posedge HCLK);
        ADDR_VAR = 32'h0000_0100;
        repeat (4) begin
            AHB_READ(1, ADDR_VAR);
            ADDR_VAR = ADDR_VAR + 4;
        end
        repeat (2) @(posedge HCLK);

        // ── Slave 2: write 4 regs, read back ─────────────────────
        ADDR_VAR = 32'h0000_0200;
        repeat (4) begin
            AHB_WRITE(2, ADDR_VAR, $random);
            ADDR_VAR = ADDR_VAR + 4;
        end
        repeat (2) @(posedge HCLK);
        ADDR_VAR = 32'h0000_0200;
        repeat (4) begin
            AHB_READ(2, ADDR_VAR);
            ADDR_VAR = ADDR_VAR + 4;
        end
        repeat (2) @(posedge HCLK);

        // ── Slave 0: back-to-back writes ─────────────────────────
        ADDR_VAR = 32'h0000_0000;
        repeat (4) begin
            AHB_WRITE(0, ADDR_VAR, $random);
            ADDR_VAR = ADDR_VAR + 4;
        end

        repeat (5) @(posedge HCLK);
        $finish;
    end

    // ─── Timeout ─────────────────────────────────────────────────
    initial begin
        #100000;
        $finish;
    end
endmodule