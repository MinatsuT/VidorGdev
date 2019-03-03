/*
 * Copyright 2019 Minatsu Tukisima
 *
 * GFX Hardware Accelerator for MKR VIDOR 4000
 *
 */

`timescale 1 ps / 1 ps
module GFX_HW #(
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

// input
wire [cCMD_BITS-1:0] wE_CMD = iAVL_WRITE_DATA[cCMD_BITS-1:0]; // effective CMD
wire [cADDR_BITS-1:0] wE_ADDR = iAVL_ADDRESS[cADDR_BITS-1:0]; // effective ADDR

// parameters
localparam cADDR_BITS = 3;
localparam cMAX_PARAM = 5;
localparam cADDR_CMD = 0;
localparam cW = 640;
localparam cH = 480;
// command definition
localparam cCMD_BITS = 4;
localparam cCMD_NOP = 4'd0;
localparam cCMD_GPSET = 4'd1;
localparam cCMD_GLINE = 4'd2;


// control registers: cmd, param1, param2, ...
reg [31:0] rPARAM [0:cMAX_PARAM]; // cMAX_PARAM+1
wire [3:0] wCMD = rPARAM[3'd0][3:0];
wire signed [31:0] wX0  = rPARAM[3'd1][31:0];
wire signed [31:0] wY0  = rPARAM[3'd2][31:0];
wire signed [31:0] wX1  = rPARAM[3'd3][31:0];
wire signed [31:0] wY1  = rPARAM[3'd4][31:0];
(* ramstyle = "Auto" *) wire [31:0] wCOL = rPARAM[3'd5][31:0];

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

reg [3:0] rSTATE, rNEXT_STATE;
localparam cSTATE_IDLE = 4'd0;
localparam cSTATE_GPSET_RUN = 4'd1;
localparam cSTATE_GLINE_RUN = 4'd2;

always @(posedge iCLOCK) begin
  //always @(posedge iCLOCK) begin
  if (iRESET)  begin
    rSTATE <= cSTATE_IDLE;
  end
  else begin
    case(rSTATE)
      cSTATE_IDLE: begin
        rSTATE<=cSTATE_IDLE;
        if (iAVL_WRITE && wE_ADDR==cADDR_CMD) begin
          case(wE_CMD)
            cCMD_GPSET: begin
              rSTATE<=cSTATE_GPSET_RUN;
            end
            cCMD_GLINE: begin
              rSTATE<=cSTATE_GLINE_RUN;
            end
            default: begin
              rSTATE<=cSTATE_IDLE;
            end
          endcase
        end
      end
      cSTATE_GPSET_RUN: begin
        rSTATE<=(!iSDRAM_WAIT_REQUEST) ? cSTATE_IDLE : cSTATE_GPSET_RUN;
      end
      cSTATE_GLINE_RUN: begin
        rSTATE<=(!iSDRAM_WAIT_REQUEST && rCOUNT_TOTAL == 0) ? cSTATE_IDLE : cSTATE_GLINE_RUN;
      end
      default: begin
        rSTATE<=cSTATE_IDLE;
      end
    endcase
  end
end

reg signed [31:0] rTMP_COUNT_TRIG_no_trig;
reg signed [31:0] rTMP_COUNT_TRIG_trig;
reg signed [31:0] rTMP_ADDR_STEP_no_trig;
reg signed [31:0] rTMP_ADDR_STEP_trig;
reg signed [31:0] rTMP_COUNT_TOTAL;


always @(posedge iCLOCK) begin
  if (rSTATE==cSTATE_IDLE && iAVL_WRITE) begin
    rPARAM[iAVL_ADDRESS[cADDR_BITS-1:0]] <= iAVL_WRITE_DATA;
    rX <= wX0;
    rY <= wY0;
    rADDR_STEP <= 0;
    rSDRAM_WRITE <= 1'b0;
    rCOUNT_TOTAL <= wFRAC_B;
    rCOUNT_TRIG  <= wFRAC_B>>1;
    if (wE_ADDR==cADDR_CMD) begin
      if (wE_CMD==cCMD_GPSET) begin
        rSDRAM_WRITE <= 1'b1;
      end
      if (wE_CMD==cCMD_GLINE) begin
        rSDRAM_WRITE <= 1'b1;
      end
    end
  end

  if (rSTATE==cSTATE_GPSET_RUN && !iSDRAM_WAIT_REQUEST) begin
    rSDRAM_WRITE <= 1'b0;
  end

  if (rSTATE==cSTATE_GLINE_RUN && !iSDRAM_WAIT_REQUEST) begin
    rCOUNT_TRIG <= rCOUNT_TRIG - wFRAC_A + ((rCOUNT_TRIG - wFRAC_A <= 0) ? wFRAC_B : 0);
    rADDR_STEP <= rADDR_STEP + wADDR_STEP_EVERY + ((rCOUNT_TRIG - wFRAC_A <= 0) ? wADDR_STEP_TRIG : 0);

    rCOUNT_TOTAL <= rCOUNT_TOTAL - 1;
    if (rCOUNT_TOTAL == 0) begin
      rSDRAM_WRITE <= 1'b0;
    end
/*
    rTMP_COUNT_TRIG_no_trig = rCOUNT_TRIG - wFRAC_A;
    rTMP_COUNT_TRIG_trig = rTMP_ADDR_STEP_no_trig + wFRAC_B;
    rTMP_ADDR_STEP_no_trig = rADDR_STEP + wADDR_STEP_EVERY;
    rTMP_ADDR_STEP_trig = rTMP_ADDR_STEP_no_trig + wADDR_STEP_TRIG;
    rTMP_COUNT_TOTAL = rCOUNT_TOTAL - 1;

    if (rTMP_COUNT_TRIG_no_trig<=0) begin
      rCOUNT_TRIG <= rTMP_COUNT_TRIG_trig;
      rADDR_STEP <= rTMP_ADDR_STEP_trig;
    end
    else begin
      rCOUNT_TRIG <= rTMP_COUNT_TRIG_no_trig;
      rADDR_STEP <= rTMP_ADDR_STEP_no_trig;
    end

    rCOUNT_TOTAL <= rTMP_COUNT_TOTAL;
    if (rTMP_COUNT_TOTAL < 0) begin
      rSDRAM_WRITE <= 1'b0;
    end
*/
  end
end

endmodule
