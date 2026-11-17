// AHB Slave - 4 x 32-bit register file
// Parameter WAIT_STATES sets the number of wait cycles per transfer
// HSEL is driven by the decoder - this module does not decode HADDR
// Instantiate once per slave in top, override WAIT_STATES per instance

module AHB_SLAVE #(parameter WAIT_STATES = 0)
                  (input wire HCLK,
                   input wire HRESETn,
                   
                   // AHB slave inputs
                   input wire HSEL,
                   input wire [31:0] HADDR,
                   input wire HWRITE,
                   input wire HREADY,          // from mux - previous transfer done
                   input wire [1:0]  HTRANS,
                   input wire [31:0] HWDATA,

                   // AHB slave outputs
                   output reg [31:0] HRDATA,
                   output reg HREADYOUT,
                   output reg HRESP);

    // HTRANS encoding
    localparam IDLE = 2'b00;
    localparam BUSY = 2'b01;
    localparam NONSEQ = 2'b10;
    localparam SEQ = 2'b11;


    // 4 x 32-bit registers
    reg [31:0] REG_FILE [0:3];

    // Address-phase capture registers
    reg HSEL_D;
    reg [31:0] HADDR_D;
    reg HWRITE_D;
    reg HTRANS_VALID_D;

    // Wait state counter
    reg [2:0]  WAIT_CNT;

    // Transfer valid when HSEL active, bus ready, NONSEQ or SEQ
    wire TRANS_VALID;
    assign TRANS_VALID = HSEL && HREADY && ((HTRANS == NONSEQ) || (HTRANS == SEQ));

    // --- Address Phase Capture ---
    // Capture on every cycle where this slave is ready (HREADYOUT high)
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HSEL_D <= 1'b0;
            HADDR_D <= 32'b0;
            HWRITE_D <= 1'b0;
            HTRANS_VALID_D <= 1'b0;
        end else begin
            if (HREADYOUT) begin
                HSEL_D <= HSEL;
                HADDR_D <= HADDR;
                HWRITE_D <= HWRITE;
                HTRANS_VALID_D <= TRANS_VALID;
            end
        end
    end

    // --- Wait State Counter and HREADYOUT ---
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HREADYOUT <= 1'b1;
            WAIT_CNT <= 3'b0;
        end else begin
            if (TRANS_VALID && HREADYOUT) begin
                // New transfer starting - insert wait states if needed
                if (WAIT_STATES == 0) begin
                    HREADYOUT <= 1'b1;
                    WAIT_CNT  <= 3'b0;
                end else begin
                    HREADYOUT <= 1'b0;
                    WAIT_CNT  <= WAIT_STATES - 1;
                end
            end else if (!HREADYOUT) begin
                // Counting down wait states
                if (WAIT_CNT == 3'b0) begin
                    HREADYOUT <= 1'b1;
                end else begin
                    WAIT_CNT <= WAIT_CNT - 1;
                end
            end
        end
    end

    // --- Data Phase: Write ---
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            REG_FILE[0] <= 32'b0;
            REG_FILE[1] <= 32'b0;
            REG_FILE[2] <= 32'b0;
            REG_FILE[3] <= 32'b0;
        end else begin
            if (HREADYOUT && HTRANS_VALID_D && HWRITE_D && HSEL_D) begin
                case (HADDR_D[3:2])
                    2'b00 : REG_FILE[0] <= HWDATA;
                    2'b01 : REG_FILE[1] <= HWDATA;
                    2'b10 : REG_FILE[2] <= HWDATA;
                    2'b11 : REG_FILE[3] <= HWDATA;
                endcase
            end
        end
    end

    // --- Data Phase: Read ---
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HRDATA <= 32'b0;
        end else begin
            if (HREADYOUT && HTRANS_VALID_D && !HWRITE_D && HSEL_D) begin
                case (HADDR_D[3:2])
                    2'b00 : HRDATA <= REG_FILE[0];
                    2'b01 : HRDATA <= REG_FILE[1];
                    2'b10 : HRDATA <= REG_FILE[2];
                    2'b11 : HRDATA <= REG_FILE[3];
                endcase
            end
        end
    end
    
    // --- HRESP: ERROR if address out of register range ---
    // Valid offsets: 0x00, 0x04, 0x08, 0x0C (bits [7:2] must be 0)
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HRESP <= 1'b0;
        end else begin
            if (HREADYOUT && HTRANS_VALID_D && HSEL_D) begin
                if (HADDR_D[7:4] != 4'b0000) begin
                    HRESP <= 1'b1;
                end else begin
                    HRESP <= 1'b0;
                end
            end else begin
                HRESP <= 1'b0;
            end
        end
    end
endmodule