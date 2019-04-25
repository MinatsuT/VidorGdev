/*
 * Copyright 2019 Minatsu Tukisima
 *
 * Video Mixer for MKR VIDOR 4000
 *
 */
 `timescale 1 ps / 1 ps
 `include "VID_MIXER.pkg"
 module VID_MIXER
  import VidMixer::*;
  #(
  parameter pADDR_BITS = 22
  )
  (
  input  wire                  iCLOCK,                 // clock.clk
  input  wire                  iRESET,                 // reset.reset
  
  input  wire [7:0]            iAVL_ADDRESS,           //   AVL.address
  input  wire                  iAVL_READ,              //      .read
  output wire [31:0]           oAVL_READ_DATA,         //      .readdata
  input  wire                  iAVL_WRITE,             //      .write
  input  wire [31:0]           iAVL_WRITE_DATA,        //      .writedata
  output wire                  oAVL_WAIT_REQUEST,      //      .waitrequest
  
  output wire [pADDR_BITS-1:0] oSDRAM_ADDRESS,         // SDRAM.address
  output wire                  oSDRAM_READ,            //      .read
  input  wire                  iSDRAM_WAIT_REQUEST,    //      .waitrequest
  input  wire [15:0]           iSDRAM_READ_DATA,       //      .readdata
  output wire                  oSDRAM_WRITE,           //      .write
  output wire [15:0]           oSDRAM_WRITE_DATA,      //      .writedata
  input  wire                  iSDRAM_READ_DATA_VALID, //      .readdatavalid
  
  output wire                  oPIX_START,
  output wire [14:0]           oPIX_RGB,
  output wire                  oPIX_WRITE,
  input  wire                  iPIX_FULL
  );
  
  // TODO: Auto-generated HDL template
  assign oAVL_READ_DATA = 1'b0;
  assign oAVL_WAIT_REQUEST = iRESET | rAVL_ACK_n;
  assign oSDRAM_WRITE = 1'b0;
  assign oSDRAM_WRITE_DATA = 1'b0;
  
  // ================================================================================
  // working variables
  // ================================================================================
  
  // Avalon
  // --------------------------------------------------------------------------------
  logic rAVL_ACK_n;
  always_ff @(posedge iCLOCK) begin
    rAVL_ACK_n <= (iAVL_WRITE) ? 1'b0 : 1'b1;
  end
  
  // BG0
  // --------------------------------------------------------------------------------
  logic wBG0_OFFSCREEN; // from BG module
  logic wBG0_RGB_WRITE; // from BG module
  tRGB wBG0_RGB; // from BG module
  logic wBG0_READY;
  assign wBG0_READY = (wBG0_OFFSCREEN | wBG0_RGB_WRITE);
  
  // RGB out
  // assign oPIX_RGB = (wBG0_OFFSCREEN) ? 1'b0 : wBG0_RGB;
  //assign oPIX_RGB = 15'h00f;
  always_comb begin
    if ((rX>160) & (rY>120)) begin
      oPIX_RGB = 15'h00f;
    end else begin
      oPIX_RGB = (wBG0_OFFSCREEN) ? 1'b0 : wBG0_RGB;
    end
  end
  
  // ================================================================================
  // state machine
  // ================================================================================
  // state definition
  typedef enum logic [1:0] { sPIX_REQ, sPIX_WAIT, sPIX_OUT } tSTATE;
  
  // state variables
  //(* preserve *)
  tSTATE rSTATE;
  //(* keep *) 
  tSTATE wNEXT_STATE;
  
  // next state
  always_comb begin
    case (rSTATE)
      sPIX_REQ:  wNEXT_STATE = sPIX_WAIT;
      sPIX_WAIT: wNEXT_STATE = (wBG0_READY) ? sPIX_OUT : sPIX_WAIT;
      sPIX_OUT:  wNEXT_STATE = (!iPIX_FULL) ? sPIX_REQ : sPIX_OUT;
      default: wNEXT_STATE = sPIX_REQ;
    endcase
  end
  
  // update state
  always_ff @(posedge iCLOCK) begin
    if (iRESET) begin
      rSTATE <= sPIX_REQ;
    end else begin
      rSTATE <= wNEXT_STATE;
    end
  end
  
  // ================================================================================
  // data path
  // ================================================================================
  
  // output pixel
  // --------------------------------------------------------------------------------
  assign oPIX_WRITE = ((rSTATE==sPIX_OUT) & !iPIX_FULL);
  
  // BG0
  // --------------------------------------------------------------------------------
  logic wBG0_PIX_MOVE;
  // assign wBG0_PIX_MOVE = (rSTATE==sPIX_WAIT & wNEXT_STATE==sPIX_OUT) ? 1'b1 : 1'b0;
  assign wBG0_PIX_MOVE = (wNEXT_STATE==sPIX_REQ);
  logic wBG0_RGB_REQ;
  assign wBG0_RGB_REQ = (rSTATE==sPIX_REQ) ? 1'b1 : 1'b0;
  
  // ================================================================================
  // transfer counter
  // ================================================================================
  logic [cW_WIDTH-1:0] rX = 1'b0;
  logic [cH_WIDTH-1:0] rY = 1'b0;
  logic rPIX_START = 1'b0;
  logic rLINE_START = 1'b0;
  assign oPIX_START = rPIX_START;
  always_ff @(posedge iCLOCK) begin
    if (iRESET) begin
      rX <= 1'b0;
      rY <= 1'b0;
      rPIX_START <= 1'b1;
      rLINE_START <= 1'b0;
    end else if (wNEXT_STATE==sPIX_REQ) begin
      rPIX_START <= 1'b0;
      rLINE_START <= 1'b0;
      rX <= rX + 1'b1;
      if (rX == cW-1) begin
        rX <= 1'b0;
        rLINE_START <= 1'b1;
        rY <= rY + 1'b1;
        if (rY == cH-1) begin
          rPIX_START <= 1'b1;
          // Don't reset rY here. rY is reset after start pixel is sent.
        end
      end
      if (rPIX_START) begin // start pixel is a pseude pixel which is not displayed.
        rX <= 1'b0;
        rY <= 1'b0;
      end
    end
  end
  
  // Counter for check
  // ----------------------------------------
  (* noprune *) logic [31:0] rCHECK_COUNTER;
  always_ff @(posedge iCLOCK) begin
    if (iRESET) begin
      rCHECK_COUNTER <= 1'b0;
    end else if (oPIX_WRITE) begin
      rCHECK_COUNTER <= (rPIX_START) ? 1'b0 : rCHECK_COUNTER + 1'b1;
    end
  end
  
  // ----------------------------------------
  //
  // BG renderer
  //
  // ----------------------------------------
  BG #(
  .pBG_NUM(0)
  ) BG0 (
  .iCLOCK(iCLOCK),                                // clock
  .iRESET(iRESET),                                // reset
  .iPIX_MOVE(wBG0_PIX_MOVE),                         // move pix pos to next
  .iSTART(rPIX_START),                            // Scan start signal
  .iLINE_START(rLINE_START),                      // Line start signal
  .iRGB_REQ(wBG0_RGB_REQ),                          // request for next RGB
  .iREG_ADDR(iAVL_ADDRESS[2:0]),                  // register addr
  .iREG_DATA(iAVL_WRITE_DATA),                    // register data
  .iREG_WRITE(iAVL_WRITE),                        // register write
  .oOFFSCREEN(wBG0_OFFSCREEN),                    // offscreen flag
  .oRGB_WRITE(wBG0_RGB_WRITE),                    // RGB write strobe
  .oRGB_WRITE_DATA(wBG0_RGB),                     // RGB data
  .oSDRAM_ADDRESS(oSDRAM_ADDRESS),                // SDRAM.address
  .oSDRAM_READ(oSDRAM_READ),                      //      .read
  .iSDRAM_WAIT_REQUEST(iSDRAM_WAIT_REQUEST),      //      .waitrequest
  .iSDRAM_READ_DATA(iSDRAM_READ_DATA),            //      .readdata
  .iSDRAM_READ_DATA_VALID(iSDRAM_READ_DATA_VALID) //      .readdatavalid
  );
  
endmodule
