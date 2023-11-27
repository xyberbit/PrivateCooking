### Firmware Update under MegaRAC  
&emsp;copy \<image\> to directory /tmp  
&emsp;***bmc_spi_update -p mtd0 -u /tmp/\<image\>***  

### Firmware Update under OpenBMC  
&emsp;copy \<image\> to file /run/initramfs/image-bmc  
&emsp;***reboot***  
