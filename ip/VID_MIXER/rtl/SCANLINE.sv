/*
 * Copyright 2019 Minatsu Tukisima
 *
 * Scanline Converter for MKR VIDOR 4000
 *
 */
 
 module SCANLINE #(
  parameter pW=320,
  parameter pH=240,
  parameter pADDR_WIDTH=9
  )
  (
  input             iPIX_CLK,
  input             iPIX_START,
  input [14:0]      iPIX_RGB,
  input             iPIX_WRITE,
  output            oPIX_FULL,
  
  input             iFB_CLK,
  output            oFB_START,
  output [14:0]     oFB_RGB,
  output            oFB_DATAVALID,
  input             iFB_READY
  );
  
  localparam cSCANLINE_COL_WIDTH = 10;
  
  // Scanline buffer
  logic [pADDR_WIDTH-1:0] rHEAD = 0;
  logic [pADDR_WIDTH-1:0] rTAIL = 0;
  wire [pADDR_WIDTH-1:0] wWADDR = rHEAD;
  wire [pADDR_WIDTH-1:0] wRADDR;
  (* keep *) wire [pADDR_WIDTH-1:0] wDAT_LEN = rHEAD-rTAIL;
  assign oPIX_FULL = (wDAT_LEN==(512-1));
  wire wSCANLINE_START;
  wire [14:0] wSCANLINE_RGB;
  ram_2port ram_2port_inst (
  .clock ( iPIX_CLK ),
  .data ( {iPIX_START, iPIX_RGB} ),
  .rdaddress ( wRADDR ),
  .wraddress ( wWADDR ),
  .wren ( iPIX_WRITE ),
  .q ( {wSCANLINE_START, wSCANLINE_RGB} )
  );
  
  // Store 320x240 pixel data
  always_ff @(posedge iPIX_CLK) begin
    if (iPIX_WRITE) begin
      rHEAD <= rHEAD + 1'd1;
    end
    if (oPIX_FULL && iPIX_WRITE) begin
      $messagelog("%:S oPIX_FULL && iPIX_WRITE","Fatal");
    end
  end
  
  // Generate 640x480 pixel data
  wire wPIX2FB_WRFULL;
  wire wPIX2FB_WRREQ = (wDAT_LEN>0) && !wPIX2FB_WRFULL;
  logic rSCANLINE_START = 0;
  logic [14:0] rSCANLINE_RGB = 0;
  logic [cSCANLINE_COL_WIDTH-1:0] rSCANLINE_COL = 0;
  wire wSCANLINE_ODD = rSCANLINE_COL[0:0];
  logic rSCANLINE_ROW = 0;
  wire wSCANLINE_1ST_ROW = (rSCANLINE_ROW==0);
  logic [pADDR_WIDTH-1:0] rSCANLINE_RADDR = 0;
  assign wRADDR = (wSCANLINE_1ST_ROW) ? rSCANLINE_RADDR : rTAIL;
  always_ff @(posedge iPIX_CLK) begin
    if (wPIX2FB_WRREQ) begin
      // Address control
      rSCANLINE_COL <= rSCANLINE_COL + 1'd1;
      if (rSCANLINE_COL==(640-1)) begin
        rSCANLINE_COL <= 0;
        rSCANLINE_ROW <= rSCANLINE_ROW + 1'd1;
      end
      rSCANLINE_RADDR <= rSCANLINE_RADDR + ((wSCANLINE_1ST_ROW && wSCANLINE_ODD) ? 1'd1 : 1'd0);
      rTAIL <= rTAIL + ((!wSCANLINE_1ST_ROW && wSCANLINE_ODD) ? 1'd1 : 1'd0);
      // Data written to FB
      rSCANLINE_START <= wSCANLINE_START;
      rSCANLINE_RGB <= wSCANLINE_RGB;
      // Sync to START marker pixel. (The marker pixsel itself is not displayed.)
      if (wSCANLINE_START) begin
        rSCANLINE_COL <= 0;
        rSCANLINE_ROW <= 0;
        rSCANLINE_RADDR <= rSCANLINE_RADDR + 1'd1;
        rTAIL <= rSCANLINE_RADDR + 1'd1;
      end
    end
  end

  // Output FIFO
  (* keep *) wire wPIX2FB_RDEMPTY;
  wire wPIX2FB_RDREQ = !wPIX2FB_RDEMPTY && iFB_READY;
  wire [15:0] wPIX2FB_DATA;
  pix2fbfifo pix2fbfifo_inst (
  .data ( {rSCANLINE_START, rSCANLINE_RGB} ),
  .rdclk ( iFB_CLK ),
  .rdreq ( wPIX2FB_RDREQ),
  .wrclk ( iPIX_CLK ),
  .wrreq ( wPIX2FB_WRREQ),
  .q ( wPIX2FB_DATA ),
  .rdempty ( wPIX2FB_RDEMPTY ),
  .wrfull ( wPIX2FB_WRFULL )
  );
  assign oFB_DATAVALID = wPIX2FB_RDREQ;
  assign {oFB_START, oFB_RGB} = wPIX2FB_DATA;
  
endmodule