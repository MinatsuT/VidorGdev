//
// VidorGdev example
// Author: minatsu
//
#include "Blaster.h"

#include "VidorGdev.h"
#include "vec2.h"
#include <avr/dtostrf.h>

#include "map1.h"          // 200x200 map
#include "mapchip_light.h" // 9 BG chrs

// The following Arduino pins are internally used for communications
// between SAMD and FPGA , don't connect any external devices to them.
//  8 SPI MOSI for AvalonMM
//  9 SPI SCK for AvalonMM
// 10 SPI MISO for AvalonMM
// 11 I2C SDA for NINA
// 12 I2C ACL for NINA
// 20(A5) reset of FPGA
// 21(A6) SPI SS for AvalonMM

// NINA's UART and reset pins are exposed to following Arduino pins:
//  6 IO0 of NINA
//  7 EN of NINA
// 13 RX of NINA
// 14 TX of NINA

// Variables
uint32_t count = 0;

static float dir = 0;
static float height = 0;
static float v = 0;
static float a = 0.1;
static float brk = 0.95;
vec2f p{1024, 1024};
static int frames;
static unsigned long us, next_us, laps;

// ==================================================
// Setup
// ==================================================
void setup() {
  USBBlaster.setOutEpSize(60);
  USBBlaster.begin(1);
  Gdev.begin(1);

  Serial.begin(9600);
  // while (!Serial) {
  //   USBBlaster.loop();
  // };

  // Live indicators
  pinMode(0, INPUT);  // Drive via FPGA
  pinMode(1, OUTPUT); // Drive by SAMD

  // Show some information
  Serial.print("PCG_ADDR/2=");
  Serial.println(cPCG_ADDR, HEX);
  Serial.print("SCR_ADDR/2=");
  Serial.println(cBG_SCR_ADDR, HEX);
}

// ==================================================
// Loop
// ==================================================
static uint16_t mapBuf[200];
void loop() {
  int8_t resetFlag = 0;

  // Wait until fpga comes up
  do {
    Serial.println("Waiting for FPGA comes up ...");
    blasterWait(1000);
    if (resetFlag = serialCheck()) {
      break;
    }
  } while (AvalonMM.read(0, 0x00000010) == 0xffff);
  Serial.println("FPGA is ready.");

  // Init PIO
  AvalonMM.write(0, PIO_DIR, PIO_DIR_OUT);

  // Set BG view
  Serial.println("Set initial BG view.");
  bgset(2048, 2048, 320 / 2, 240 / 2, 0, 1 / 14.5);

  // Set PCG
  Serial.println("Transfer PCG.");
  for (int i = 0; i < 16 * 16 * 9; i++) {
    AvalonMM.write16(0, PCG + i * 2, mapchip_light[i]);
  }

  // Set BG
  Serial.println("Transfer BG.");
  for (int y = 0; y < 200; y++) {
    for (int x = 0; x < 200; x++) {
      mapBuf[x] = map1[y * 200 + x];
    }
    uint32_t addr = BG0 + ((y + 26) * 256 + 26) * 2;
    AvalonMM.write16n(0, addr, mapBuf, 200);
  }

  Serial.println("Start loop.");
  frames = 0;
  next_us = micros() + 1000000;
  while (!resetFlag) {
    USBBlaster.loop();

    // Check whether FPGA is alive.
    if (AvalonMM.read(0, count) == 0xffff) { // 0xffff means AvalonMM call is timed out.
      Serial.println("Avalon read failed, exit loop");
      break;
    }

    // Check and handle inputs from serial console.
    if (resetFlag = serialCheck()) {
      break;
    }

    if (!(count % 1)) {
      uint8_t blink = (count / 1) % 2;
      AvalonMM.write(0, PIO_IO, blink);
      digitalWrite(1, !blink);
    }

    // Update screen
    update();

    count++;

    frames++;
    if ((us = micros()) >= next_us) {
      next_us = us + 1000000;
      Serial.print(frames);
      Serial.println("fps");
      frames = 0;
    }
    // blasterWait(1000 / 60); // About 1/60sec;
  }

  softReset();
  resetFlag = 0;
  count = 0;
}

// ==================================================
// Update screen
// ==================================================
static uint16_t lastBtn = 0;
void update() {
  uint16_t btn = getBtn();
  uint16_t pressed = (~lastBtn) & btn;
  if (btn != lastBtn) {
    char buf[17];
    for (int i = 0; i < 16; i++) {
      buf[i] = (btn & (1 << (15 - i))) ? '1' : '0';
    }
    buf[16] = 0x00;
    Serial.print("btn=");
    Serial.print(buf);

    for (int i = 0; i < 16; i++) {
      buf[i] = (pressed & (1 << (15 - i))) ? '1' : '0';
    }
    Serial.print(" pressed=");
    Serial.println(buf);
  }
  lastBtn = btn;

  // reset
  if (btn & BTN_HOME) {
    p.set(1024, 1024);
    dir = 0;
    height = 0;
  }

  // Direction
  if (btn & BTN_B) {
    dir += !!(btn & BTN_DOWN) - !!(btn & BTN_UP);
  }

  /// Slide
  if (!(btn & BTN_B)) {
    vec2f s(1, 0);
    s.rotate(dir);
    s *= (double)(!!(btn & BTN_DOWN) - !!(btn & BTN_UP));
    p += s;
  }

  // Forward & back
  vec2f front(0, -1);
  front.rotate(dir);
  // Print info
  if (pressed & BTN_A) {
    Serial.print("pos=");
    putVec2f(p);
    Serial.print(" dir=");
    putF(dir);
    Serial.println("");
  }

  double spd = (!!((btn & BTN_RIGHT) || (btn & BTN_2)) - !!((btn & BTN_LEFT) || (btn & BTN_1)));
  front *= spd;
  p += front;

  // height
  height += 2 * (!!(btn & BTN_MINUS) - !!(btn & BTN_PLUS));
  height = max(-300, height);

  float mag = 320 / (320 + height);

  bgset(p.x, p.y, 320 / 2, 240 / 2, rad(-dir), mag);
}

float rad(float deg) { return deg * PI / 180.0; }

static uint32_t regs[6];
void bgset(float mapx, float mapy, float hx, float hy, float th, float mag) {
  if (mag == 0) {
    return;
  }

  float ux = cos(-th) / mag;
  float uy = sin(-th) / mag;
  float vx = -uy;
  float vy = ux;

  float ox = mapx - hx * ux - hy * vx;
  float oy = mapy - hx * uy - hy * vy;

#if 0
  AvalonMM.write32(0, BG_REG_BASE + BG_REG_OX, fp2q(ox));
  AvalonMM.write32(0, BG_REG_BASE + BG_REG_OY, fp2q(oy));
  AvalonMM.write32(0, BG_REG_BASE + BG_REG_UX, fp2q(ux));
  AvalonMM.write32(0, BG_REG_BASE + BG_REG_UY, fp2q(uy));
  AvalonMM.write32(0, BG_REG_BASE + BG_REG_VX, fp2q(vx));
  AvalonMM.write32(0, BG_REG_BASE + BG_REG_VY, fp2q(vy));
#endif
  regs[0] = fp2q(ox);
  regs[1] = fp2q(oy);
  regs[2] = fp2q(ux);
  regs[3] = fp2q(uy);
  regs[4] = fp2q(vx);
  regs[5] = fp2q(vy);
  AvalonMM.write32n(0, BG_REG_BASE + BG_REG_OX, regs, 6);
}

int32_t fp2q(float f) {
  int32_t q = f * (1 << 12);
  return q;
}

// Get WiiRemote's buttons
uint16_t getBtn() {
  uint16_t ret = 0;
  byte buf[3] = {0};

  for (int i = 0; i < 3; i++) {
    Wire.requestFrom(0x28, 1);
    while (Wire.available()) {
      if ((buf[i] = Wire.read()) == 0xff) {
        // Break whenever stop byte (0xff) appeared.
        break;
      }
    }
  }

  if (buf[2] == 0xff) {
    ret = buf[0] | buf[1] << 8;
  }

  return ret;
}

// ==================================================
// Serial console input handling
// ==================================================
uint8_t serialCheck() {
  uint8_t reset = 0;
  while (Serial.available() > 0) {
    reset = 1;
    Serial.read();
  }
  return reset;
}

void softReset() {
  Serial.println("soft reset");
  digitalWrite(PIN_RESET, 1);
  blasterWait(10);
  digitalWrite(PIN_RESET, 0);
}

// ==================================================
// Wait with calling USBBlaster
// ==================================================
void blasterWait(int n) {
  for (int i = 0; i < n; i++) {
    USBBlaster.loop();
    delay(1);
  }
}

// ==================================================
// print utilities
// ==================================================
void putF(float f) {
  char buf[9];
  dtostrf(f, 8, 1, buf);
  Serial.print(buf);
}

void putVec2f(vec2f v) {
  char bufX[9], bufY[9];
  char buf[20];
  dtostrf(v.x, 8, 1, bufX);
  dtostrf(v.y, 8, 1, bufY);
  sprintf(buf, "%s,%s", bufX, bufY);
  Serial.print(buf);
}
