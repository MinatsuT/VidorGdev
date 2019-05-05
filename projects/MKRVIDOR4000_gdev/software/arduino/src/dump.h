#ifndef DUMP_H_
#define DUMP_H_

#include <stdio.h>
#include <ctype.h>

void dumpInit(void);
void dumpPut(uint32_t addr, uint8_t d);
char *dumpSPrint(void);

#endif /*DUMP_H_*/
