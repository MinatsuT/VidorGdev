#pragma once

#include <ctype.h>
#include <stdio.h>

#define FIFO_LEN 16
#define FIFO_BYTES ((head + FIFO_LEN - tail) % FIFO_LEN)

class AvalonMMClass {
  public:
    int chipSelectPin = 7;
    void begin();
    void memoryDump(uint32_t base, uint32_t size);
    uint16_t read(uint8_t ch, uint32_t addr);
    uint16_t write(uint8_t ch, uint32_t addr, uint8_t dat);

  private:
    uint8_t fifo[FIFO_LEN];
    uint8_t head = 0;
    uint8_t tail = 0;

    enum receiveState { waitSop, afterSop } rstat = waitSop;

    void writePacket(uint8_t ch, uint8_t *p, uint16_t len);
    void writeData(uint8_t b);
    void writeByte(uint8_t b);
    void writeSPI(uint8_t b);
    uint16_t readPacket(void);
    uint8_t readData(void);
    uint8_t readByte(void);
    uint8_t readSPI(void);
};

extern AvalonMMClass AvalonMM;
