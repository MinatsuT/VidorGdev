/*
 * Application main
 */
#include "esp32_wiiremote.h"

#include "esp_err.h"
#include "esp_log.h"
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/unistd.h>

#include "driver/gpio.h"
#include "driver/i2c.h"

static const char *TAG = "main_loop";

/***************************************************************************
 * Definitions & variables
 ***************************************************************************/
static uint8_t connected = 0;
uint32_t frameCount = 0;
uint16_t btn_data = 0;

#define LED_BLUE GPIO_NUM_25
#define LED_GREEN GPIO_NUM_26

/***************************************************************************
 * Prototypes
 ***************************************************************************/
void waitFrame(void);
static esp_err_t i2c_slave_init();
static void i2c_slave_task(void *pvParameter);

/***************************************************************************
 * Application setup (Called by btstack_main() in esp32_wiiremote.c)
 ***************************************************************************/
void setup() {
  esp_log_level_set("*", ESP_LOG_VERBOSE);

  gpio_pad_select_gpio(LED_BLUE);
  gpio_set_direction(LED_BLUE, GPIO_MODE_OUTPUT);
  gpio_pad_select_gpio(LED_GREEN);
  gpio_set_direction(LED_GREEN, GPIO_MODE_OUTPUT);

  if (i2c_slave_init() != ESP_OK) {
    ESP_LOGW(TAG, "I2C slave init failed.");
  } else {
    ESP_LOGW(TAG, "I2C slave init OK.");
  }
  xTaskCreate(i2c_slave_task, "i2c_slave_task", 4096, NULL, 10, NULL);

  ESP_LOGI(TAG, "Application setup OK");
}

/***************************************************************************
 *
 * Application loop (Called by btstack_main() in esp32_wiiremote.c)
 *
 * Once it returns, called again with new button states
 *
 ***************************************************************************/
static uint8_t countEnable = 1;
static uint8_t cnt = 0;
static uint8_t led;
void loop(uint16_t btn, uint16_t pressed, uint16_t released) {
  btn_data = btn;

  /// LED control
  if (pressed & BTN_A) {
    countEnable ^= 1;
  }

  if (pressed & BTN_MINUS) {
    cnt = 0xff;
  }

  if (countEnable) {
    cnt++;
  }

  uint8_t c = cnt >> 4;
  led = (c & 0b0001) << 3;
  led |= (c & 0b0010) << 1;
  led |= (c & 0b0100) >> 1;
  led |= (c & 0b1000) >> 3;
  wii_setLed(led);

  if (pressed & BTN_PLUS) {
  }

  if (pressed & BTN_B) {
  }

  if (!(frameCount % 60)) {
    int even = (frameCount / 60) % 2;
    if (connected) {
      gpio_set_level(LED_BLUE, even);
      gpio_set_level(LED_GREEN, 1);
    } else {
      gpio_set_level(LED_GREEN, even);
      gpio_set_level(LED_BLUE, 1);
    }
  }

  waitFrame(); // wait next frame (60fps)
}

/***************************************************************************
 * Wii Remote event handlers
 ***************************************************************************/
void wii_connected() {
  connected = 1;
  printf("Wii Remote connected.\n");
}
void wii_disconnected() {
  connected = 0;
  printf("Wii Remote disconnected.\n");
}

/***************************************************************************
 * Utilities
 ***************************************************************************/
static TickType_t xLastWakeTime = 0;
static TickType_t xNow;
static const TickType_t xFrequency = 1000 / 60 / portTICK_PERIOD_MS; // 60 fps
void waitFrame() {
  // Always wait at least one frame
  xNow = xTaskGetTickCount();
  if (xLastWakeTime + xFrequency < xNow) {                          // It is already delayed over one frame.
    xLastWakeTime = ((TickType_t)(xNow / xFrequency)) * xFrequency; // Reset the last time.
  }
  vTaskDelayUntil(&xLastWakeTime, xFrequency);
  frameCount++;
}

/***************************************************************************
 * I2C Slave
 ***************************************************************************/
#define _I2C_NUMBER(num) I2C_NUM_##num
#define I2C_NUMBER(num) _I2C_NUMBER(num)

#define DELAY_TIME_BETWEEN_ITEMS_MS 1000 /*!< delay time between different test items */

#define I2C_SLAVE_SCL_IO 19         /*!< gpio number for i2c slave clock */
#define I2C_SLAVE_SDA_IO 18         /*!< gpio number for i2c slave data */
#define I2C_SLAVE_NUM I2C_NUMBER(1) /*!< I2C port number for slave dev */
#define DATA_LENGTH 128             /*!< Data buffer length of test buffer */
// #define I2C_SLAVE_TX_BUF_LEN (2 * DATA_LENGTH) /*!< I2C slave tx buffer size */
// #define I2C_SLAVE_RX_BUF_LEN (2 * DATA_LENGTH) /*!< I2C slave rx buffer size */
#define I2C_SLAVE_TX_BUF_LEN (3) /*!< I2C slave tx buffer size */
#define I2C_SLAVE_RX_BUF_LEN (128) /*!< I2C slave rx buffer size */

#define ESP_SLAVE_ADDR 0x28 /*!< ESP32 slave address, you can set any 7bit value */

static esp_err_t i2c_slave_init() {
  int i2c_slave_port = I2C_SLAVE_NUM;
  i2c_config_t conf_slave;
  conf_slave.sda_io_num = I2C_SLAVE_SDA_IO;
  conf_slave.sda_pullup_en = GPIO_PULLUP_ENABLE;
  conf_slave.scl_io_num = I2C_SLAVE_SCL_IO;
  conf_slave.scl_pullup_en = GPIO_PULLUP_ENABLE;
  conf_slave.mode = I2C_MODE_SLAVE;
  conf_slave.slave.addr_10bit_en = 0;
  conf_slave.slave.slave_addr = ESP_SLAVE_ADDR;
  i2c_param_config(i2c_slave_port, &conf_slave);
  return i2c_driver_install(i2c_slave_port, conf_slave.mode, I2C_SLAVE_RX_BUF_LEN, I2C_SLAVE_TX_BUF_LEN, 0);
}

// uint8_t *data = NULL;
static uint8_t dbuf[3];
static void i2c_slave_task(void *pvParameter) {
  //   if (data == NULL) {
  //     data = NULL;
  //     (uint8_t *)malloc(DATA_LENGTH);
  //   }
  //   uint8_t *data = (uint8_t *)malloc(DATA_LENGTH);

  while (1) {
    dbuf[0] = btn_data & 0xff;
    dbuf[1] = btn_data >> 8;
    dbuf[2] = 0xff;

    // size_t d_size = i2c_slave_write_buffer(I2C_SLAVE_NUM, data, 2, 1000 / portTICK_RATE_MS);
    size_t d_size = i2c_slave_write_buffer(I2C_SLAVE_NUM, dbuf, 3, 1000 / portTICK_RATE_MS);
    // if (d_size == 0) {
    //   ESP_LOGW(TAG, "i2c slave tx buffer full");
    // } else {
    //   ESP_LOGW(TAG, "i2c slave send data");
    // }
  }
}