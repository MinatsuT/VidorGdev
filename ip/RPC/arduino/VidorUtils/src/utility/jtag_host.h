/*
  This file is part of the VidorBoot/VidorPeripherals/VidorGraphics library.
  Copyright (c) 2018 Arduino SA. All rights reserved.

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
*/

#ifndef __JTAG_HOST_H__
#define __JTAG_HOST_H__

#include <stddef.h>
#include <stdint.h>

// setups the JTAG host
extern int jtag_host_setup();

// shutdowns the JTAG host
extern int jtag_host_shutdown();

// set TMS to the value and pulses TCK
extern void jtag_host_pulse_tck(int tms);

// pulses TCK and returns value of TDO pin
extern int jtag_host_pulse_tdo_bit();

// pulses out an instrution of bits length, returns data pulsed in from TDO
extern unsigned int jtag_host_pulse_tdio_instruction(int bits, unsigned int out);

// pulses out an instrution of bits length
extern void jtag_host_pulse_tdi_instruction(int bits, unsigned int out);

// pulses out data to TDI of bits length, returns data pulsed in from TDO
extern unsigned int jtag_host_pulse_tdio(int bits, unsigned int out);

// pulses out bits 0's to TDI
extern void jtag_host_pulse_tdi_0(int bits);

// pulses out bytes to TDI
extern void jtag_host_pulse_tdi(const uint8_t* data, size_t size);

// pulses in bytes from TDO
extern void jtag_host_pulse_tdo(uint8_t* data, size_t size);

#endif
