//
// VidorGdev
// Author: minatsu
//
#include "VidorGdev.h"
#include "jtag.h"

// Defines for fpga_bitstream_signature section
#define no_data                                                                \
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,      \
      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,  \
      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,  \
      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00

#define NO_BOOTLOADER no_data
#define NO_APP no_data
#define NO_USER_DATA no_data

__attribute__((used, section(".fpga_bitstream_signature")))
const unsigned char signatures[4096] = {
#include "signature.h"
};
__attribute__((used, section(".fpga_bitstream")))
const unsigned char bitstream[] = {
#include "app.ttf"
};

VidorGdev Gdev;

void VidorGdev::begin(int jtag_trigger) {
  enableFpgaClock();

  // Initialize AvalonMM
  pinMode(PIN_RESET, OUTPUT); // RESET
  pinMode(PIN_SS, OUTPUT);    // SS
  AvalonMM.begin(PIN_SS);

  // Initialize I2C bridge to NINA
  //                    [SAMD] PIN [FPGA] [esp32(NINA-W102)]
  pinMode(6, INPUT); // PA20 | D6 |--> bMKR_D[6] --> IO0(27:SYS_BOOT/GPIO_27)
  pinMode(7, INPUT); // PA21 | D7 |--> bMKR_D[7] --> EN(19:RESET_N)
  pinMode(13,
          INPUT); // PB23(RX)| D13 |--> bMKR_D[13] --> IO3(23:UART_RXD/GPIO_23)
  pinMode(14,
          INPUT); // PB22(TX)| D14 |<-- bMKR_D[14] <-- IO1(22:UART_TXD/GPIO_22)
  Wire.begin();

  if (jtag_trigger) {
    // Initialize JTAG interface
    jtagInit();

    // Start user bitstream (app.ttf) configuration
    mbPinSet();
    uint32_t ptr[1];
    ptr[0] = 0 | 3;
    mbEveSend(ptr, 1);
  }
}
