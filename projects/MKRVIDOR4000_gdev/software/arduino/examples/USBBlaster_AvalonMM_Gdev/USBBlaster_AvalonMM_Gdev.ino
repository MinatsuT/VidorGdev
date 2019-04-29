#include "AvalonMM.h"
#include "Blaster.h"
//#include "VidorJTAG.h"

// 9 chrs
#include "mapchip_light.h"

// 200x200 map
#include "map1.h"

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

#define cGRP_ADDR (0)
// #define cPCG_ADDR (cGRP_ADDR + (cGRP_WORDS * cNUM_GRP))
#define cPCG_ADDR (0x900000 / 2)
// #define cBG_SCR_ADDR (cPCG_ADDR + cPCG_WORDS)
#define cBG_SCR_ADDR (cGRP_ADDR + (cGRP_WORDS * cNUM_GRP))

#define PCG (cPCG_ADDR * 2)
#define BG0 (cBG_SCR_ADDR * 2)

extern void enableFpgaClock();

void setup() {
  USBBlaster.setOutEpSize(60);
  USBBlaster.begin(1);
  enableFpgaClock();

  Serial.begin(9600);
  while (!Serial) {
    USBBlaster.loop();
  };

  pinMode(7, OUTPUT); // SS   P12[5]
  pinMode(8, OUTPUT); // MOSI P12[2]
  pinMode(9, OUTPUT); // SCK  P12[4]
  pinMode(10, INPUT); // MISO P12[3]

  pinMode(6, OUTPUT); // D6 PA20

  AvalonMM.begin();
}

uint32_t reset_count = 300;

void loop() {
  // wait until fpga comes up
  // AvalonMM.spi_debug = 1;
  do {
    Serial.println("waits FPGA");
    blasterWait(1000);
    serialCheck();
  } while (AvalonMM.read(0, 0x00000010) == 0xffff);
  // AvalonMM.spi_debug = 0;
  Serial.println("FPGA comes up");

  AvalonMM.write(0, 0x00000000, 0x00);
  AvalonMM.memoryDump(0x00000000, 0x100);
  AvalonMM.write(0, 0x00000000, 0x12);
  AvalonMM.memoryDump(0x00000000, 0x100);

  bgset(2048, 2048, 320 / 2, 240 / 2, 0, 1 / 14.5);

  AvalonMM.write(0, PIO_DIR, PIO_DIR_OUT);
  for (int i = 0; i < 16 * 16 * 9; i++) {
    AvalonMM.write16(0, PCG + i * 2, mapchip_light[i]);
    USBBlaster.loop();
  }
  // for (int y = 0; y < 16; y++) {
  //   for (int x = 0; x < 16; x++) {
  //     uint32_t addr = PCG + (y * 16 + x) * 2;
  //     AvalonMM.write16(0, addr, 0x8000 | (x + y) + ((x + y) % 2) * 0b000000011100000);
  //     USBBlaster.loop();
  //   }
  // }
  // AvalonMM.write16(0, PCG, 0x8000 | 0b111110000000000);

  // for (int y = 0; y < 256; y++) {
  //   for (int x = 0; x < 256; x++) {
  //     uint32_t addr = BG0 + (y * 256 + x) * 2;
  //     AvalonMM.write16(0, addr, 0);
  //     USBBlaster.loop();
  //   }
  // }
  for (int y = 0; y < 200; y++) {
    for (int x = 0; x < 200; x++) {
      uint32_t addr = BG0 + ((y + 26) * 256 + (x + 26)) * 2;
      AvalonMM.write16(0, addr, map1[y * 200 + x]);
      USBBlaster.loop();
    }
  }
  // for (int y = 0; y < 16; y++) {
  //   for (int x = 0; x < 16; x++) {
  //     uint32_t addr = BG0 + (y * 256 + x) * 2;
  //     AvalonMM.write16(0, addr, 0);
  //     USBBlaster.loop();
  //   }
  // }

  Serial.print("PCG_ADDR/2=");
  Serial.println(cPCG_ADDR, HEX);
  Serial.print("SCR_ADDR/2=");
  Serial.println(cBG_SCR_ADDR, HEX);

  // AvalonMM.write32(0, BG_REG_BASE + BG_REG_OX, fp2q(1000.5));
  // AvalonMM.write32(0, BG_REG_BASE + BG_REG_OY, fp2q(1000.5));

  // AvalonMM.write32(0, BG_REG_BASE + BG_REG_UX, fp2q(1.0/8.0));
  // AvalonMM.write32(0, BG_REG_BASE + BG_REG_UY, fp2q(0));
  // AvalonMM.write32(0, BG_REG_BASE + BG_REG_VX, fp2q(0));
  // AvalonMM.write32(0, BG_REG_BASE + BG_REG_VY, fp2q(1.0/8.0));

  while (1) {
    // if (AvalonMM.read(0, 0x00000010) == 0xffff) {
    // AvalonMM.spi_debug = 1;
    uint16_t ret = AvalonMM.read(0, reset_count);
    // AvalonMM.spi_debug = 0;
    if (ret == 0xffff) {
      Serial.println("Avalon read failed, exit loop");
      break;
    }
    USBBlaster.loop();
    serialCheck();

    // Serial.print("PIO 1=");
    // Serial.print(AvalonMM.write(0, PIO_IO, 1));
    AvalonMM.write(0, PIO_IO, 1);
    blasterWait(20);
    // Serial.print(" ");
    // Serial.print("PIO 0=");
    // Serial.print(AvalonMM.write(0, PIO_IO, 0));
    AvalonMM.write(0, PIO_IO, 0);
    blasterWait(20);

    // Serial.print(" count=");
    // Serial.print(reset_count);
    // Serial.print(" t=");

    Serial.println(reset_count);
    // writeREG(reset_count);
    // writeREG(365);

    setDisp(reset_count);

    // blasterWait(100);

    // if (reset_count >= 50) {
    //   reset_count = 0;
    //   break;
    // }

    reset_count++;
  }

  softReset();
  reset_count = 0;
}

void blasterWait(int n) {
  int i;
  for (i = 0; i < n; i += 10) {
    USBBlaster.loop();
    delay(10);
  }
}

static float deg = 0;
static float mag = 0;
void setDisp(int32_t d) {
  deg += 0.2;
  // if (deg > 360) {
  //   deg -= 360;
  // }
  float th = deg * PI / 180.0;

  mag += 0.3;
  if (mag > 200) {
    mag -= 200;
  }

  float t = 100.0 - abs(100.0 - mag);
  // float mag = powf(2.0, - (t / 100.0) * 5.0);
  float z = 320 * 4 * (t / 100.0) - 160.0;
  float mag = 320.0 / (320.0 + z);

  float px = 2048 + cos(th * 0.7) * 16 * 50;
  float py = 2048 + sin(th) * 16 * 50;
  // bgset(2048, 2048, 320 / 2, 240 / 2, th, mag);
  bgset(px, py, 320 / 2, 240 / 2, th + PI, mag);
}

void bgset(float mapx, float mapy, float hx, float hy, float th, float mag) {
  if (mag == 0) {
    return;
  }

  float ux = cos(th) / mag;
  float uy = sin(th) / mag;
  float vx = -uy;
  float vy = ux;

  float ox = mapx - hx * ux - hy * vx;
  float oy = mapy - hx * uy - hy * vy;

  AvalonMM.write32(0, BG_REG_BASE + BG_REG_OX, fp2q(ox));
  AvalonMM.write32(0, BG_REG_BASE + BG_REG_OY, fp2q(oy));
  AvalonMM.write32(0, BG_REG_BASE + BG_REG_UX, fp2q(ux));
  AvalonMM.write32(0, BG_REG_BASE + BG_REG_UY, fp2q(uy));
  AvalonMM.write32(0, BG_REG_BASE + BG_REG_VX, fp2q(vx));
  AvalonMM.write32(0, BG_REG_BASE + BG_REG_VY, fp2q(vy));
}

int32_t fp2q(float f) {
  int32_t q = f * (1 << 12);
  return q;
}

void serialCheck() {
  uint8_t flag = 0;
  while (Serial.available() > 0) {
    flag = 1;
    Serial.read();
  }
  if (flag) {
    softReset();
  }
}

void softReset() {
  Serial.println("soft reset");
  digitalWrite(6, 1);
  blasterWait(10);
  digitalWrite(6, 0);
}