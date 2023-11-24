Firmware Update under MegaRAC<br/>
  copy BMC image to /tmp<br/>
  bmc_spi_update -p mtd0 -u <image><br/>
<br/>
Firmware Update under OpenBMC<br/>
  copy image to /run/initramfs/image-bmc<br/>
  reboot<br/>
