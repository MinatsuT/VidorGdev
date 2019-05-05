#ifndef __ESP32_WIIREMOTE_H__
#define __ESP32_WIIREMOTE_H__

#include <inttypes.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

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

uint8_t wii_isReady(void);
uint16_t wii_getButton(void);
uint16_t wii_getLed(void);
void wii_setLed(uint16_t led);

#endif /* __ESP32_WIIREMOTE_H__ */