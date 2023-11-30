### Firmware Update under MegaRAC  
&emsp;copy \<image\> to directory /tmp  
&emsp;***bmc_spi_update -p mtd0 -u /tmp/\<image\>***  

### Firmware Update under OpenBMC  
&emsp;copy \<image\> to file /run/initramfs/image-bmc  
&emsp;***reboot***  

### Generation of 4M-Byte 0xFF under BMC  
&emsp;***cd /tmp; b=\`echo -en "\xff"\`; for i in 0 1 2 3 4 5 6 7 8 9; do b="$b$b"; done** # 2^10=1K*  
&emsp;***echo -n "$b" >4m.0xff; dd if=4m.0xff of=4m.0xff seek=1 bs=1K count=$((1024\*4-1))** # 1K\*4K=4M*  
