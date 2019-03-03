#include "AvalonMM.h"
#include "Blaster.h"

#define PIO_BASE (0x00800000)
#define PIO_IO (0x00800000 + 0)
#define PIO_DIR (0x00800000 + 4)
#define PIO_DIR_IN 0
#define PIO_DIR_OUT 1

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

    AvalonMM.begin();
}

void loop() {
    // wait until fpga comes up
    while (AvalonMM.read(0, 0x00000000) == 0xffff)
        ;

    AvalonMM.write(0, 0x00000000, 0x00);
    AvalonMM.memoryDump(0x00000000, 0x100);
    AvalonMM.write(0, 0x00000000, 0x12);
    AvalonMM.memoryDump(0x00000000, 0x100);

    AvalonMM.write(0, PIO_DIR, PIO_DIR_OUT);
    while (1) {
        USBBlaster.loop();

        AvalonMM.write(0, PIO_IO, 1);
        blasterWait(100);
        AvalonMM.write(0, PIO_IO, 0);
        blasterWait(100);
    }
}

void blasterWait(int n) {
    int i;
    for (i = 0; i < n; i += 10) {
        USBBlaster.loop();
        delay(10);
    }
}
