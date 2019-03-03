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

         output wire                     oFB_START,
         output [30:0]                   oFB_DATA,
         output                          oFB_DATAVALID,
         input                           iFB_READY,

         output wire [pADDRESS_BITS-1:0] oSDRAM_ADDRESS,         // SDRAM.address
         output wire                     oSDRAM_READ,            //      .read
         input  wire                     iSDRAM_WAIT_REQUEST,    //      .waitrequest
         input  wire [15:0]              iSDRAM_READ_DATA,       //      .readdata
         output wire                     oSDRAM_WRITE,           //      .write
         output wire [15:0]              oSDRAM_WRITE_DATA,      //      .writedata
         input  wire                     iSDRAM_READ_DATA_VALID  //      .readdatavalid
       );

localparam cBG_SCREEN_W = 256;
localparam cBG_SCREEN_H = 256;
localparam cBG_CHR_W = 16;
localparam cBG_CHR_H = 16;
localparam cSCREEN_SIZE = cSCREEN_ W * cSCREEN_H;
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

wire signed [31:0] wX,wY;
wire signed [31:0] wHX1,wHY1,wUX1,wUY1,wVX1,wVY1;
wire [pADDRESS_BITS-1:0] wADDR1;
wire wREAD1,wVALID1;

// TODO: Auto-generated HDL template
assign oAVL_READ_DATA = 0;
assign oAVL_WAIT_REQUEST = iRESET || wBUSY;
assign oSDRAM_ADDRESS = wADDR_POINT;
assign oSDRAM_READ = 1'b0;
assign oSDRAM_WRITE = rSDRAM_WRITE;
assign oSDRAM_WRITE_DATA = wCOL;

// input
wire [cCMD_BITS-1:0] wE_CMD = iAVL_WRITE_DATA[cCMD_BITS-1:0]; // effective CMD
wire [cADDR_BITS-1:0] wE_ADDR = iAVL_ADDRESS[cADDR_BITS-1:0]; // effective ADDR



endmodule
