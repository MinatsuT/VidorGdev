/*
* Copyright 2018 ARDUINO SA (http://www.arduino.cc/)
* This file is part of Vidor IP.
* Copyright (c) 2018
* Authors: Dario Pennisi
*
* This software is released under:
* The GNU General Public License, which covers the main part of 
* Vidor IP
* The terms of this license can be found at:
* https://www.gnu.org/licenses/gpl-3.0.en.html
*
* You can be released from the requirements of the above licenses by purchasing
* a commercial license. Buying such a license is mandatory if you want to modify or
* otherwise use the software for commercial activities involving the Arduino
* software without disclosing the source code of your own applications. To purchase
* a commercial license, send an email to license@arduino.cc.
*
*/

module MKRVIDOR4000_top (
         // system signals
         input         iCLK,
         input         iRESETn,
         input         iSAM_INT,
         output        oSAM_INT,

         // SDRAM
         output        oSDRAM_CLK,
         output [11:0] oSDRAM_ADDR,
         output [1:0]  oSDRAM_BA,
         output        oSDRAM_CASn,
         output        oSDRAM_CKE,
         output        oSDRAM_CSn,
         inout  [15:0] bSDRAM_DQ,
         output [1:0]  oSDRAM_DQM,
         output        oSDRAM_RASn,
         output        oSDRAM_WEn,

         // SAM D21 PINS
         inout         bMKR_AREF,
         inout  [6:0]  bMKR_A,
         inout  [14:0] bMKR_D,

         // Mini PCIe
         inout         bPEX_RST,
         inout         bPEX_PIN6,
         inout         bPEX_PIN8,
         inout         bPEX_PIN10,
         input         iPEX_PIN11,
         inout         bPEX_PIN12,
         input         iPEX_PIN13,
         inout         bPEX_PIN14,
         inout         bPEX_PIN16,
         inout         bPEX_PIN20,
         input         iPEX_PIN23,
         input         iPEX_PIN25,
         inout         bPEX_PIN28,
         inout         bPEX_PIN30,
         input         iPEX_PIN31,
         inout         bPEX_PIN32,
         input         iPEX_PIN33,
         inout         bPEX_PIN42,
         inout         bPEX_PIN44,
         inout         bPEX_PIN45,
         inout         bPEX_PIN46,
         inout         bPEX_PIN47,
         inout         bPEX_PIN48,
         inout         bPEX_PIN49,
         inout         bPEX_PIN51,

         // NINA interface
         inout         bWM_PIO1,
         inout         bWM_PIO2,
         inout         bWM_PIO3,
         inout         bWM_PIO4,
         inout         bWM_PIO5,
         inout         bWM_PIO7,
         inout         bWM_PIO8,
         inout         bWM_PIO18,
         inout         bWM_PIO20,
         inout         bWM_PIO21,
         inout         bWM_PIO27,
         inout         bWM_PIO28,
         inout         bWM_PIO29,
         inout         bWM_PIO31,
         input         iWM_PIO32,
         inout         bWM_PIO34,
         inout         bWM_PIO35,
         inout         bWM_PIO36,
         input         iWM_TX,
         inout         oWM_RX,
         inout         oWM_RESET,

         // HDMI output
         output [2:0]  oHDMI_TX,
         output        oHDMI_CLK,

         inout         bHDMI_SDA,
         inout         bHDMI_SCL,

         input         iHDMI_HPD,

         // MIPI input
         input  [1:0]  iMIPI_D,
         input         iMIPI_CLK,
         inout         bMIPI_SDA,
         inout         bMIPI_SCL,
         inout  [1:0]  bMIPI_GP,

         // Q-SPI Flash interface
         output        oFLASH_SCK,
         output        oFLASH_CS,
         inout         oFLASH_MOSI,
         inout         iFLASH_MISO,
         inout         oFLASH_HOLD,
         inout         oFLASH_WP

       );

// signal declaration
// Clocks
wire wCLK48 = iCLK;

// System PLL
wire        wMEM_CLK;
SYSTEM_PLL PLL_inst_sys (
             .areset(1'b0),
             .inclk0(wCLK48),
             .c2(wMEM_CLK),   // 140MHz for NIOS II
             .c3(oSDRAM_CLK), // 140MHz for SDRAM 180deg phase
             .locked());

// VID PLL
wire        wCLK24, wCLK120;
wire        wVID_CLK, wVID_CLKx5, wFLASH_CLK;
assign wVID_CLK   = wCLK24;
assign wVID_CLKx5 = wCLK120;
VID_PLL PLL_inst_vid (
          .areset(1'b0),
          .inclk0(wCLK48),
          .c0(wCLK24),     // for VID
          .c1(wCLK120),    // for VID
          .c4(wFLASH_CLK),
          .locked());

// SPI Avlon-MM bridge
wire wSS,wMOSI,wSCK,wMISO;
assign bMKR_D[7] = 1'bz;
assign wSS   = bMKR_D[7];
assign bMKR_D[8] = 1'bz;
assign wMOSI = bMKR_D[8];
assign bMKR_D[9] = 1'bz;
assign wSCK  = bMKR_D[9];
assign bMKR_D[10] = wMISO;

// PIO
wire wPIO;
assign bMKR_D[0] = wPIO;

// SDRAM
wire        wDPRAM_CS;

// HDMI/DVI-OUT
wire [7:0]  wDVI_RED,wDVI_GRN,wDVI_BLU;
wire        wDVI_HS, wDVI_VS, wDVI_DE;
DVI_OUT (
    .iPCLK(wVID_CLK),
    .iSCLK(wVID_CLKx5),

    .iRED(wDVI_RED),
    .iGRN(wDVI_GRN),
    .iBLU(wDVI_BLU),
    .iHS (wDVI_HS),
    .iVS (wDVI_VS),
    .iDE (wDVI_DE),

    .oDVI_DATA(oHDMI_TX),
    .oDVI_CLK(oHDMI_CLK),
    .iDVI_HPD(iHDMI_HPD)
  );

// SCANLINE
wire [14:0] wPIX_RGB;
wire wPIX_WRITE,wPIX_START,wPIX_FULL;
wire [14:0] wFB_RGB;
wire wFB_START,wFB_DATAVALID,wFB_READY;
SCANLINE (
    .iPIX_CLK(wMEM_CLK),
    .iPIX_RGB(wPIX_RGB),
    .iPIX_WRITE(wPIX_WRITE),
    .iPIX_START(wPIX_START),
    .oPIX_FULL(wPIX_FULL),

    .iFB_CLK(wVID_CLK),
    .oFB_START(wFB_START),
    .oFB_RGB(wFB_RGB),
    .oFB_DATAVALID(wFB_DATAVALID),
    .iFB_READY(wFB_READY)
  );

// RESET
reg [5:0] rRESETCNT;
assign bMKR_D[6] = 1'bz;
always @(posedge wMEM_CLK) begin
  if (!rRESETCNT[5]) begin
    rRESETCNT<=rRESETCNT+1'd1;
  end
  if (bMKR_D[6]) begin // soft reset
    rRESETCNT <= 6'd0;
  end
end

// QSYS
MKRVIDOR4000_gdev_lite_sys u0 (
                             .clk_clk                (wMEM_CLK),        //   clk.clk
                             .reset_reset_n          (rRESETCNT[5]),    // reset.reset_n
                             .vidclk_clk             (wVID_CLK),        //   vid.clk

                             .vid_mixer_pix_full     (wPIX_FULL),       // vid_mixer.pix_full
                             .vid_mixer_pix_rgb      (wPIX_RGB),        //          .pix_rgb
                             .vid_mixer_pix_start    (wPIX_START),      //          .pix_start
                             .vid_mixer_pix_write    (wPIX_WRITE),      //          .pix_write

                             .fb_st_start            (wFB_START),    //  fb_st.start
                             .fb_st_data             (wFB_RGB),      //       .data
                             .fb_st_dv               (wFB_DATAVALID),//       .dv
                             .fb_st_ready            (wFB_READY),    //       .ready

                             .fb_vport_red           (wDVI_RED),     //      .red
                             .fb_vport_grn           (wDVI_GRN),     //      .grn
                             .fb_vport_blu           (wDVI_BLU),     // vport.blu
                             .fb_vport_de            (wDVI_DE),      //      .de
                             .fb_vport_hs            (wDVI_HS),      //      .hs
                             .fb_vport_vs            (wDVI_VS),      //      .vs

                             .sdram_addr             (oSDRAM_ADDR), //    sdram.addr
                             .sdram_ba               (oSDRAM_BA),   //         .ba
                             .sdram_cas_n            (oSDRAM_CASn), //         .cas_n
                             .sdram_cke              (oSDRAM_CKE),  //         .cke
                             .sdram_cs_n             (oSDRAM_CSn),  //         .cs_n
                             .sdram_dq               (bSDRAM_DQ),   //         .dq
                             .sdram_dqm              (oSDRAM_DQM),  //         .dqm
                             .sdram_ras_n            (oSDRAM_RASn), //         .ras_n
                             .sdram_we_n             (oSDRAM_WEn),  //         .we_n

                             .spi_slave_mosi_to_the_spislave_inst_for_spichain          (wMOSI), // spi_slave.mosi_to_the_spislave_inst_for_spichain
                             .spi_slave_nss_to_the_spislave_inst_for_spichain           (wSS),   //          .nss_to_the_spislave_inst_for_spichain
                             .spi_slave_miso_to_and_from_the_spislave_inst_for_spichain (wMISO), //          .miso_to_and_from_the_spislave_inst_for_spichain
                             .spi_slave_sclk_to_the_spislave_inst_for_spichain          (wSCK),  //          .sclk_to_the_spislave_inst_for_spichain

                             .pio_export             (wPIO)   //       pio.export

                           );


endmodule
