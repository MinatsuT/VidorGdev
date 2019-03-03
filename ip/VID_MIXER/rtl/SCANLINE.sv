/*
 * Copyright 2019 Minatsu Tukisima
 *
 * Scanline Converter Mixer for MKR VIDOR 4000
 *
 */
 
 module SCANLINE #(
  parameter pW=320,
  parameter pH=240,
  parameter pADDR_WIDTH=9
  )
  (
  input             iPIX_CLK,
  input [14:0]      iPIX_DATA,
  input             iPIX_WRITE,
  input             iPIX_START,
  output            oPIX_FULL,
  
  input             iFB_CLK,
  output            oFB_START,
  output [14:0]     oFB_DATA,
  output            oFB_DATAVALID,
  input             iFB_READY
  );
  
  wire [pADDR_WIDTH-1:0] wRADDR,wWADDR;
  wire wWEN;
  wire [15:0] wSCANLINE_DATA;
  ram_2port ram_2port_inst (
  .clock ( iPIX_CLK ),
  .data ( iPIX_DATA ),
  .rdaddress ( wRADDR ),
  .wraddress ( wWADDR ),
  .wren ( iPIX_WRITE ),
  //.q ( wSCANLINE_DATA )
  .q ()
  );
  
  wire wPIX2FB_WRFULL;
  wire wPIX2FB_RDEMPTY;
  wire wPIX2FB_WRREQ = !wPIX2FB_WRFULL;
  wire wPIX2FB_RDREQ = !wPIX2FB_RDEMPTY && iFB_READY;
  wire [15:0] wPIX2FB_DATA;
  
  pix2fbfifo pix2fbfifo_inst (
	.data ( wSCANLINE_DATA ),
	.rdclk ( iFB_CLK ),
	.rdreq ( wPIX2FB_RDREQ),
	.wrclk ( iPIX_CLK ),
	.wrreq ( wPIX2FB_WRREQ),
	.q ( wPIX2FB_DATA ),
	.rdempty ( wPIX2FB_RDEMPTY ),
  .wrfull ( wPIX2FB_WRFULL )
  );
  
  logic rFB_START=0;
  logic [14:0] rTMP_DAT=15'h7fff;
  logic [18:0] rTMP_CNT=0;
  logic [18:0] rFB_COUNT=0;

  wire [31:0] rOFS=(rFB_COUNT+rTMP_CNT)%(640*480);
  wire [31:0] wX=rOFS % 640;
  wire [31:0] wY=rOFS / 640;
  wire [4:0] wB=32*wX/640;
  wire [4:0] wG=32*wY/480;
  wire [4:0] wR=31-32*wY/480;

  assign wSCANLINE_DATA = {rFB_START, rTMP_DAT};
  always_ff @(posedge iPIX_CLK) begin
    if (wPIX2FB_WRREQ) begin
      rFB_START <= (rFB_COUNT==(640*480-1)) ? 1'b1 : 1'b0;
      if (rFB_COUNT==(640*480)) begin
        rTMP_CNT <= (rTMP_CNT+641)%(640*480);
        rFB_COUNT <= 0;
      end else begin
        rFB_COUNT <= rFB_COUNT+1'd1;
      end
      rTMP_DAT <= {wR,wG,wB};
      /*
      if ((((rFB_COUNT+1)/640) % 3)==0) begin
        rTMP_DAT <= 15'b11111_00000_00000;
      end
      if ((((rFB_COUNT+1)/640) % 3)==1) begin
        rTMP_DAT <= 15'b00000_11111_00000;
      end
      if ((((rFB_COUNT+1)/640) % 3)==2) begin
        rTMP_DAT <= 15'b00000_00000_11111;
      end
      */
    end
  end
  
  logic rPIX2FB_DATAVALID=1'b0;
  logic riFB_READY=0;
  always_ff @(posedge iFB_CLK) begin
    rPIX2FB_DATAVALID <= wPIX2FB_RDREQ;
  end
  //assign oFB_DATAVALID = rPIX2FB_DATAVALID;
  assign oFB_DATAVALID = wPIX2FB_RDREQ;
  assign {oFB_START, oFB_DATA} = wPIX2FB_DATA;
  
endmodule