// AHB Decoder
// Generates HSEL for each slave based on HADDR
// Address Map:
//   Slave 0 : 0x0000_0000 - 0x0000_00FF
//   Slave 1 : 0x0000_0100 - 0x0000_01FF
//   Slave 2 : 0x0000_0200 - 0x0000_02FF
//   Unmapped: all other addresses - no HSEL asserted

module AHB_DECODER (input wire [31:0] HADDR,
                    output reg HSEL0,
                    output reg HSEL1,
                    output reg HSEL2);

    always @(*) begin
        HSEL0 = 1'b0;
        HSEL1 = 1'b0;
        HSEL2 = 1'b0;

        if (HADDR <= 32'h0000_00FF) begin 
            HSEL0 = 1'b1;
        end
        else if (HADDR >= 32'h0000_0100 && HADDR <= 32'h0000_01FF) begin
            HSEL1 = 1'b1;
        end
        else if (HADDR >= 32'h0000_0200 && HADDR <= 32'h0000_02FF) begin        
            HSEL2 = 1'b1;
        end
    end

endmodule