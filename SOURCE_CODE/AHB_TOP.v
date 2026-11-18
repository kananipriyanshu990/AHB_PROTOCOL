// AHB Top
// Connects: AHB_MASTER, AHB_DECODER, AHB_SLAVE x3, AHB_MUX
//
// Address Map:
//   Slave 0 : 0x0000_0000 - 0x0000_00FF  (0 wait states)
//   Slave 1 : 0x0000_0100 - 0x0000_01FF  (1 wait state)
//   Slave 2 : 0x0000_0200 - 0x0000_02FF  (2 wait states)

module AHB_TOP (input wire HCLK,
                input wire HRESETn,
                // Master control inputs (exposed for testbench)
                input wire START,
                input wire [31:0] ADDR,
                input wire [31:0] WDATA,
                input wire WRITE,
                input wire BURST_EN,
                // Outputs observable in testbench/waveform
                output wire DONE,
                output wire [31:0] RDATA_CAP,
                output wire HRESP_CAP);

    // ─── Master → Bus ─────────────────────────────────────────────
    wire [31:0] HADDR;
    wire [1:0] HTRANS;
    wire HWRITE;
    wire [2:0] HBURST;
    wire [31:0] HWDATA;

    // ─── Mux → Master ─────────────────────────────────────────────
    wire [31:0] HRDATA;
    wire HREADY;
    wire HRESP;

    // ─── Decoder → Slaves ─────────────────────────────────────────
    wire HSEL0;
    wire HSEL1;
    wire HSEL2;

    // ─── Slaves → Mux ────────────────────────────────────────────
    wire [31:0] HRDATA0,    HRDATA1,    HRDATA2;
    wire HREADYOUT0, HREADYOUT1, HREADYOUT2;
    wire HRESP0,     HRESP1,     HRESP2;

    // ─── Master ───────────────────────────────────────────────────
    AHB_MASTER U_MASTER (.HCLK      (HCLK),
                         .HRESETn   (HRESETn),
                         .START     (START),
                         .ADDR      (ADDR),
                         .WDATA     (WDATA),
                         .WRITE     (WRITE),
                         .BURST_EN  (BURST_EN),
                         .HADDR     (HADDR),
                         .HTRANS    (HTRANS),
                         .HWRITE    (HWRITE),
                         .HBURST    (HBURST),
                         .HWDATA    (HWDATA),
                         .HRDATA    (HRDATA),
                         .HREADY    (HREADY),
                         .HRESP     (HRESP),
                         .DONE      (DONE),
                         .RDATA_CAP (RDATA_CAP),
                         .HRESP_CAP (HRESP_CAP));

    // ─── Decoder ──────────────────────────────────────────────────
    AHB_DECODER U_DECODER (.HADDR (HADDR),
                           .HSEL0 (HSEL0),
                           .HSEL1 (HSEL1),
                           .HSEL2 (HSEL2));

    // ─── Slave 0 - 0 wait states ──────────────────────────────────
    AHB_SLAVE #(.WAIT_STATES(0)) 
    U_SLAVE0 (.HCLK      (HCLK),
              .HRESETn   (HRESETn),
              .HSEL      (HSEL0),
              .HADDR     (HADDR),
              .HWRITE    (HWRITE),
              .HREADY    (HREADY),
              .HTRANS    (HTRANS),
              .HWDATA    (HWDATA),
              .HRDATA    (HRDATA0),
              .HREADYOUT (HREADYOUT0),
              .HRESP     (HRESP0));

    // ─── Slave 1 - 1 wait state ───────────────────────────────────
    AHB_SLAVE #(.WAIT_STATES(1)) 
    U_SLAVE1 (.HCLK      (HCLK),
             .HRESETn   (HRESETn),
             .HSEL      (HSEL1),
             .HADDR     (HADDR),
             .HWRITE    (HWRITE),
             .HREADY    (HREADY),
             .HTRANS    (HTRANS),
             .HWDATA    (HWDATA),
             .HRDATA    (HRDATA1),
             .HREADYOUT (HREADYOUT1),
             .HRESP     (HRESP1));

    // ─── Slave 2 - 2 wait states ──────────────────────────────────
    AHB_SLAVE #(.WAIT_STATES(2)) 
    U_SLAVE2 (.HCLK      (HCLK),
              .HRESETn   (HRESETn),
              .HSEL      (HSEL2),
              .HADDR     (HADDR),
              .HWRITE    (HWRITE),
              .HREADY    (HREADY),
              .HTRANS    (HTRANS),
              .HWDATA    (HWDATA),
              .HRDATA    (HRDATA2),
              .HREADYOUT (HREADYOUT2),
              .HRESP     (HRESP2));

    // ─── Mux ──────────────────────────────────────────────────────
    AHB_MUX U_MUX (.HSEL0      (HSEL0),
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
                   .HRESP      (HRESP));

endmodule