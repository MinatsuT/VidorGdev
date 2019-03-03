
`timescale 1ps / 1ps
module SCANLINE_tb ();
    logic pix_clk = 1'b1;
    always begin
        #50 pix_clk <= ~pix_clk;
    end
    
    logic fb_clk = 1'b0;
    always begin
        #115 fb_clk <= ~fb_clk;
    end
    
    logic [14:0] pix_data=0;
    logic pix_write=0;
    logic pix_start=0;
    logic pix_full=0;
    logic fb_st_ready=0;
    SCANLINE SCANLINE_inst (
    .iPIX_CLK(pix_clk),
    .iPIX_DATA(pix_data),
    .iPIX_WRITE(pix_write),
    .iPIX_START(pix_start),
    .oPIX_FULL(pix_full),
    
    .iFB_CLK(fb_clk),
    .oFB_START(fb_st_start),
    .oFB_DATA(fb_st_data),
    .oFB_DATAVALID(fb_st_dv),
    .iFB_READY(fb_st_ready)
    );
    
    logic [31:0] rCOUNT = 0;
    always @(posedge pix_clk) begin
        pix_write <= 1'b0;
        pix_start <= 1'b0;
        if (!pix_full) begin
            pix_write <= 1'b1;
            pix_data <= pix_data + 1;
            rCOUNT <= rCOUNT + 1;
            if (rCOUNT==320*240) begin
                rCOUNT <= 0;
                pix_start <= 1'b1;
            end
        end
    end

    initial begin
        #200 fb_st_ready <= 1'b1;
    end
endmodule
