/* ========================================
 *
 * AvalonMM SPI bridge API
 *
 * Copyright Minatsu, 2018
 * All Rights Reserved
 * UNPUBLISHED, LICENSED SOFTWARE.
 *
 * ========================================
 */
#include "AvalonMM.h"
#include "Arduino.h"
#include "Blaster.h"
#include "dump.h"
#include <SPI.h>

AvalonMMClass AvalonMM;

/**************************************
 * Packet definition
 *************************************/
#define TRANSACTION_WRITE 0x00
#define TRANSACTION_WRITE_INC_ADDR 0x04
#define TRANSACTION_READ 0x10
#define TRANSACTION_READ_INC_ADDR 0x14
#define TRANSACTION_NOP 0x7f

#define HEADER_SIZE 8
#define RESPONSE_LEN 4

/**************************************
 * Special bytes
 *************************************/
#define SOP 0x7a
#define EOP 0x7b
#define CH_INDICATOR 0x7c
#define ESCAPE 0x7d

#define SPI_IDLE 0x4a
#define SPI_ESC 0x4d

/**************************************
 * For debug
 *************************************/
/* Debug Print */
char dbuf[256];
#define DP(...)                                                                \
  {                                                                            \
    sprintf(dbuf, __VA_ARGS__);                                                \
    Serial.write(dbuf);                                                        \
  }

void AvalonMMClass::begin(int SS) {
  SS_pin = SS;

  SPI.begin();
  SPI.setBitOrder(MSBFIRST);
  SPI.setClockDivider(2); // 48Mhz/2=24MHz
  SPI.setDataMode(SPI_MODE1);
  pinMode(SS_pin, OUTPUT);
  digitalWrite(SS_pin, HIGH);

  rstat = waitSop;
  head = 0;
  tail = 0;
}

void AvalonMMClass::memoryDump(uint32_t base, uint32_t size) {
  dumpInit();
  enum receiveState rstat = waitSop;
  uint32_t addr = base;
  for (; addr < base + size; addr++) {
    dumpPut(addr, read(0, addr));

    if ((addr % 16) == 15) {
      DP("%s\n", dumpSPrint());
      dumpInit();
    }
  }

  if (((addr + 16 - 1) % 16) != 15) {
    DP("%s\n", dumpSPrint());
    dumpInit();
  }
  DP("Finished.\n");
}

// ================================================================================
// AvalonMM API
// ================================================================================

// write 8bit data
// --------------------------------------------------------------------------------
uint16_t AvalonMMClass::write(uint8_t ch, uint32_t addr, uint8_t dat) {
  // head = tail = 0; // clear FIFO
  uint8_t buf[HEADER_SIZE + 1];
  uint16_t size = 1;
  // buf[0] = TRANSACTION_WRITE;
  buf[0] = TRANSACTION_WRITE_INC_ADDR;
  buf[1] = 0;
  buf[2] = (size >> (8 * 1)) & 0xff; // size
  buf[3] = (size >> (8 * 0)) & 0xff; // size
  buf[4] = (addr >> (8 * 3)) & 0xff;
  buf[5] = (addr >> (8 * 2)) & 0xff;
  buf[6] = (addr >> (8 * 1)) & 0xff;
  buf[7] = (addr >> (8 * 0)) & 0xff;

  buf[8] = dat;

  writePacket(ch, buf, HEADER_SIZE + 1);
  // read 4 bytes response
  for (int i = 0; i < 4; i++) {
    buf[i] = readPacket();
  }
  return buf[2] << 8 | buf[3]; // size
}

// write 16bit data
// --------------------------------------------------------------------------------
uint16_t AvalonMMClass::write16(uint8_t ch, uint32_t addr, uint16_t dat) {
  // head = tail = 0; // clear FIFO
  uint8_t buf[HEADER_SIZE + 2];
  uint16_t size = 2;
  // buf[0] = TRANSACTION_WRITE;
  buf[0] = TRANSACTION_WRITE_INC_ADDR;
  buf[1] = 0;
  buf[2] = (size >> (8 * 1)) & 0xff; // size
  buf[3] = (size >> (8 * 0)) & 0xff; // size
  buf[4] = (addr >> (8 * 3)) & 0xff;
  buf[5] = (addr >> (8 * 2)) & 0xff;
  buf[6] = (addr >> (8 * 1)) & 0xff;
  buf[7] = (addr >> (8 * 0)) & 0xff;

  buf[8] = (dat >> (8 * 0)) & 0xff;
  buf[9] = (dat >> (8 * 1)) & 0xff;

  writePacket(ch, buf, HEADER_SIZE + 2);
  // read 4 bytes response
  for (int i = 0; i < 4; i++) {
    buf[i] = readPacket();
  }
  return buf[2] << 8 | buf[3]; // size
}

// write 32bit data
// --------------------------------------------------------------------------------
uint16_t AvalonMMClass::write32(uint8_t ch, uint32_t addr, uint32_t dat) {
  // head = tail = 0; // clear FIFO
  uint8_t buf[HEADER_SIZE + 4];
  uint16_t size = 4;
  // buf[0] = TRANSACTION_WRITE;
  buf[0] = TRANSACTION_WRITE_INC_ADDR;
  buf[1] = 0;
  buf[2] = (size >> (8 * 1)) & 0xff; // size
  buf[3] = (size >> (8 * 0)) & 0xff; // size
  buf[4] = (addr >> (8 * 3)) & 0xff;
  buf[5] = (addr >> (8 * 2)) & 0xff;
  buf[6] = (addr >> (8 * 1)) & 0xff;
  buf[7] = (addr >> (8 * 0)) & 0xff;

  buf[8] = (dat >> (8 * 0)) & 0xff;
  buf[9] = (dat >> (8 * 1)) & 0xff;
  buf[10] = (dat >> (8 * 2)) & 0xff;
  buf[11] = (dat >> (8 * 3)) & 0xff;

  writePacket(ch, buf, HEADER_SIZE + 4);
  // read 4 bytes response
  for (int i = 0; i < 4; i++) {
    buf[i] = readPacket();
  }
  return buf[2] << 8 | buf[3]; // size
}

// read 8bit data
// --------------------------------------------------------------------------------
uint16_t AvalonMMClass::read(uint8_t ch, uint32_t addr) {
  // head = tail = 0; // clear FIFO
  uint8_t buf[HEADER_SIZE];
  uint16_t size = 1;
  // buf[0] = TRANSACTION_READ;
  buf[0] = TRANSACTION_READ_INC_ADDR;
  buf[1] = 0;
  buf[2] = (size >> (8 * 1)) & 0xff; // size
  buf[3] = (size >> (8 * 0)) & 0xff; // size
  buf[4] = (addr >> (8 * 3)) & 0xff;
  buf[5] = (addr >> (8 * 2)) & 0xff;
  buf[6] = (addr >> (8 * 1)) & 0xff;
  buf[7] = (addr >> (8 * 0)) & 0xff;

  writePacket(ch, buf, HEADER_SIZE);
  return readPacket();
}

// ================================================================================
// packet manipulation methods
// ================================================================================
void AvalonMMClass::writePacket(uint8_t ch, uint8_t *p, uint16_t len) {
  writeByte(SOP);
  writeByte(CH_INDICATOR);
  writeByte(ch);
  for (uint16_t i = 0; i < len - 1; i++) {
    // Send EOP before last data bytes
    writeData(*p++);
  }
  writeByte(EOP);
  writeData(*p++);
}

uint16_t AvalonMMClass::readPacket() {
  while (1) {
    uint8_t r = readData();
    if (r == SPI_IDLE) {
      // timeout
      return 0xffff;
    }

    if (rstat == waitSop) {
      // wait for Start of Packet
      if (r == SOP) {
        rstat = afterSop;
      }
    } else {
      if (r == EOP) {
        // if End of Packet is received, next byte is final data.
        rstat = waitSop;
        return readData();
      }
      return r;
    }
  }
  return 0;
}

// ================================================================================
// byte manipulation methods
// ================================================================================

// Send routines
// --------------------------------------------------------------------------------
void AvalonMMClass::writeData(uint8_t b) {
  if (b == SOP || b == EOP || b == CH_INDICATOR || b == ESCAPE) {
    writeByte(ESCAPE);
    writeByte(b ^ 0x20);
  } else {
    writeByte(b);
  }
}

void AvalonMMClass::writeByte(uint8_t b) {
  if (b == SPI_IDLE || b == SPI_ESC) {
    writeSPI(SPI_ESC);
    writeSPI(b ^ 0x20);
  } else {
    writeSPI(b);
  }
}

// Receive routines
// --------------------------------------------------------------------------------
uint8_t AvalonMMClass::readData() {
  uint8_t d = readByte();
  return (d == ESCAPE) ? readByte() ^ 0x20 : d;
}

uint8_t AvalonMMClass::readByte() {
  uint8_t d = readSPI();
  return (d == SPI_ESC) ? readSPI() ^ 0x20 : d;
}

// ================================================================================
// SPI (Physical) input/output methods
// ================================================================================
void AvalonMMClass::writeSPI(uint8_t b) {
  uint8_t d;
  digitalWrite(SS_pin, LOW);
  d = SPI.transfer(b);

  printSendByte(b);
  printReceiveByte(d);

  digitalWrite(SS_pin, HIGH);
  if (d != SPI_IDLE) {
    // push into FIFO
    fifo[head++] = d;
    head %= FIFO_LEN;
  }
}

uint8_t AvalonMMClass::readSPI() {
  uint8_t d;
  uint32_t timeout = 5000;

  // data in the FIFO
  if (FIFO_BYTES != 0) {
    d = fifo[tail++];
    tail %= FIFO_LEN;
    return d;
  }

  // FIFO is empty
  d = SPI_IDLE;
  while (d == SPI_IDLE && timeout--) {
    USBBlaster.loop();

    digitalWrite(SS_pin, LOW);
    d = SPI.transfer(SPI_IDLE);
    digitalWrite(SS_pin, HIGH);
    // if (d == SPI_IDLE) {
    //   blasterWait(10);
    // }
  }

  printReceiveByte(d);

  return d;
}

// ================================================================================
// USB Blaster
// ================================================================================
void AvalonMMClass::blasterWait(int n) {
  int i;
  for (i = 0; i < n; i += 1) {
    USBBlaster.loop();
    delay(1);
  }
}

// ================================================================================
// Debug facilities
// ================================================================================
void AvalonMMClass::printSendByte(uint8_t b) {
  if (spi_debug) {
    if (b == SPI_IDLE) {
      Serial.print("(__)");
    } else {
      Serial.print("(");
      printHex8(b);
      Serial.print(")");
    }
  }
}

void AvalonMMClass::printReceiveByte(uint8_t b) {
  if (spi_debug) {
    if (b == SPI_IDLE) {
      Serial.print("[__]");
    } else {
      Serial.print("[");
      printHex8(b);
      Serial.print("]");
    }
  }
}

void AvalonMMClass::printHex8(uint8_t b) {
  if (b <= 0xf) {
    Serial.print(0);
  }
  Serial.print(b, HEX);
}

