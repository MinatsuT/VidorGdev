
`timescale 1ps / 1ps
module VID_MIXER_tb ();
    logic clk = 1'b1;
    always begin
        #50 clk <= ~clk;
    end
    
    VID_MIXER VID_MIXER (
    .iCLOCK(clk),
    .iRESET(),
    .iAVL_ADDRESS(),
    .iAVL_READ(),
    .oAVL_READ_DATA(),
    .iAVL_WRITE(),
    .iAVL_WRITE_DATA(),
    .oAVL_WAIT_REQUEST(),
    .oSDRAM_ADDRESS(),
    .oSDRAM_READ(),
    .iSDRAM_WAIT_REQUEST(),
    .iSDRAM_READ_DATA(),
    .oSDRAM_WRITE(),
    .oSDRAM_WRITE_DATA(),
    .iSDRAM_READ_DATA_VALID(),
    .oPIX_START(),
    .oPIX_RGB(),
    .oPIX_WRITE(),
    .iPIX_FULL()
    );
    
endmodule
