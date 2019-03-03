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

#include "VidorJTAG.h"

#include "VidorMailbox.h"
#include "VidorIRQ.h"

#define MB_BASE     0x00000000
#define MB_INT_PIN  31
#define MB_TIMEOUT  5000

VidorMailboxClass::VidorMailboxClass() {}

int VidorMailboxClass::begin()
{
	if (!VidorJTAG.begin()) {
		return 0;
	}

	uint32_t rpc[1];
	rpc[0] = 0;

	VidorJTAG.writeBuffer(MB_BASE, rpc, 1);

	pinMode(MB_INT_PIN, OUTPUT);
	digitalWrite(MB_INT_PIN, LOW);

	attachInterrupt(IRQ_PIN, VidorIRQ::onInterrupt, HIGH);

	return 1;
}

void VidorMailboxClass::end()
{
	VidorJTAG.end();

	digitalWrite(MB_INT_PIN, LOW);
	pinMode(MB_INT_PIN, INPUT);
}

void VidorMailboxClass::reload()
{
	VidorJTAG.reset();
}

int VidorMailboxClass::sendCommand(const uint32_t data[], size_t len)
{
	if (data[0] == 0) {
		return -1;
	}

	if (_debugStream != NULL) {
		char strhex[10];
		_debugStream->print("sendCommand giid:" + String((data[0]>>24)&0xFF) +
							", chn:" + String((data[0]>>12)&0xFFF) +
							", rpc:" + String((data[0]    )&0xFFF) +
									", len:" + String(len));
		for (int i = 0; i < len - 1; i++) {
			sprintf(strhex, " %08X", data[i + 1]);
			_debugStream->print(strhex);
		}
		_debugStream->println("");
	}

	VidorIRQ::lock();

	if (write(0x00, data, len) != (int)len) {
		VidorIRQ::unlock();
		return -1;
	}

	digitalWrite(MB_INT_PIN, HIGH);
	digitalWrite(MB_INT_PIN, LOW);

	for (unsigned long start = millis(); (millis() - start) < MB_TIMEOUT;) {
		uint32_t result;
		read(0x00, &result, 1);

		if (result == 0) {
			read(0x01, &result, 1);
			if (_debugStream != NULL) {
				_debugStream->println("sendCommand return " + String(result, HEX));
			}
			VidorIRQ::unlock();
			return result;
		}
	}

	if (_debugStream != NULL) {
		_debugStream->println("sendCommand Timeout");
	}
	VidorIRQ::unlock();
	return -1;
}

int VidorMailboxClass::sendEvent(const uint32_t data[], size_t len)
{
	VidorIRQ::lock();
	if (write(0x00, data, len) != (int)len) {
		VidorIRQ::unlock();
		return -1;
	}
	VidorIRQ::unlock();

	digitalWrite(MB_INT_PIN, HIGH);
	digitalWrite(MB_INT_PIN, LOW);

	return len;
}

int VidorMailboxClass::read(uint32_t address, uint32_t data[], size_t len)
{
	VidorJTAG.readBuffer(MB_BASE + address, data, len);

	return len;
}

int VidorMailboxClass::write(uint32_t address, const uint32_t data[], size_t len)
{
	return VidorJTAG.writeBuffer(MB_BASE + address, data, len);
}

VidorMailboxClass VidorMailbox;
