// AHB Mux
// Routes HRDATA, HREADYOUT, HRESP from the active slave back to the master
// Selection driven by HSEL0/1/2 from the decoder
// Default (no slave selected): HREADYOUT=1, HRESP=0, HRDATA=0

module AHB_MUX (input wire HSEL0,
                input wire HSEL1,
                input wire HSEL2,
                input wire [31:0] HRDATA0,
                input wire [31:0] HRDATA1,
                input wire [31:0] HRDATA2,
                input wire HREADYOUT0,
                input wire HREADYOUT1,
                input wire HREADYOUT2,
                input wire HRESP0,
                input wire HRESP1,
                input wire HRESP2,
                output reg [31:0] HRDATA,
                output reg HREADY,
                output reg HRESP);

    always @(*) begin
        if (HSEL0) begin
            HRDATA = HRDATA0;
            HREADY = HREADYOUT0;
            HRESP  = HRESP0;
        end 
        else if (HSEL1) begin
            HRDATA = HRDATA1;
            HREADY = HREADYOUT1;
            HRESP  = HRESP1;
        end 
        else if (HSEL2) begin
            HRDATA = HRDATA2;
            HREADY = HREADYOUT2;
            HRESP  = HRESP2;
        end 
        else begin
            HRDATA = 32'h0000_0000;
            HREADY = 1'b1;
            HRESP  = 1'b0;
        end
    end
endmodule