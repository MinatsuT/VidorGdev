/*
 * Copyright 2019 Minatsu Tukisima
 *
 * BG Renderer for MKR VIDOR 4000
 *
 */
 `timescale 1 ps / 1 ps
 `include "VID_MIXER.pkg"
 module BG 
    import VidMixer::*;
    #(
    parameter pBG_NUM = 0
    )
    (
    input iCLOCK, // clock
    input iRESET, // reset
    
    input iPIX_MOVE, // move pix pos to next
    input iSTART, // Scan start signal
    input iLINE_START, // Line start signal
    
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
    tVEC_2D rO; // scan origin
    tVEC_2D rU; // a unit vector of horizontal axis for scan
    tVEC_2D rV; // a unit vector of vertical axis for scan
    
    // register addresses
    enum { OX,OY,UX,UY,VX,VY } eREG_ADDR;
    
    // register set/reset
    always_ff @(posedge iCLOCK) begin
        if (iRESET) begin
            rO.x <= 0;
            rO.y <= 0;
            rU.x <= 32'h00001000;
            rU.y <= 0;
            rV.x <= 0;
            rV.y <= 32'h00001000;
        end else begin
            if (iREG_WRITE) begin
                case (iREG_ADDR)
                    OX: rO.x <= iREG_DATA;
                    OY: rO.y <= iREG_DATA;
                    UX: rU.x <= iREG_DATA;
                    UY: rU.y <= iREG_DATA;
                    VX: rV.x <= iREG_DATA;
                    VY: rV.y <= iREG_DATA;
                    default:;
                endcase
            end
        end
    end
    
    // ================================================================================
    // working variables
    // ================================================================================
    tVEC_2D rL; // starting point of scanning line
    tVEC_2D rP; // scanning point
    
    // clipping detection
    // --------------------------------------------------------------------------------
    tVEC_2D_I wPI;
    assign wPI = VEC_2D_int(rP);
    assign oOFFSCREEN = (wPI.x<0) | (wPI.y<0) | (wPI.x>=cSCR_W) | (wPI.y>=cSCR_H);
    
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
    typedef enum logic [2:0] { sIDLE, sRD_SCR, sRDWT_SCR, sRD_PCG, sRDWT_PCG, sWR_RGB } tSTATE;
    
    // state variables
    (* preserve *) tSTATE rSTATE;
    (* keep *) tSTATE wNEXT_STATE;
    
    // next state
    always_comb begin
        case (rSTATE)
            sIDLE:     wNEXT_STATE = (iRGB_REQ) ? sRD_SCR : sIDLE;
            sRD_SCR:   wNEXT_STATE = (!oOFFSCREEN) ? sRDWT_SCR : sWR_RGB;
            sRDWT_SCR: wNEXT_STATE = (iSDRAM_READ_DATA_VALID) ? sRD_PCG : sRDWT_SCR;
            sRD_PCG:   wNEXT_STATE = sRDWT_PCG;
            sRDWT_PCG: wNEXT_STATE = (iSDRAM_READ_DATA_VALID) ? sWR_RGB : sRDWT_PCG;
            sWR_RGB:   wNEXT_STATE = sIDLE;
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
    always_ff @(posedge iCLOCK) begin
        if (iPIX_MOVE) begin
            rP <= VEC_2D_add(rP, rU);
            if (iLINE_START) begin
                rP <= rL;
                rL <= VEC_2D_add(rL, rV);
            end
            if (iSTART) begin
                rP <= rO;
                rL <= VEC_2D_add(rO, rV);
            end
        end
    end
    
    // --------------------------------------------------------------------------------
    // SDRAM read address
    // --------------------------------------------------------------------------------
    
    // BG screen address
    (* keep *) logic [cBG_W_WIDTH-1:0] wBG_X;
    (* keep *) logic [cBG_H_WIDTH-1:0] wBG_Y;
    assign wBG_X = Q_int(rP.x >> cCHR_W_WIDTH);
    assign wBG_Y = Q_int(rP.y >> cCHR_H_WIDTH);
    tADDR wSCR_ADDR;
    assign wSCR_ADDR = cSCR_ADDR + (wBG_Y * cBG_W) + wBG_X;
    
    // PCG address
    tPCG rPCG;
    (* keep *) logic [cCHR_W_WIDTH-1:0] wCHR_X;
    (* keep *) logic [cCHR_H_WIDTH-1:0] wCHR_Y;
    assign wCHR_X = Q_int(rP.x);
    assign wCHR_Y = Q_int(rP.y);
    tADDR wPCG_ADDR;
    assign wPCG_ADDR = cPCG_ADDR + (cCHR_WORDS * rPCG) + (wCHR_Y * cCHR_W) + wCHR_X;
    
    // SDRAM address
    // --------------------------------------------------------------------------------
    always_comb begin
        case (wNEXT_STATE)
            sRD_PCG:   oSDRAM_ADDRESS = wPCG_ADDR;
            sRDWT_PCG: oSDRAM_ADDRESS = wPCG_ADDR;
            default:   oSDRAM_ADDRESS = wSCR_ADDR;
        endcase
    end
    
    // SDRAM read request
    // --------------------------------------------------------------------------------
    logic wSDRAM_READ;
    assign oSDRAM_READ = wSDRAM_READ;
    always_comb begin
        case (wNEXT_STATE)
            sRD_SCR:   wSDRAM_READ = 1'b1;
            sRDWT_SCR: wSDRAM_READ = 1'b1;
            sRD_PCG:   wSDRAM_READ = 1'b1;
            sRDWT_PCG: wSDRAM_READ = 1'b1;
            default:   wSDRAM_READ = 1'b0;
        endcase
    end
    
    // PCG data
    // --------------------------------------------------------------------------------
    always_ff @(posedge iCLOCK) begin
        if (wNEXT_STATE==sRD_PCG) rPCG <= iSDRAM_READ_DATA;
    end
    
    // RGB data and write
    // --------------------------------------------------------------------------------
    always_ff @(posedge iCLOCK) begin
        if (wNEXT_STATE==sRD_SCR) begin
            rRGB_WRITE <= 1'b0;
        end
        if (wNEXT_STATE==sWR_RGB) begin
            rRGB_WRITE <= 1'b1;
            rRGB <= iSDRAM_READ_DATA;
        end
    end
    
endmodule
