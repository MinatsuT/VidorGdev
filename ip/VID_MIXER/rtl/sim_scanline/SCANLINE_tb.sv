
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
    
    logic [31:0] rCOUNT = (320*240-10);

    logic [14:0] pix_rgb=0;
    wire pix_write;
    logic pix_start=0;
    wire pix_full;
    logic fb_st_ready=1;
    logic [14:0] fb_st_rgb;
    SCANLINE SCANLINE_inst (
    .iPIX_CLK(pix_clk),
    //.iPIX_RGB(pix_rgb),
    .iPIX_RGB(rCOUNT),
    .iPIX_WRITE(pix_write),
    .iPIX_START(pix_start),
    .oPIX_FULL(pix_full),
    
    .iFB_CLK(fb_clk),
    .oFB_START(fb_st_start),
    .oFB_RGB(fb_st_rgb),
    .oFB_DATAVALID(fb_st_dv),
    .iFB_READY(fb_st_ready)
    );
    assign pix_write = !pix_full;

    always @(posedge pix_clk) begin
        pix_start <= 1'b0;
        if (pix_write) begin
            //pix_rgb <= pix_rgb + 1;
            rCOUNT <= rCOUNT + 1;
            if (rCOUNT==320*240-1) begin
                rCOUNT <= 0;
                pix_start <= 1'b1;
            end
        end
    end
    
    initial begin
        #200 fb_st_ready <= 1'b1;
    end
endmodule
