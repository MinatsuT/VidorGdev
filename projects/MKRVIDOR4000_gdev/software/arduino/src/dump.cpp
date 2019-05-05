#include "dump.h"

#define HEXBUFSIZE (3 * 16 + 1)
static char hexBuf[HEXBUFSIZE];

#define CHRBUFSIZE (16 + 1)
static char chrBuf[CHRBUFSIZE];

void dumpInit() {
  for (int i = 0; i < HEXBUFSIZE; i++) {
    hexBuf[i] = 0x00;
  }
  for (int i = 0; i < CHRBUFSIZE; i++) {
    chrBuf[i] = 0x00;
  }
}

static uint32_t lineAddr;

void dumpPut(uint32_t addr, uint8_t d) {
  lineAddr = addr;

  int idx = addr % 16;
  sprintf(&hexBuf[idx * 3], "%02X", d);

  chrBuf[idx] = isprint(d) ? d : '.';
}

#define BUFSIZE (11 + HEXBUFSIZE + CHRBUFSIZE)
static char buf[BUFSIZE];
char *dumpSPrint() {
  for (int i = 0; i < HEXBUFSIZE - 1; i++) {
    if (!hexBuf[i]) {
      hexBuf[i] = ' ';
    }
  }
  for (int i = 0; i < CHRBUFSIZE-1; i++) {
    if (!chrBuf[i]) {
      chrBuf[i] = ' ';
    }
  }

  lineAddr &= 0xfffffff0;
  uint16_t h16 = (lineAddr >> 16) & 0xffff;
  uint16_t l16 = (lineAddr >> 0) & 0xffff;
  sprintf(buf, "%04X_%04X: %s %s", h16, l16, hexBuf, chrBuf);
  buf[BUFSIZE - 1] = 0x00;

  return buf;
}
