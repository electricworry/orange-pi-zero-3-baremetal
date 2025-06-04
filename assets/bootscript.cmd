setenv bootargs "console=ttyS0,115200n8 earlycon"
booti $kernel_addr_r $ramdisk_addr_r:RAMDISK_SIZE $fdtcontroladdr
