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

module NEOPIXEL #(
  pCHANNELS=23,
  pSTART_ADDRESS=0
) (
  input                      iCLOCK,
  input                      iRESET,

  input       [3:0]          iCSR_ADDRESS,
  input                      iCSR_READ,
  output reg [31:0]          oCSR_READ_DATA,
  input                      iCSR_WRITE,
  input      [31:0]          iCSR_WRITE_DATA,

  output reg [31:0]          oDATA_ADDRESS,
  output reg                 oDATA_READ,
  input                      iDATA_WAIT_REQUEST,
  output [4:0]               oDATA_BURST_COUNT,
  input  [31:0]              iDATA_READ_DATA,
  input                      iDATA_READ_DATA_VALID,

  output reg                 oIRQ,
  output reg [pCHANNELS-1:0] oDATA,
  output reg                 oCLK
);

localparam pCHANNEL_BITS = $clog2(pCHANNELS);

enum reg [3:0] {eST_IDLE,                  // idle state where we wait for start update command
                eST_PRELOAD,               // preload temporary buffer with one pixel
                eST_SHIFTING,              // state that produces output data to update strings
                eST_RESETTING              // state that generates reset pulse to indicate string end
               } rINT_STATE;               // holds system state
reg [4:0]  rBIT_COUNTER,                   // counts bits in a word
           rBIT_COUNT;                     // holds number of bits per word
reg [15:0] rCOUNTER;                       // counts pixels in a string
reg [15:0] rT0H,                           // holds number of clocks to stay high for 0 bit
           rT1H,                           // holds number of clocks to stay high for 1 bit
           rTT,                            // holds number of clocks for total duration of a bit
           rTRESET;                        // holds number of clocks for Treset, the minimum time
                                           // to wait before sending a new set of pixels
reg [14:0]                rSTRING_LEN;     // holds total number of pixels in a string
reg [14:0]                rREG_STRING_LEN; // holds total number of pixels in a string
reg [pCHANNELS-1:0][31:0] rPIXEL_DATA;     // holds pixels being shifted out
reg [pCHANNELS-1:0][31:0] rTMP_DATA;       // temporary buffer for next pixel to shift
reg [pCHANNELS-1:0]       rMASK;           // holds mask flagging which strings will be updated
reg [pCHANNEL_BITS-1:0]   rCHAN_CNT;       // counts channels during burst accesses
reg                       rSTART;          // start update request flag
reg [31:0]                rSTART_ADDRESS;  // start address for the buffer to transmit
reg [31:0]                rWRAP_ADDRESS;   // address at which the address is set at wrap
reg [14:0]                rWRAP_COUNT;     // count at which wrap is done
reg [14:0]                rLINE_LENGTH;    // length of a line (used for zig zag mode)
reg                       rZIGZAG;         // Zig Zag mode
reg [31:0]                rZZ_OFFSET;      // offset to add to address when moving to next line in zigzag mode
reg [14:0]                rHCNT;           // Zig Zag horizontal counter
reg                       rZZSTATE;        // state of the zigzag pattern
reg                       rAPA;            // if set outpus data in APA format
reg                       rAPA_SOF;        // flag APA Start of Frame

integer i;
assign oDATA_BURST_COUNT = pCHANNELS;      // burst size is fixed at compile time

initial rSTART_ADDRESS <= pSTART_ADDRESS;

always @(posedge iCLOCK)
begin
  // handle slave bus interface
  if (iCSR_WRITE) begin
    case (iCSR_ADDRESS)
      0: rMASK <= iCSR_WRITE_DATA;
      1: begin
        // writing this register clears interrupt request. if start bit is set
        // a string update cycle is started
        if (rINT_STATE==eST_IDLE) {rAPA, rSTART,rREG_STRING_LEN, rBIT_COUNT} <= iCSR_WRITE_DATA;
        oIRQ<=0;
      end
      2: if (rINT_STATE==eST_IDLE) rTRESET <= iCSR_WRITE_DATA;
      3: if (rINT_STATE==eST_IDLE) rT0H <= iCSR_WRITE_DATA;
      4: if (rINT_STATE==eST_IDLE) rT1H <= iCSR_WRITE_DATA;
      5: if (rINT_STATE==eST_IDLE) rTT <= iCSR_WRITE_DATA;
      6: if (rINT_STATE==eST_IDLE) {rZIGZAG, rZZSTATE,rLINE_LENGTH,rWRAP_COUNT} <= iCSR_WRITE_DATA;
      8: if (rINT_STATE==eST_IDLE) rSTART_ADDRESS <= iCSR_WRITE_DATA;
      9: if (rINT_STATE==eST_IDLE) rWRAP_ADDRESS <= iCSR_WRITE_DATA;
      10: if (rINT_STATE==eST_IDLE) rZZ_OFFSET <= iCSR_WRITE_DATA;
    endcase
  end
  if (iCSR_READ) begin
    case (iCSR_ADDRESS)
      0: oCSR_READ_DATA <= rMASK;
      1: oCSR_READ_DATA <= {rSTART, rSTRING_LEN, rBIT_COUNT};
      2: oCSR_READ_DATA <=  rTRESET;
      3: oCSR_READ_DATA <=  rT0H;
      4: oCSR_READ_DATA <=  rT1H;
      5: oCSR_READ_DATA <=  rTT;
      6: oCSR_READ_DATA <= {rZIGZAG, rZZSTATE,rLINE_LENGTH,rWRAP_COUNT};
      7: oCSR_READ_DATA <= rINT_STATE;
    endcase
  end

  // if we are in idle state and receive an update request...
  if ((rINT_STATE==eST_IDLE) && rSTART) begin
    // move to preload state, reset counters and read address and start reading
    rINT_STATE<= eST_PRELOAD;
    rCHAN_CNT<= 0;
    oDATA_READ <= 1;
    oDATA_ADDRESS <= rSTART_ADDRESS;
    // also reset the start flag to acknowledge we started updating
    rSTART<= 0;
    rHCNT <= 0;
    rAPA_SOF <= rAPA;
    rSTRING_LEN <= rREG_STRING_LEN;
  end

  // if we are reading and slave accepted burst request...
  if (oDATA_READ&&!iDATA_WAIT_REQUEST) begin
    // remove read request and increment read address by burst size
    oDATA_READ<= 0;
    if (!rZZSTATE)
      oDATA_ADDRESS <= oDATA_ADDRESS+{oDATA_BURST_COUNT,2'b0};
    else
      oDATA_ADDRESS <= oDATA_ADDRESS-{oDATA_BURST_COUNT,2'b0};
    rHCNT <= rHCNT+1;
    if (rZIGZAG&&rHCNT==rLINE_LENGTH) begin
      oDATA_ADDRESS <= oDATA_ADDRESS+rZZ_OFFSET;
    rHCNT <= 0;
    rZZSTATE<= !rZZSTATE;
   end
   if (rSTRING_LEN==rWRAP_COUNT)
    oDATA_ADDRESS <= rWRAP_ADDRESS;

  end

  // if we are receiving data we requested...
  if (iDATA_READ_DATA_VALID) begin
    // increment channel counter and store read data in temporary buffer
    rCHAN_CNT<= rCHAN_CNT+1;
    rTMP_DATA[rCHAN_CNT]<= iDATA_READ_DATA;
    // if this is the last channel...
    if (rCHAN_CNT==pCHANNELS-1) begin
      // reset channel counter
      rCHAN_CNT <= 0;
      // if state is preload...
      if (rINT_STATE==eST_PRELOAD) begin
        // load temporary buffer in shift buffer, move to shift state and reset counters
        rPIXEL_DATA<= rTMP_DATA;
        rINT_STATE<= eST_SHIFTING;
        rCOUNTER <= 0;
        rBIT_COUNTER<= 0;
        // since we just emptied temporary buffer let's issue another read request to fill it
        oDATA_READ <= 1;
      end
    end
  end

  // if we are in the shift state...
  if (rINT_STATE==eST_SHIFTING) begin
    // increment the timebase counter
    rCOUNTER<= rCOUNTER+1;
    // if counter has just been reset, set all non masked channels to 1
    // as NP protocol always has a pulse at beginning of a timeslot
    if (rCOUNTER==0) begin
      if (!rAPA) oDATA<= rMASK;
      else begin
        if (rAPA_SOF) begin
          oDATA <= 0;
        end
        else for (i=0;i<pCHANNELS;i++) begin
          oDATA[i]<=rMASK[i] ? rPIXEL_DATA[i][rBIT_COUNT] : 0;
        end
      end
      oCLK <= 0;
    end
    // if counter reached the T1H time...
    if (rCOUNTER==rT1H) begin
      // on all channels that are shifting out a 1 let's set output data to 0 to terminate pulse
      for (i=0;i<pCHANNELS;i++) begin
        if (!rAPA &&rPIXEL_DATA[i][rBIT_COUNT]) oDATA[i]<=0;
      end
      oCLK <= 1;
    end
    // if counter reached the T1H time...
    if (rCOUNTER==rT0H) begin
      // on all channels that are shifting out a 0 let's set output data to 0 to terminate pulse
      for (i=0;i<pCHANNELS;i++) begin
        if (!rAPA && !rPIXEL_DATA[i][rBIT_COUNT]) oDATA[i]<=0;
      end
    end
    // if counter reached end of timeslot..
    if (rCOUNTER==rTT) begin
      // reset counter and  increment bit counter
      rCOUNTER<=0;
      rBIT_COUNTER<=rBIT_COUNTER+1;

      // if this was the last bit of the word...
      if (rBIT_COUNTER==rBIT_COUNT) begin
        // reset bit counter
        rBIT_COUNTER<= 0;
        rAPA_SOF <= 0;
        // if this was te last pixel of the string...
        if (rSTRING_LEN==0) begin
          // move to reset state that updates pixels and prepares for next data
          rINT_STATE<= eST_RESETTING;
          rCOUNTER <= 0;
          oDATA <=0;
          rSTRING_LEN <= (rREG_STRING_LEN >64) ? ((rREG_STRING_LEN>>1) +1): 32;
        end
        else begin
          // since this wasn't the last pixel let's decrement string len count,
          // issue a burst request and update pixel data with temporary buffer
          if (!rAPA_SOF) rSTRING_LEN<= rSTRING_LEN-1;
          if (!rAPA_SOF)
            oDATA_READ <= 1;
          rAPA_SOF <= 0;
          if (!rAPA_SOF) begin
            if (!rAPA)
              rPIXEL_DATA<= rTMP_DATA;
            else
              rPIXEL_DATA<= rTMP_DATA|{pCHANNELS{32'he0000000}};
          end
        end
      end
      else if (!rAPA_SOF) begin
        // this wasn't the last bit of the word so we need to shift buffer to
        // prepare for next bit
        for (i=0;i<pCHANNELS;i++) begin
          rPIXEL_DATA[i] <= rPIXEL_DATA[i]<<1;
        end
      end
    end
  end
  // if we are in the reset state...
  if (rINT_STATE==eST_RESETTING) begin
    if (!rAPA) begin
      // increment the counter until we reach Treset...
      rCOUNTER <= rCOUNTER+1;
      if (rCOUNTER==rTRESET) begin
        // ...then move to idle state and raise interrupt
        rCOUNTER <= 0;
        rINT_STATE <= eST_IDLE;
        oCLK <= 0;
        oIRQ<= 1;
      end
    end else begin
      oDATA <= rMASK;
      rCOUNTER <= rCOUNTER+1;
      if (rCOUNTER==0) begin
        oCLK <= 0;
      end
      if (rCOUNTER==rT1H) begin
        // on all channels that are shifting out a 1 let's set output data to 0 to terminate pulse
        oCLK <= 1;
      end
      if (rCOUNTER==rTT) begin
        rCOUNTER <= 0;
        rSTRING_LEN <= rSTRING_LEN-1;
        if (rSTRING_LEN==0) begin
          rINT_STATE <= eST_IDLE;
          oCLK <= 0;
          oIRQ <= 1;
        end
      end
    end
  end
end


endmodule

