//
// VidorGdev
// Author: minatsu
//
#ifndef __VIDOR_GDEV_H__
#define __VIDOR_GDEV_H__

#include "AvalonMM.h"
#include "WiiRemote.h"
#include "Wire.h"

// Defines for fpga_bitstream_signature section
#define no_data		0xFF, 0xFF, 0xFF, 0xFF, \
					0xFF, 0xFF, 0xFF, 0xFF, \
					0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, \
					0xFF, 0xFF, 0xFF, 0xFF, \
					0x00, 0x00, 0x00, 0x00  \

#define NO_BOOTLOADER		no_data
#define NO_APP				no_data
#define NO_USER_DATA		no_data

__attribute__((weak)) void enableFpgaClock() {}
__attribute__((weak)) void disableFpgaClock() {}


#define PIO_BASE (0x00800000)
#define PIO_IO (0x00800000 + 0)
#define PIO_DIR (0x00800000 + 4)
#define PIO_DIR_IN 0
#define PIO_DIR_OUT 1

#define BG_REG_BASE 0x800400
#define BG_REG_OX 0
#define BG_REG_OY 4
#define BG_REG_UX 8
#define BG_REG_UY 12
#define BG_REG_VX 16
#define BG_REG_VY 20

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
#define PIN_RESET (A5)
#define PIN_SS (A6)


class VidorGdev {
public:
  void begin();
};

extern VidorGdev Gdev;

#endif
