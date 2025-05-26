#!/bin/bash
devmem 0x1E6E2000 32 0x1688A8A8 # SCU unlock
devmem 0x1E6E2080 32 0xC0C00000 # enable UART3 Tx/Rx
devmem 0x1E6E2000 32 0x00000000 # SCU lock
gpiotool --set-data-high 60 # select CPU SCP to BMC UART3 (/dev/ttyS2)
gpiotool --set-data-low  59
/conf/picocom -b 115200 /dev/ttyS2
