/*
 * Copyright 2019 Minatsu Tukisima
 *
 * GFX Hardware Accelerator for MKR VIDOR 4000
 *
 */

`timescale 1 ps / 1 ps
module GFX #(
         parameter pFB_OFFSET = 2*640*480,
         parameter pFB_SIZE = 640*480,
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
         input  wire                     iSDRAM_READ_DATA_VALID  //      .readdatavalid
       );

// TODO: Auto-generated HDL template
assign oAVL_READ_DATA = 0;
assign oAVL_WAIT_REQUEST = iRESET || wBUSY;
assign oSDRAM_ADDRESS = wADDR_POINT;
assign oSDRAM_READ = 1'b0;
assign oSDRAM_WRITE = rSDRAM_WRITE;
assign oSDRAM_WRITE_DATA = wCOL;

// parameters
localparam cMAX_PARAM = 5;
localparam cADDR_CMD = 0;
localparam cW = 640;
localparam cH = 480;

// command definition
localparam cCMD_NOP = 4'd0;
localparam cCMD_GPSET = 4'd1;
localparam cCMD_GLINE = 4'd2;

// control registers: cmd, param1, param2, ...
reg [31:0] rPARAM [0:cMAX_PARAM]; // cMAX_PARAM+1
wire [3:0] wCMD = rPARAM[0][3:0];
wire signed [31:0] wX0  = rPARAM[1][31:0];
wire signed [31:0] wY0  = rPARAM[2][31:0];
wire signed [31:0] wX1  = rPARAM[3][31:0];
wire signed [31:0] wY1  = rPARAM[4][31:0];
wire [31:0] wCOL = rPARAM[5][31:0];

wire wBUSY = (rSTATE!=cSTATE_IDLE); // BUSY flag
reg rSDRAM_WRITE; // write trigger

// writing address
reg [31:0] rX;
reg [31:0] rY;
reg signed [31:0] rADDR_STEP;
wire [31:0] wADDR_POINT = pFB_OFFSET + (cW*rY) + rX + rADDR_STEP; // SDRAM address unit is WORD


wire signed [31:0] wDX = (wX1-wX0);
wire signed [31:0] wDY = (wY1-wY0);
wire signed [31:0] wADDR_STEP_X = (wDX==0) ? 0 : (wDX<0) ? -1 : 1;
wire signed [31:0] wADDR_STEP_Y = (wDY==0) ? 0 : (wDY<0) ? -cW : cW;
wire signed [31:0] wDX_ABS = (wDX<0) ? -wDX : wDX;
wire signed [31:0] wDY_ABS = (wDY<0) ? -wDY : wDY;
wire wSTEEP = (wDY_ABS>wDX_ABS);
// step fraction: A/B
wire signed [31:0] wFRAC_A = (wSTEEP) ? wDX_ABS : wDY_ABS;
wire signed [31:0] wFRAC_B = (wSTEEP) ? wDY_ABS : wDX_ABS;
reg signed [31:0] rCOUNT_TOTAL;
reg signed [31:0] rCOUNT_TRIG;
wire signed [31:0] wADDR_STEP_EVERY = (wSTEEP) ? wADDR_STEP_Y : wADDR_STEP_X;
wire signed [31:0] wADDR_STEP_TRIG  = (wSTEEP) ? wADDR_STEP_X : wADDR_STEP_Y;

reg [3:0] rSTATE;
localparam cSTATE_IDLE = 4'd0;
localparam cSTATE_GPSET_RUN = 4'd1;
localparam cSTATE_GLINE_RUN = 4'd2;

always @(posedge iCLOCK) begin
  if (iRESET)  begin
    rSTATE <= cSTATE_IDLE;
  end
  else begin
    case (rSTATE)
      cSTATE_IDLE: begin
        if (iAVL_WRITE) begin
          rPARAM[iAVL_ADDRESS] = iAVL_WRITE_DATA;
          if (iAVL_ADDRESS==cADDR_CMD) begin
            if (iAVL_WRITE_DATA==cCMD_GPSET) begin
              rADDR_STEP <= 0;
              rX <= wX0;
              rY <= wY0;
              rSDRAM_WRITE <= 1'b1;
              rSTATE <= cSTATE_GPSET_RUN;
            end
            else if (iAVL_WRITE_DATA==cCMD_GLINE) begin
              rADDR_STEP <= 0;
              rX <= wX0;
              rY <= wY0;
              rSDRAM_WRITE <= 1'b1;
              rCOUNT_TOTAL <= wFRAC_B;
              rCOUNT_TRIG <= wFRAC_B>>1;
              rSTATE <= cSTATE_GLINE_RUN;
            end
          end
        end
      end
      cSTATE_GPSET_RUN: begin
        if(!iSDRAM_WAIT_REQUEST) begin
          rSDRAM_WRITE <= 1'b0;
          rSTATE <= cSTATE_IDLE;
        end
      end
      cSTATE_GLINE_RUN: begin
        if(!iSDRAM_WAIT_REQUEST) begin
          if (rCOUNT_TRIG - wFRAC_A <= 0) begin
            rCOUNT_TRIG <= rCOUNT_TRIG - wFRAC_A + wFRAC_B;
            rADDR_STEP <= rADDR_STEP + wADDR_STEP_EVERY + wADDR_STEP_TRIG;
          end else begin
            rCOUNT_TRIG <= rCOUNT_TRIG - wFRAC_A;
            rADDR_STEP <= rADDR_STEP + wADDR_STEP_EVERY;
          end

          rCOUNT_TOTAL <= rCOUNT_TOTAL - 1;
          if (rCOUNT_TOTAL - 1 <= 0) begin
            rSTATE <= cSTATE_IDLE;
            rSDRAM_WRITE <= 1'b0;
          end
        end
      end
      default: begin
        rSTATE <= cSTATE_IDLE;
      end
    endcase
  end
end

endmodule
