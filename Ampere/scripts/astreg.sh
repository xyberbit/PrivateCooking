#!/bin/bash

# SNOW AST2500
# UART1-RS232   (COM & VGA)
# UART2-S0UART4 (ATF)
# UART3-S0UART1 (SCP)
# UART4-S0UART0 (CPU)
# UART5-Console (BMC_UART1)

SCU80=0xC0C00000
SCU84=


SCU=0x1E6E2000
SCU_MAGIC=0x1688A8A8
UART1=
UART2=
UART3=
UART4=
UART5=

