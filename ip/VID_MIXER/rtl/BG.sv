/*
 * Copyright 2019 Minatsu Tukisima
 *
 * BG Renderer for MKR VIDOR 4000
 *
 */
 `timescale 1 ps / 1 ps
 `include "VID_MIXER.pkg"
 import VidMixer::*;
 module BG 
    #(
    parameter pBG_NUM = 0
    )
    (
    input iCLOCK, // clock
    input iRESET, // reset
    
    input iPIX_START, // next scan position is TOP-LEFT
    input [cW_WIDTH-1:0] iX, // coordinates of the pixel to be rendered
    input [cH_WIDTH-1:0] iY,
    
    input iRGB_REQ, // request for next RGB
    
    input  [2:0]  iREG_ADDR, // register addr
    input  [31:0] iREG_DATA, // register data
    input         iREG_WRITE, // register write
    
    output        oOFFSCREEN, // offscreen flag
    
    output        oRGB_WRITE, // RGB write strobe
    output tRGB   oRGB_WRITE_DATA, // RGB data
    
    output tADDR  oSDRAM_ADDRESS,         // SDRAM.address
    output        oSDRAM_READ,            //      .read
    input         iSDRAM_WAIT_REQUEST,    //      .waitrequest
    input  [15:0] iSDRAM_READ_DATA,       //      .readdata
    input         iSDRAM_READ_DATA_VALID  //      .readdatavalid
    );
    localparam cSCR_ADDR = cBG_SCR_ADDR + cBG_WORDS * pBG_NUM; // BG screen address
    
    // ================================================================================
    // registers
    // ================================================================================
    tVEC_2D rO,rO_tmp; // scan origin
    tVEC_2D rU,rU_tmp; // a unit vector of horizontal axis for scan
    tVEC_2D rV,rV_tmp; // a unit vector of vertical axis for scan
    
    // register addresses
    enum { OX,OY,UX,UY,VX,VY } eREG_ADDR;
    
    // register set/reset
    always_ff @(posedge iCLOCK) begin
        if (iRESET) begin
            rO_tmp.x <= 0;
            rO_tmp.y <= 0;
            rU_tmp.x <= 32'h00001000;
            rU_tmp.y <= 0;
            rV_tmp.x <= 0;
            rV_tmp.y <= 32'h00001000;
        end else begin
            if (iREG_WRITE) begin
                case (iREG_ADDR)
                    OX: rO_tmp.x <= iREG_DATA;
                    OY: rO_tmp.y <= iREG_DATA;
                    UX: rU_tmp.x <= iREG_DATA;
                    UY: rU_tmp.y <= iREG_DATA;
                    VX: rV_tmp.x <= iREG_DATA;
                    VY: rV_tmp.y <= iREG_DATA;
                    default:;
                endcase
            end
        end
    end 
    
    // register update
    // --------------------------------------------------------------------------------
    logic rREG_NEED_UPDATE = 1'b0;
    always_ff @(posedge iCLOCK) begin
        if (iPIX_START & rREG_NEED_UPDATE) begin
            rREG_NEED_UPDATE <= 1'b0;
            rO <= rO_tmp;
            rU <= rU_tmp;
            rV <= rV_tmp;
        end
        if (iREG_WRITE & iREG_ADDR==VY) begin
            rREG_NEED_UPDATE <= 1'b1;
        end
    end
    
    // ================================================================================
    // working variables
    // ================================================================================
    tVEC_2D rP; // scanning point
    
    // clipping detection
    // --------------------------------------------------------------------------------
    tVEC_2D_I wPI;
    assign wPI = VEC_2D_int(rP);
    assign wOFFSCREEN = (wPI.x<0) | (wPI.y<0) | (wPI.x>=cSCR_W) | (wPI.y>=cSCR_H);
    logic rOFFSCREEN;
    assign oOFFSCREEN = rOFFSCREEN;
    
    // RGB out
    // --------------------------------------------------------------------------------
    logic rRGB_WRITE;
    assign oRGB_WRITE = rRGB_WRITE;
    tRGB rRGB;
    assign oRGB_WRITE_DATA = rRGB;
    
    // ================================================================================
    // state machine
    // ================================================================================
    // state definition
    typedef enum logic [2:0] { sIDLE, sUPD_SCADR, sCHK_OFSC, sRD_SCR, sRDWT_SCR, sRD_PCG, sRDWT_PCG, sWR_RGB } tSTATE;
    
    // state variables
    tSTATE rSTATE;
    tSTATE wNEXT_STATE;
    
    // next state
    always_comb begin
        case (rSTATE)
            sIDLE:       wNEXT_STATE = (iRGB_REQ) ? sUPD_SCADR : sIDLE;
            sUPD_SCADR:  wNEXT_STATE = sCHK_OFSC;
            sCHK_OFSC:   wNEXT_STATE = (rOFFSCREEN) ? sWR_RGB : (rSCR_ADDR==rLAST_SCR_ADDR) ? sRD_PCG : sRD_SCR;
            sRD_SCR:     wNEXT_STATE = sRDWT_SCR;
            sRDWT_SCR:   wNEXT_STATE = (iSDRAM_READ_DATA_VALID) ? sRD_PCG : sRDWT_SCR;
            sRD_PCG:     wNEXT_STATE = sRDWT_PCG;
            sRDWT_PCG:   wNEXT_STATE = (iSDRAM_READ_DATA_VALID) ? sWR_RGB : sRDWT_PCG;
            sWR_RGB:     wNEXT_STATE = sIDLE;
            default: wNEXT_STATE = sIDLE;
        endcase
    end
    
    // update state
    always_ff @(posedge iCLOCK) begin
        if (iRESET) begin
            rSTATE <= sIDLE;
        end else begin
            rSTATE <= wNEXT_STATE;
        end
    end
    
    // ================================================================================
    // data path
    // ================================================================================
    
    // scan position update
    // --------------------------------------------------------------------------------
    // P = O + U*x + V*y
    tCOORD rUxX,rVxY;
    tCOORD rUyX,rVyY;
    always_ff @(posedge iCLOCK) begin
        if (rSTATE==sIDLE) begin
            // This must always update because it affects to oOFFSCREEN.
            rUxX <= rU.x * tCOORD'(iX);
            rVxY <= rV.x * tCOORD'(iY);
            rUyX <= rU.y * tCOORD'(iX);
            rVyY <= rV.y * tCOORD'(iY);
            rP.x <= rO.x + rUxX + rVxY;
            rP.y <= rO.y + rUyX + rVyY;
            // rP.x <= rO.x + ((rU.x)*tCOORD'(iX) + (rV.x)*tCOORD'(iY));
            // rP.y <= rO.y + ((rU.y)*tCOORD'(iX) + (rV.y)*tCOORD'(iY));
        end
    end
    
    // offscreen flag
    // --------------------------------------------------------------------------------
    always_ff @(posedge iCLOCK) begin
        if (rSTATE==sUPD_SCADR) begin
            rOFFSCREEN <= wOFFSCREEN;
        end
    end
    
    // --------------------------------------------------------------------------------
    // SDRAM read address
    // --------------------------------------------------------------------------------
    
    // BG screen address
    // --------------------------------------------------------------------------------
    logic [cBG_W_WIDTH-1:0] wBG_X;
    logic [cBG_H_WIDTH-1:0] wBG_Y;
    assign wBG_X = Q2I(rP.x >> cCHR_W_WIDTH);
    assign wBG_Y = Q2I(rP.y >> cCHR_H_WIDTH);
    tADDR wSCR_ADDR;
    assign wSCR_ADDR = cSCR_ADDR + (wBG_Y * cBG_W) + wBG_X;
    tADDR rSCR_ADDR;
    tADDR rLAST_SCR_ADDR;
    always_ff @(posedge iCLOCK) begin
        if (rSTATE==sUPD_SCADR) begin
            rLAST_SCR_ADDR <= rSCR_ADDR;
            rSCR_ADDR <= wSCR_ADDR;
        end
    end
    
    // PCG number
    // --------------------------------------------------------------------------------
    tPCG rPCG;
    always_ff @(posedge iCLOCK) begin
        if (rSTATE==sRDWT_SCR & iSDRAM_READ_DATA_VALID) begin
            rPCG <= iSDRAM_READ_DATA;
        end
    end
    
    // PCG address
    // --------------------------------------------------------------------------------
    logic [cCHR_W_WIDTH-1:0] wCHR_X;
    logic [cCHR_H_WIDTH-1:0] wCHR_Y;
    assign wCHR_X = Q2I(rP.x);
    assign wCHR_Y = Q2I(rP.y);
    tADDR wPCG_ADDR;
    assign wPCG_ADDR = cPCG_ADDR + (cCHR_WORDS * rPCG) + (wCHR_Y * cCHR_W) + wCHR_X;
    
    // SDRAM address
    // --------------------------------------------------------------------------------
    assign oSDRAM_ADDRESS = (rSTATE==sRD_PCG|rSTATE==sRDWT_PCG) ? wPCG_ADDR : rSCR_ADDR;
    // always_comb begin
    //     case (wNEXT_STATE)
    //         sRD_PCG:   oSDRAM_ADDRESS = wPCG_ADDR;
    //         sRDWT_PCG: oSDRAM_ADDRESS = wPCG_ADDR;
    //         default:   oSDRAM_ADDRESS = wSCR_ADDR;
    //     endcase
    // end
    
    // SDRAM read request
    // --------------------------------------------------------------------------------
    logic rSDRAM_READ;
    assign oSDRAM_READ = rSDRAM_READ;
    always_ff @(posedge iCLOCK) begin
        if (rSDRAM_READ & !iSDRAM_WAIT_REQUEST) begin
            rSDRAM_READ <= 1'b0;
        end
        if (wNEXT_STATE==sRD_SCR) begin
            rSDRAM_READ <= 1'b1;
        end
        if (wNEXT_STATE==sRD_PCG) begin
            rSDRAM_READ <= 1'b1;
        end
    end
    // logic wSDRAM_READ;
    // assign oSDRAM_READ = wSDRAM_READ;
    // always_comb begin
    //     case (wNEXT_STATE)
    //         sRD_SCR:   wSDRAM_READ = 1'b1;
    //         sRDWT_SCR: wSDRAM_READ = 1'b1;
    //         sRD_PCG:   wSDRAM_READ = 1'b1;
    //         sRDWT_PCG: wSDRAM_READ = 1'b1;
    //         default:   wSDRAM_READ = 1'b0;
    //     endcase
    // end
    
    // PCG data
    // --------------------------------------------------------------------------------
    // always_ff @(posedge iCLOCK) begin
    //     if (rSTATE==sRDWT_SCR) begin
    //         rPCG <= iSDRAM_READ_DATA;
    //     end 
    // end
    
    // RGB data and write
    // --------------------------------------------------------------------------------
    always_ff @(posedge iCLOCK) begin
        if (rSTATE==sIDLE) begin
            rRGB_WRITE <= 1'b0;
        end
        if (rSTATE==sRDWT_PCG) begin
            rRGB <= iSDRAM_READ_DATA;
        end
        if (wNEXT_STATE==sWR_RGB) begin
            rRGB_WRITE <= 1'b1;
        end
    end
    
endmodule

