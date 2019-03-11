/*
 * Copyright 2019 Minatsu Tukisima
 *
 * Video Mixer for MKR VIDOR 4000
 *
 */
 
 `timescale 1 ps / 1 ps
 module VID_MIXER #(
  parameter pPCG_OFFSET = 0,
  parameter pPCG_SIZE = 512*512,
  parameter pADDRESS_BITS = 22
  )(
  input  wire                     iCLOCK,                 // clock.clk
  input  wire                     iRESET,                 // reset.reset
  
  input  wire [7:0]               iAVL_ADDRESS,           //   AVL.address
  input  wire                     iAVL_READ,              //      .read
  output wire [31:0]              oAVL_READ_DATA,         //      .readdata
  input  wire                     iAVL_WRITE,             //      .write
  input  wire [31:0]              iAVL_WRITE_DATA,        //      .writedata
  output wire                     oAVL_WAIT_REQUEST,      //      .waitrequest
  
  output wire [pADDRESS_BITS-1:0] oSDRAM_ADDRESS,         // SDRAM.address
  output wire                     oSDRAM_READ,            //      .read
  input  wire                     iSDRAM_WAIT_REQUEST,    //      .waitrequest
  input  wire [15:0]              iSDRAM_READ_DATA,       //      .readdata
  output wire                     oSDRAM_WRITE,           //      .write
  output wire [15:0]              oSDRAM_WRITE_DATA,      //      .writedata
  input  wire                     iSDRAM_READ_DATA_VALID, //      .readdatavalid
  
  output wire                     oPIX_START,
  output wire [14:0]              oPIX_RGB,
  output wire                     oPIX_WRITE,
  input  wire                     iPIX_FULL
  );
  
  localparam cBG_SCREEN_W = 256;
  localparam cBG_SCREEN_H = 256;
  localparam cBG_CHR_W = 16;
  localparam cBG_CHR_H = 16;
  localparam cSCREEN_SIZE = 65536;
  
  wire signed [31:0] wX,wY;
  wire signed [31:0] wHX1,wHY1,wUX1,wUY1,wVX1,wVY1;
  wire [pADDRESS_BITS-1:0] wADDR1;
  wire wREAD1,wVALID1,wBUSY;
  
  // TODO: Auto-generated HDL template
  assign oAVL_READ_DATA = 0;
  assign oAVL_WAIT_REQUEST = iRESET || wBUSY;
  assign oSDRAM_ADDRESS = 0;
  assign oSDRAM_READ = 1'b0;
  assign oSDRAM_WRITE = 0;
  assign oSDRAM_WRITE_DATA = 0;
  
  // input
  //wire [cCMD_BITS-1:0] wE_CMD = iAVL_WRITE_DATA[cCMD_BITS-1:0]; // effective CMD
  //wire [cADDR_BITS-1:0] wE_ADDR = iAVL_ADDRESS[cADDR_BITS-1:0]; // effective ADDR
  
  logic [31:0] rCOUNT = (320*240-10);
  assign wX = rCOUNT % 320;
  assign wY = rCOUNT / 320;
  wire [4:0] wB = 32 * (wX + wY) / (320+240);
  wire [4:0] wG = 32 * ((320-1-wX) + wY) / (320+240);
  wire [4:0] wR = 0;
  wire [14:0] wRGB = ((wX + wY) & 1'b1) ? {wR, wG, wB} : 0;
  assign oPIX_RGB = ((wX + wY)==0) ? {5'd31, 5'd0, 5'd0} : wRGB;
  //assign oPIX_RGB = ((wX + wY)==0) ? 15'b11111_00000_00000 : (wX==0) ? 15'b00000_00000_11111 : (wY==0) ? 15'b00000_11111_00000 : 0;
  logic rPIX_START = 0;
  assign oPIX_START = rPIX_START;
  assign oPIX_WRITE = !iPIX_FULL;
  
  logic [31:0] rBEGIN_CNT=100000001;
  always @(posedge iCLOCK) begin
    if (oPIX_WRITE) begin
      rPIX_START <= 1'b0;
      rCOUNT <= rCOUNT + 1;
      if (rCOUNT==(320*240-1)) begin
        rPIX_START <= 1'b1;
      end
      if (rCOUNT==320*240) begin
        rCOUNT <= 0;
      end
    end
    
    rBEGIN_CNT <= rBEGIN_CNT-1;
    if (rBEGIN_CNT==0) begin
      //rBEGIN_CNT <= 100000001;
      //rCOUNT <= (320*240-99);
    end
  end
  
  /*
  BG #(
  .addr     (pPCG_OFFSET+pPCG_SIZE+cSCREEN_SIZE*0),
  .screen_w (cBG_SCREEN_W),
  .screen_h (cBG_SCREEN_H),
  .chr_w    (cBG_CHR_W),
  .chr_h    (cBG_CHR_H)
  ) BG1 (
  .clk   (iCLOCK),
  .x     (wX),
  .y     (wY),
  .hx    (wHX1),
  .hy    (wHY1),
  .ux    (wUX1),
  .uy    (wUY1),
  .vx    (wVX1),
  .vy    (wVY1),
  .addr  (wADDR1),
  .read  (wREAD1),
  .valid (wVALID1)
  );
  */
  
endmodule
