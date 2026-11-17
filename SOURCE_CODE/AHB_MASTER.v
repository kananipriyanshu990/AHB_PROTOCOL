// AHB Master
// FSM-based master that issues single and 4-beat incrementing burst transfers
// Waits for HREADY before advancing each beat
// BURST_EN=0 : single transfer (HTRANS=NONSEQ, HBURST=SINGLE)
// BURST_EN=1 : 4-beat burst    (HTRANS=NONSEQ then SEQ x3, HBURST=INCR4)
//
// Usage:
//   1. Set ADDR, WDATA, WRITE, BURST_EN
//   2. Pulse START high for one cycle
//   3. Wait for DONE to go high

module AHB_MASTER (input wire HCLK,
                   input wire HRESETn,
                   // Control inputs
                   input wire START,
                   input wire [31:0] ADDR,
                   input wire [31:0] WDATA,
                   input wire WRITE,
                   input wire BURST_EN,   // 0=single, 1=4-beat INCR4
                   // AHB master outputs
                   output reg [31:0] HADDR,
                   output reg [1:0] HTRANS,
                   output reg HWRITE,
                   output reg [2:0] HBURST,
                   output reg [31:0] HWDATA,
                   output reg [31:0] RDATA_CAP,   // last captured read data
                   output reg HRESP_CAP,    // latched error response
                   // AHB slave response inputs
                   input wire [31:0] HRDATA,
                   input wire HREADY,
                   input wire HRESP,
                   // Status
                   output reg DONE);

    // HTRANS encoding
    localparam IDLE = 2'b00;
    localparam NONSEQ = 2'b10;
    localparam SEQ = 2'b11;

    // HBURST encoding
    localparam SINGLE = 3'b000;
    localparam INCR4 = 3'b011;

    // FSM states
    localparam S_IDLE = 3'd0;
    localparam S_ADDR = 3'd1;
    localparam S_DATA = 3'd2;
    localparam S_BURST_ADDR = 3'd3;
    localparam S_BURST_DATA = 3'd4;
    localparam S_DONE = 3'd5;

    reg [2:0] STATE;
    reg [1:0] BEAT_CNT;    // counts remaining burst beats (3 downto 0)
    reg [31:0] ADDR_REG;
    reg [31:0] WDATA_REG;
    reg WRITE_REG;
    reg BURST_REG;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            STATE <= S_IDLE;
            HADDR <= 32'b0;
            HTRANS <= IDLE;
            HWRITE <= 1'b0;
            HBURST <= SINGLE;
            HWDATA <= 32'b0;
            DONE <= 1'b0;
            BEAT_CNT <= 2'b0;
            ADDR_REG <= 32'b0;
            WDATA_REG <= 32'b0;
            WRITE_REG <= 1'b0;
            BURST_REG <= 1'b0;
            RDATA_CAP <= 32'b0;
        end else begin
            case (STATE)

                // ── Wait for START pulse ──────────────────────────
                S_IDLE : begin
                    DONE <= 1'b0;
                    HTRANS <= IDLE;
                    HBURST <= SINGLE;
                    RDATA_CAP <= 32'b0;
                    HRESP_CAP <= 1'b0;
                    if (START) begin
                        ADDR_REG <= ADDR;
                        WDATA_REG <= WDATA;
                        WRITE_REG <= WRITE;
                        BURST_REG <= BURST_EN;
                        STATE <= S_ADDR;
                    end
                end

                // ── Drive address phase ───────────────────────────
                S_ADDR : begin
                    HADDR <= ADDR_REG;
                    HWRITE <= WRITE_REG;
                    HTRANS <= NONSEQ;
                    if (BURST_REG) begin
                        HBURST <= INCR4;
                        BEAT_CNT <= 2'd3;   // 3 more beats after first
                        STATE <= S_BURST_DATA;
                    end else begin
                        HBURST <= SINGLE;
                        STATE <= S_DATA;
                    end
                end

                // ── Single transfer data phase ────────────────────
                S_DATA : begin
                    if (HREADY) begin
                        HWDATA <= WDATA_REG;
                        if (!WRITE_REG) begin
                            RDATA_CAP <= HRDATA;
                        end
                        HRESP_CAP <= HRESP;
                        HTRANS <= IDLE;
                        STATE <= S_DONE;
                    end
                end

                // ── Burst: pipelined address + data phase ─────────
                // Address of next beat is driven while current data phase runs
                S_BURST_DATA : begin
                    if (HREADY) begin
                        // Complete data phase of current beat
                        HWDATA <= WDATA_REG;
                        if (!WRITE_REG) begin
                            RDATA_CAP <= HRDATA;
                        end
                        HRESP_CAP <= HRESP;

                        if (BEAT_CNT == 2'd0) begin
                            // Last beat done
                            HTRANS <= IDLE;
                            STATE  <= S_DONE;
                        end else begin
                            // Pipeline: drive next address now
                            ADDR_REG <= ADDR_REG  + 4;
                            WDATA_REG <= WDATA_REG + 1;
                            HADDR <= ADDR_REG  + 4;
                            HTRANS <= SEQ;
                            BEAT_CNT <= BEAT_CNT  - 1;
                        end
                    end
                end

                // ── Signal completion for one cycle ───────────────
                S_DONE : begin
                    DONE <= 1'b1;
                    HTRANS <= IDLE;
                    STATE <= S_IDLE;
                end

            endcase
        end
    end

endmodule