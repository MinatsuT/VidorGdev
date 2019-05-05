//
// VidorGdev
// Author: minatsu
//
#include "VidorGdev.h"
#include "jtag.h"

#if 1
__attribute__((used, section(".fpga_bitstream_signature")))
const unsigned char signatures[4096] = {
#include "signature.h"
};
__attribute__((used, section(".fpga_bitstream")))
const unsigned char bitstream[] = {
#include "app.ttf"
};

VidorGdev Gdev;

void VidorGdev::begin() {
  enableFpgaClock();

  // AvalonMM
  pinMode(PIN_RESET, OUTPUT); // RESET
  pinMode(PIN_SS, OUTPUT);    // SS
  AvalonMM.begin(PIN_SS);

  // NINA
  //                    [SAMD] PIN [FPGA] [esp32(NINA-W102)]
  pinMode(6, INPUT); // PA20 | D6 |--> bMKR_D[6] --> IO0(27:SYS_BOOT/GPIO_27)
  pinMode(7, INPUT); // PA21 | D7 |--> bMKR_D[7] --> EN(19:RESET_N)
  pinMode(13,
          INPUT); // PB23(RX)| D13 |--> bMKR_D[13] --> IO3(23:UART_RXD/GPIO_23)
  pinMode(14,
          INPUT); // PB22(TX)| D14 |<-- bMKR_D[14] <-- IO1(22:UART_TXD/GPIO_22)
  Wire.begin();

  // Initialize JTAG interface
  jtagInit();

  // Start user bitstream (app.ttf) configuration
  mbPinSet();
  uint32_t ptr[1];
  ptr[0] = 0 | 3;
  mbEveSend(ptr, 1);
}

#endif