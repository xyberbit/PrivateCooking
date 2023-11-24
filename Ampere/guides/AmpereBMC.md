Firmware Update under MegaRAC__
  copy BMC image to /tmp__
  bmc_spi_update -p mtd0 -u <image>__
__
Firmware Update under OpenBMC__
  copy image to /run/initramfs/image-bmc__
  reboot__
