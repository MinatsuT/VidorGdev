/*
 * Copyright (C) 2017 BlueKitchen GmbH
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the copyright holders nor the names of
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 * 4. Any redistribution, use, or modification is done solely for
 *    personal benefit and not for any commercial purpose or for
 *    monetary gain.
 *
 * THIS SOFTWARE IS PROVIDED BY BLUEKITCHEN GMBH AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL MATTHIAS
 * RINGWALD OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * Please inquire about commercial licensing options at
 * contact@bluekitchen-gmbh.com
 *
 */

#define __BTSTACK_FILE__ "esp32_wiiremote.c"

/*
 * esp32_wiiremote.c
 */
#include <inttypes.h>
#include <stdio.h>

#include "btstack.h"
#include "btstack_config.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#include "nvs.h"
#include "nvs_flash.h"

/***************************************************************************
 * Definitions and variables
 ***************************************************************************/
// L2CAP
static uint16_t l2cap_hid_control_cid;
static uint16_t l2cap_hid_interrupt_cid;

// HCI
static btstack_packet_callback_registration_t hci_event_callback_registration;

// SDP
#define MAX_ATTRIBUTE_VALUE_SIZE 300
static uint8_t hid_descriptor[MAX_ATTRIBUTE_VALUE_SIZE];
static uint16_t hid_descriptor_len;
static uint16_t hid_control_psm;
static uint16_t hid_interrupt_psm;
static uint8_t attribute_value[MAX_ATTRIBUTE_VALUE_SIZE];
static const unsigned int attribute_value_buffer_size = MAX_ATTRIBUTE_VALUE_SIZE;

// GAP
#define MAX_DEVICES 1
enum DEVICE_STATE { REMOTE_NAME_REQUEST, REMOTE_NAME_INQUIRED, REMOTE_NAME_FETCHED };
struct device {
  bd_addr_t address;
  uint8_t pageScanRepetitionMode;
  uint16_t clockOffset;
  enum DEVICE_STATE state;
};
#define INQUIRY_INTERVAL 15
struct device devices[MAX_DEVICES];
int deviceCount = 0;
enum STATE { INIT, ACTIVE };
enum STATE state = INIT;

// NVS
static const char *nvs_namespace = "wiiremote";
static const char *nvs_key = "addr";

// WiiRemote
static bd_addr_t wii_addr;
static uint8_t wii_ready = 0;
static uint16_t wii_btn;
static uint8_t wii_led = 0;

/***************************************************************************
 * Prototypes
 ***************************************************************************/
int btstack_main(int argc, const char *argv[]);
static void main_loop_task(void *pvParameter);

static void packet_handler(uint8_t packet_type, uint16_t channel, uint8_t *packet, uint16_t size);
static void sdp_query_result_handler(uint8_t packet_type, uint16_t channel, uint8_t *packet, uint16_t size);
static void hid_report_handler(const uint8_t *report, uint16_t report_len);

static void gap_scan_start(void);
static int gap_has_more_remote_name_requests(void);
static void gap_continue_remote_names(void);
static void gap_do_next_remote_name_request(void);
static int gap_getDeviceIndexForAddress(bd_addr_t addr);

static esp_err_t nvs_init();
static uint64_t nvs_read_u64(const char *namespace, const char *key);
static uint64_t nvs_write_u64(const char *namespace, const char *key, uint64_t val);

static void connection_start(void);
static esp_err_t connection_try_saved(void);
static esp_err_t connection_try_listed(void);
static void connection_lost(void);

// Main loop
void setup(void);
void loop(uint16_t btn, uint16_t pressed, uint16_t released);
void wii_connected(void);
void wii_disconnected(void);

/***************************************************************************
 * Entry point
 ***************************************************************************/
int btstack_main(int argc, const char *argv[]) {
  (void)argc;
  (void)argv;

  // Initialize L2CAP
  l2cap_init();

  // enabled EIR
  hci_set_inquiry_mode(INQUIRY_MODE_RSSI_AND_EIR);

  // register for HCI events
  hci_event_callback_registration.callback = &packet_handler;
  hci_add_event_handler(&hci_event_callback_registration);

  // Disable stdout buffering
  setbuf(stdout, NULL);

  // Turn on the device
  hci_power_control(HCI_POWER_ON);

  // Start main application loop
  xTaskCreate(&main_loop_task, "main_loop_task", 4096, NULL, 5, NULL);
  return 0;
}

/***************************************************************************
 * LOOP
 ***************************************************************************/
static uint16_t btn_last = 0;
static uint16_t btn_pressed;
static uint16_t btn_released;
static void main_loop_task(void *pvParameter) {
  setup();
  for (;;) {
    btn_pressed = (~btn_last) & wii_btn;
    btn_released = btn_last & (~wii_btn);
    btn_last = wii_btn;
    loop(wii_btn, btn_pressed, btn_released);
  }
}

/***************************************************************************
 * BT functions
 ***************************************************************************/
static uint16_t rfcomm_channel_id;
static char lineBuffer[30];

// Packet Handler
static void packet_handler(uint8_t packet_type, uint16_t channel, uint8_t *packet, uint16_t size) {
  /* LISTING_PAUSE */
  uint8_t event;
  bd_addr_t event_addr;
  uint8_t status;
  uint16_t l2cap_cid;

  bd_addr_t addr;
  int i;
  int index;

  /* LISTING_RESUME */
  switch (packet_type) {

  // ********************************************************************************
  // HCI EVENT
  // ********************************************************************************
  case HCI_EVENT_PACKET:
    event = hci_event_packet_get_type(packet);
    switch (event) {
    /* @text When BTSTACK_EVENT_STATE with state HCI_STATE_WORKING
     * is received and the example is started in client mode, the remote SDP HID query is started.
     */
    case BTSTACK_EVENT_STATE:
      if (btstack_event_state_get_state(packet) == HCI_STATE_WORKING) {
        // gap_scan_start();
        connection_start();
      }
      break;

    // ********************************************************************************
    // BTSTACK
    // ********************************************************************************
    case BTSTACK_EVENT_NR_CONNECTIONS_CHANGED:
      if (!btstack_event_nr_connections_changed_get_number_connections(packet)) {
        printf("NR connection becomes 0\n");
        connection_lost();
      }
      break;

    // ********************************************************************************
    // GAP
    // ********************************************************************************
    case GAP_EVENT_INQUIRY_RESULT:
      if (deviceCount >= MAX_DEVICES) {
        printf("Device found: %s but deviceCount(%d)>=MAX_DEVICES(%d)\n", bd_addr_to_str(addr), deviceCount, MAX_DEVICES);
        break; // already full
      }
      gap_event_inquiry_result_get_bd_addr(packet, addr);
      index = gap_getDeviceIndexForAddress(addr);
      if (index >= 0) {
        printf("Device found: %s but already in our list\n", bd_addr_to_str(addr));
        break; // already in our list
      }

      if (!(addr[0] == 0xB8 && addr[1] == 0xAE && addr[2] == 0x6E)) {
        printf("Device found: %s but not a Nintendo\n", bd_addr_to_str(addr));
        break; // not a Nintenoo
      }

      /* Copy a discovered device into devices[] */
      memcpy(devices[deviceCount].address, addr, 6);
      devices[deviceCount].pageScanRepetitionMode = gap_event_inquiry_result_get_page_scan_repetition_mode(packet);
      devices[deviceCount].clockOffset = gap_event_inquiry_result_get_clock_offset(packet);
      // print info
      printf("Device found: %s ", bd_addr_to_str(addr));
      printf("with COD: 0x%06x, ", (unsigned int)gap_event_inquiry_result_get_class_of_device(packet));
      printf("pageScan %d, ", devices[deviceCount].pageScanRepetitionMode);
      printf("clock offset 0x%04x", devices[deviceCount].clockOffset);
      if (gap_event_inquiry_result_get_rssi_available(packet)) {
        printf(", rssi %d dBm", (int8_t)gap_event_inquiry_result_get_rssi(packet));
      }
      if (gap_event_inquiry_result_get_name_available(packet)) {
        char name_buffer[240];
        int name_len = gap_event_inquiry_result_get_name_len(packet);
        memcpy(name_buffer, gap_event_inquiry_result_get_name(packet), name_len);
        name_buffer[name_len] = 0;
        printf(", name '%s'", name_buffer);
        devices[deviceCount].state = REMOTE_NAME_FETCHED;
        ;
      } else {
        devices[deviceCount].state = REMOTE_NAME_REQUEST;
      }
      printf("\n");
      deviceCount++;
      break;

    case GAP_EVENT_INQUIRY_COMPLETE:
      for (i = 0; i < deviceCount; i++) {
        // retry remote name request
        if (devices[i].state == REMOTE_NAME_INQUIRED) {
          devices[i].state = REMOTE_NAME_REQUEST;
        }
      }
      gap_continue_remote_names();
      break;

    // ********************************************************************************
    // HCI
    // ********************************************************************************
    case HCI_EVENT_REMOTE_NAME_REQUEST_COMPLETE:
      reverse_bd_addr(&packet[3], addr);
      index = gap_getDeviceIndexForAddress(addr);
      if (index >= 0) {
        if (packet[2] == 0) {
          printf("Name: '%s'\n", &packet[9]);
          devices[index].state = REMOTE_NAME_FETCHED;
        } else {
          printf("Failed to get name: page timeout\n");
        }
      }
      gap_continue_remote_names();
      break;

    /* LISTING_PAUSE */
    case HCI_EVENT_PIN_CODE_REQUEST:
      // inform about pin code request
      printf("Pin code request - sending reverse addr as pin\n");
      hci_event_pin_code_request_get_bd_addr(packet, event_addr);
      printf("BD-ADDR: %s\n", bd_addr_to_str(event_addr));
      bd_addr_t local;
      gap_local_bd_addr(local);
      printf("LOCAL-ADDR: %s\n", bd_addr_to_str(local));
      reverse_bd_addr(local, addr);
      printf("PIN: %s\n", bd_addr_to_str(addr));
      char pin[7];
      memcpy(pin, addr, 6);
      pin[6] = 0u;
      gap_pin_code_response(event_addr, pin);
      break;

    case HCI_EVENT_USER_CONFIRMATION_REQUEST:
      // inform about user confirmation request
      printf("SSP User Confirmation Request with numeric value '%" PRIu32 "'\n", little_endian_read_32(packet, 8));
      printf("SSP User Confirmation Auto accept\n");
      break;
      /* LISTING_RESUME */

    case HCI_EVENT_COMMAND_COMPLETE:
      if (HCI_EVENT_IS_COMMAND_COMPLETE(packet, hci_write_authentication_enable)) {
        printf("HCI_EVENT_COMMAND_COMPLETE: hci_write_authentication_enable\n");
        printf("Start SDP HID query for remote HID Device.\n");
        sdp_client_query_uuid16(&sdp_query_result_handler, wii_addr, BLUETOOTH_SERVICE_CLASS_HUMAN_INTERFACE_DEVICE_SERVICE);
      }
      break;

    // ********************************************************************************
    // L2CAP
    // ********************************************************************************
    case L2CAP_EVENT_CHANNEL_OPENED:
      status = packet[2];
      if (status) {
        printf("L2CAP Connection failed: 0x%02x\n", status);
        connection_start();
        break;
      }
      l2cap_cid = little_endian_read_16(packet, 13);
      if (!l2cap_cid)
        break;
      if (l2cap_cid == l2cap_hid_control_cid) {
        status = l2cap_create_channel(packet_handler, wii_addr, hid_interrupt_psm, 48, &l2cap_hid_interrupt_cid);
        if (status) {
          printf("Connecting to HID Control failed: 0x%02x\n", status);
          connection_start();
          break;
        }
      }
      if (l2cap_cid == l2cap_hid_interrupt_cid) {
        printf("HID Connection established\n");
        wii_ready = 1;
        wii_connected();

        printf("Save connected address %s to NVS ... ", bd_addr_to_str(wii_addr));
        uint64_t addr;
        memcpy(&addr, wii_addr, 6);
        if (nvs_write_u64(nvs_namespace, nvs_key, addr) == ESP_OK) {
          printf("Done\n");
        } else {
          printf("Failed\n");
        }
      }
      break;

    // ********************************************************************************
    // RFCOMM
    // ********************************************************************************
    case RFCOMM_EVENT_INCOMING_CONNECTION:
      // data: event (8), len(8), address(48), channel (8), rfcomm_cid (16)
      rfcomm_event_incoming_connection_get_bd_addr(packet, event_addr);
      uint8_t rfcomm_channel_nr;
      rfcomm_channel_nr = rfcomm_event_incoming_connection_get_server_channel(packet);
      rfcomm_channel_id = rfcomm_event_incoming_connection_get_rfcomm_cid(packet);
      printf("RFCOMM channel %u requested for %s\n", rfcomm_channel_nr, bd_addr_to_str(event_addr));
      rfcomm_accept_connection(rfcomm_channel_id);
      break;

    case RFCOMM_EVENT_CHANNEL_OPENED:
      // data: event(8), len(8), status (8), address (48), server channel(8), rfcomm_cid(16), max frame size(16)
      if (rfcomm_event_channel_opened_get_status(packet)) {
        printf("RFCOMM channel open failed, status %u\n", rfcomm_event_channel_opened_get_status(packet));
      } else {
        rfcomm_channel_id = rfcomm_event_channel_opened_get_rfcomm_cid(packet);
        uint16_t mtu;
        mtu = rfcomm_event_channel_opened_get_max_frame_size(packet);
        printf("RFCOMM channel open succeeded. New RFCOMM Channel ID %u, max frame size %u\n", rfcomm_channel_id, mtu);
      }
      break;
    case RFCOMM_EVENT_CAN_SEND_NOW:
      rfcomm_send(rfcomm_channel_id, (uint8_t *)lineBuffer, strlen(lineBuffer));
      break;

      /* LISTING_PAUSE */
    case RFCOMM_EVENT_CHANNEL_CLOSED:
      printf("RFCOMM channel closed\n");
      rfcomm_channel_id = 0;
      break;

    default:
      break;
    }
    break;

  // ********************************************************************************
  // L2CAP DATA PACKET
  // ********************************************************************************
  case L2CAP_DATA_PACKET:
    // for now, just dump incoming data
    if (channel == l2cap_hid_interrupt_cid) {
      hid_report_handler(packet, size);
    } else if (channel == l2cap_hid_control_cid) {
      printf("HID Control: ");
      printf_hexdump(packet, size);
    } else {
      break;
    }

  default:
    break;
  }
}

// SDP query result handler
static void sdp_query_result_handler(uint8_t packet_type, uint16_t channel, uint8_t *packet, uint16_t size) {

  UNUSED(packet_type);
  UNUSED(channel);
  UNUSED(size);

  des_iterator_t attribute_list_it;
  des_iterator_t additional_des_it;
  des_iterator_t prot_it;
  uint8_t *des_element;
  uint8_t *element;
  uint32_t uuid;
  uint8_t status;

  switch (hci_event_packet_get_type(packet)) {
  case SDP_EVENT_QUERY_ATTRIBUTE_VALUE:
    if (sdp_event_query_attribute_byte_get_attribute_length(packet) <= attribute_value_buffer_size) {
      attribute_value[sdp_event_query_attribute_byte_get_data_offset(packet)] = sdp_event_query_attribute_byte_get_data(packet);
      if ((uint16_t)(sdp_event_query_attribute_byte_get_data_offset(packet) + 1) == sdp_event_query_attribute_byte_get_attribute_length(packet)) {
        switch (sdp_event_query_attribute_byte_get_attribute_id(packet)) {
        case BLUETOOTH_ATTRIBUTE_PROTOCOL_DESCRIPTOR_LIST:
          for (des_iterator_init(&attribute_list_it, attribute_value); des_iterator_has_more(&attribute_list_it); des_iterator_next(&attribute_list_it)) {
            if (des_iterator_get_type(&attribute_list_it) != DE_DES)
              continue;
            des_element = des_iterator_get_element(&attribute_list_it);
            des_iterator_init(&prot_it, des_element);
            element = des_iterator_get_element(&prot_it);
            if (!element)
              continue;
            if (de_get_element_type(element) != DE_UUID)
              continue;
            uuid = de_get_uuid32(element);
            des_iterator_next(&prot_it);
            switch (uuid) {
            case BLUETOOTH_PROTOCOL_L2CAP:
              if (!des_iterator_has_more(&prot_it))
                continue;
              de_element_get_uint16(des_iterator_get_element(&prot_it), &hid_control_psm);
              printf("HID Control PSM: 0x%04x\n", (int)hid_control_psm);
              break;
            default:
              break;
            }
          }
          break;
        case BLUETOOTH_ATTRIBUTE_ADDITIONAL_PROTOCOL_DESCRIPTOR_LISTS:
          for (des_iterator_init(&attribute_list_it, attribute_value); des_iterator_has_more(&attribute_list_it); des_iterator_next(&attribute_list_it)) {
            if (des_iterator_get_type(&attribute_list_it) != DE_DES)
              continue;
            des_element = des_iterator_get_element(&attribute_list_it);
            for (des_iterator_init(&additional_des_it, des_element); des_iterator_has_more(&additional_des_it); des_iterator_next(&additional_des_it)) {
              if (des_iterator_get_type(&additional_des_it) != DE_DES)
                continue;
              des_element = des_iterator_get_element(&additional_des_it);
              des_iterator_init(&prot_it, des_element);
              element = des_iterator_get_element(&prot_it);
              if (!element)
                continue;
              if (de_get_element_type(element) != DE_UUID)
                continue;
              uuid = de_get_uuid32(element);
              des_iterator_next(&prot_it);
              switch (uuid) {
              case BLUETOOTH_PROTOCOL_L2CAP:
                if (!des_iterator_has_more(&prot_it))
                  continue;
                de_element_get_uint16(des_iterator_get_element(&prot_it), &hid_interrupt_psm);
                printf("HID Interrupt PSM: 0x%04x\n", (int)hid_interrupt_psm);
                break;
              default:
                break;
              }
            }
          }
          break;
        case BLUETOOTH_ATTRIBUTE_HID_DESCRIPTOR_LIST:
          for (des_iterator_init(&attribute_list_it, attribute_value); des_iterator_has_more(&attribute_list_it); des_iterator_next(&attribute_list_it)) {
            if (des_iterator_get_type(&attribute_list_it) != DE_DES)
              continue;
            des_element = des_iterator_get_element(&attribute_list_it);
            for (des_iterator_init(&additional_des_it, des_element); des_iterator_has_more(&additional_des_it); des_iterator_next(&additional_des_it)) {
              if (des_iterator_get_type(&additional_des_it) != DE_STRING)
                continue;
              element = des_iterator_get_element(&additional_des_it);
              const uint8_t *descriptor = de_get_string(element);
              hid_descriptor_len = de_get_data_size(element);
              memcpy(hid_descriptor, descriptor, hid_descriptor_len);
              printf("HID Descriptor:\n");
              printf_hexdump(hid_descriptor, hid_descriptor_len);
            }
          }
          break;
        default:
          break;
        }
      }
    } else {
      fprintf(stderr, "SDP attribute value buffer size exceeded: available %d, required %d\n", attribute_value_buffer_size,
              sdp_event_query_attribute_byte_get_attribute_length(packet));
    }
    break;

  case SDP_EVENT_QUERY_COMPLETE:
    if (!hid_control_psm) {
      printf("HID Control PSM missing\n");
      connection_start();
      break;
    }
    if (!hid_interrupt_psm) {
      printf("HID Interrupt PSM missing\n");
      connection_start();
      break;
    }
    printf("Setup HID\n");
    status = l2cap_create_channel(packet_handler, wii_addr, hid_control_psm, 48, &l2cap_hid_control_cid);
    if (status) {
      printf("Connecting to HID Control failed: 0x%02x\n", status);
      connection_start();
      break;
    }

    break;
  }
}

// HID Report Handler
static void hid_report_handler(const uint8_t *report, uint16_t report_len) {
  // check if HID Input Report
  if (report_len < 1)
    return;
  if (*report != 0xa1)
    return;
  report++;
  report_len--;
#if 0
    for (int i = 0; i < report_len; i++) {
        printf("%02X ", report[i]);
    }
    printf("\n");
#endif
  switch (report[0]) {
  case 0x30: // Data reports
    wii_btn = report[1] << 8 | report[2];
    break;
  }
}

// GAP related functions
static void gap_scan_start(void) {
  if (deviceCount < MAX_DEVICES) {
    printf("Starting inquiry scan..\n");
    gap_inquiry_start(INQUIRY_INTERVAL);
  }
}

static int gap_has_more_remote_name_requests(void) {
  int i;
  for (i = 0; i < deviceCount; i++) {
    if (devices[i].state == REMOTE_NAME_REQUEST)
      return 1;
  }
  return 0;
}

static void gap_continue_remote_names(void) {
  if (gap_has_more_remote_name_requests()) {
    gap_do_next_remote_name_request();
    return;
  }

  // All remote names are received. Start connection.
  printf("All rmote names are gathered, inquiry is completed.\n");
  connection_start();
}

static void gap_do_next_remote_name_request(void) {
  int i;
  for (i = 0; i < deviceCount; i++) {
    // remote name request
    if (devices[i].state == REMOTE_NAME_REQUEST) {
      devices[i].state = REMOTE_NAME_INQUIRED;
      printf("Get remote name of %s...\n", bd_addr_to_str(devices[i].address));
      gap_remote_name_request(devices[i].address, devices[i].pageScanRepetitionMode, devices[i].clockOffset | 0x8000);
      return;
    }
  }
}

static int gap_getDeviceIndexForAddress(bd_addr_t addr) {
  int j;
  for (j = 0; j < deviceCount; j++) {
    if (bd_addr_cmp(addr, devices[j].address) == 0) {
      return j;
    }
  }
  return -1;
}

/***************************************************************************
 * Connection establishment functions.
 ***************************************************************************/
enum CONNECTION_STATE { IDLE, TRY_SAVED, TRY_LISTED } connection_state = IDLE;

static esp_err_t connection_try_saved(void) {
  // Read last saved addr.
  uint64_t stored_addr = nvs_read_u64(nvs_namespace, nvs_key);
  if (stored_addr == 0) {
    return ESP_FAIL;
  }
  memcpy(wii_addr, &stored_addr, 6);
  printf("Try saved address.\n");
  printf("Stored address = %s\n", bd_addr_to_str(wii_addr));
  printf("Start SDP HID query for remote HID Device.\n");
  sdp_client_query_uuid16(&sdp_query_result_handler, wii_addr, BLUETOOTH_SERVICE_CLASS_HUMAN_INTERFACE_DEVICE_SERVICE);
  return ESP_OK;
}

static esp_err_t connection_try_listed(void) {
  if (deviceCount == 0) {
    return ESP_FAIL;
  }
  printf("Try addresses in device list.\n");
  printf("Write authentication enable\n");
  hci_send_cmd(&hci_write_authentication_enable, 1);
  return ESP_OK;
}

static void connection_start(void) {
  printf("Connection start(%d):\n", connection_state);
  if (wii_ready) {
    printf("However, already connected. Do nothing.\n");
  }

  if (connection_state == IDLE) {
    connection_state = TRY_SAVED;
    if (connection_try_saved() == ESP_OK) {
      return;
    }
  }

  if (connection_state == TRY_SAVED) {
    connection_state = TRY_LISTED;
    if (connection_try_listed() == ESP_OK) {
      return;
    }
  }

  connection_state = IDLE;
  printf("No connection candidates, giving up.\n");
  gap_scan_start();
}

static void connection_lost(void) {
  if (wii_ready) {
    wii_ready = 0;
    wii_disconnected();
  }
  connection_start();
}

/***************************************************************************
 * NVS functions
 ***************************************************************************/
static esp_err_t nvs_init() {
  // Initialize NVS
  esp_err_t err = nvs_flash_init();
  if (err == ESP_ERR_NVS_NO_FREE_PAGES || err == ESP_ERR_NVS_NEW_VERSION_FOUND) {
    printf("NVS: No free pages or new version found, try erase.\n");
    // NVS partition was truncated and needs to be erased
    // Retry nvs_flash_init
    err = nvs_flash_erase();
    if (err != ESP_OK) {
      printf("NVS: Erase failed.\n");
      return err;
    }
    err = nvs_flash_init();
  }
  if (err != ESP_OK) {
    printf("NVS: Init failed.\n");
  }

  return err;
}

static uint64_t nvs_read_u64(const char *namespace, const char *key) {
  // Init
  nvs_init();

  // Open
  nvs_handle handle;
  esp_err_t err = nvs_open(namespace, NVS_READWRITE, &handle);
  if (err != ESP_OK) {
    printf("NVS: Open failed.\n");
    return 0;
  }
  printf("NVS: Open success.\n");

  // Read
  printf("NVS: Reading.... ");
  uint64_t val = 0;
  err = nvs_get_u64(handle, key, &val);
  switch (err) {
  case ESP_OK:
    printf("Done\n");

    break;
  case ESP_ERR_NVS_NOT_FOUND:
    printf("No value for (%s.%s).\n", namespace, key);
    break;
  default:
    printf("Error (%s) reading!\n", esp_err_to_name(err));
  }

  nvs_close(handle);

  return val;
}

static uint64_t nvs_write_u64(const char *namespace, const char *key, uint64_t val) {
  // Init
  nvs_init();

  // Open
  nvs_handle handle;
  esp_err_t err = nvs_open(namespace, NVS_READWRITE, &handle);
  if (err != ESP_OK) {
    printf("NVS: Open failed.\n");
    return 0;
  }
  printf("NVS: Open success.\n");

  // Write
  printf("Updating %s.%s=%X ... ", namespace, key, val);
  err = nvs_set_u64(handle, key, val);
  printf((err != ESP_OK) ? "Failed!\n" : "Done\n");

  printf("Committing updates in NVS ... ");
  err = nvs_commit(handle);
  printf((err != ESP_OK) ? "Failed!\n" : "Done\n");

  // Close
  nvs_close(handle);

  return err;
}

/***************************************************************************
 * WiiRemote functions
 ***************************************************************************/
uint8_t wii_isReady() { return wii_ready; }
uint16_t wii_getButton() { return wii_btn; }
uint16_t wii_getLed() { return wii_led; }

void wii_setLed(uint16_t led) {
  wii_led = led;
  uint8_t report[] = {0xa2, 0x11, wii_led << 4};
  if (wii_ready) {
    if (l2cap_send(l2cap_hid_interrupt_cid, &report[0], sizeof(report)) != ESP_OK) {
      connection_lost();
    }
  }
}
