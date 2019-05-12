//
// VidorGdev
// Author: minatsu
//
// The following Arduino pins are internally used for communications
// between SAMD and FPGA , don't connect any external devices to them.
//  8 SPI MOSI for AvalonMM
//  9 SPI SCK for AvalonMM
// 10 SPI MISO for AvalonMM
// 11 I2C SDA for NINA
// 12 I2C ACL for NINA
// 20(A5) reset of FPGA
// 21(A6) SPI SS for AvalonMM
//
// NINA's UART and reset pins are exposed to following Arduino pins:
//  6 IO0 of NINA
//  7 EN of NINA
// 13 RX of NINA
// 14 TX of NINA
//
#ifndef __VIDOR_GDEV_H__
#define __VIDOR_GDEV_H__

#include "AvalonMM.h"
#include "Wire.h"

// Wii Remote buttons
#define BTN_2 0x0001
#define BTN_1 0x0002
#define BTN_B 0x0004
#define BTN_A 0x0008
#define BTN_MINUS 0x0010
#define BTN_HOME 0x0080
#define BTN_LEFT 0x0100
#define BTN_RIGHT 0x0200
#define BTN_DOWN 0x0400
#define BTN_UP 0x0800
#define BTN_PLUS 0x1000

// PIO registers
#define PIO_BASE (0x00800000)
#define PIO_IO (0x00800000 + 0)
#define PIO_DIR (0x00800000 + 4)
#define PIO_DIR_IN 0
#define PIO_DIR_OUT 1

// BG registers
#define BG_REG_BASE 0x800400
#define BG_REG_OX 0
#define BG_REG_OY 4
#define BG_REG_UX 8
#define BG_REG_UY 12
#define BG_REG_VX 16
#define BG_REG_VY 20

// VRAM addresses
#define cW 320
#define cH 240

#define cNUM_GRP 2
#define cGRP_W cW
#define cGRP_H cH
#define cGRP_SIZE (cGRP_W * cGRP_H)
#define cGRP_WORDS (1 * cGRP_SIZE)

#define cCHR_W 16
#define cCHR_H 16
#define cCHR_SIZE (cCHR_W * cCHR_H)
#define cCHR_WORDS (1 * cCHR_SIZE)

#define cPCG_W (16)
#define cPCG_H (16)
#define cPCG_SIZE (cPCG_W * cPCG_H)
#define cPCG_WORDS (cCHR_WORDS * cPCG_SIZE)

#define cBG_W (256)
#define cBG_H (256)
#define cBG_SIZE (cBG_W * cBG_H)
#define cBG_WORDS (1 * cBG_SIZE)

// WORD addresses
#define cGRP_ADDR (0)
#define cBG_SCR_ADDR (cGRP_ADDR + (cGRP_WORDS * cNUM_GRP))
#define cPCG_ADDR (0x480000)

// BYTE addresses
#define GRP (cGRP_ADDR * 2)
#define BG0 (cBG_SCR_ADDR * 2)
#define PCG (cPCG_ADDR * 2)

// Screen size
#define SW (cW)
#define SH (cH)

// Pin definitions
#define PIN_RESET (A5) // TODO: It should be 31(PA18: FPGA MB INT)
#define PIN_SS (A6)

__attribute__((weak)) void enableFpgaClock() {}
__attribute__((weak)) void disableFpgaClock() {}

class VidorGdev {
public:
  void begin(int jtag_trigger=1);
};

extern VidorGdev Gdev;

#endif
