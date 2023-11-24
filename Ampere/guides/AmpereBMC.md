Firmware Update under MegaRAC
  copy BMC image to /tmp
  bmc_spi_update -p mtd0 -u <image>

Firmware Update under OpenBMC
  copy image to /run/initramfs/image-bmc
  reboot
