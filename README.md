# Baremetal graphics on Orange Pi Zero 3

## Task #1 - QEMU

Attempt to make a QEMU machine emulating Orange Pi Zero 3

Progress so far:

* Got QEMU OrangePi PC working (Allwinner H3). I had no problem running either
  Armbian or OrangePi images direct from `-sd` or with components extracted.
  HOWEVER: video is *not* implemented in this machine type yet.
* OrangePi Zero3 kernel runs on `virt`
* Created a new machine and the H616. Just started work on this.
* The machine runs for a bit, but I need to get the correct devices linked
* Figured out how to log unimplemented device accesses and additional logging
  (see below)

### Notes

Various references:

* https://airbus-seclab.github.io/qemu_blog/machine.html
* https://www.qemu.org/docs/master/system/introduction.html
* https://www.qemu.org/docs/master/system/arm/orangepi.html

Running an aarch64 Image.gz with no emulated hardware:

```
qemu-system-aarch64 \
    -M virt \
    -cpu cortex-a57 \
    -kernel Image.gz \
    -serial mon:stdio
```

If you want to monitor qemu you can do so at sacrifice to serial console:

```
-monitor stdio -serial /dev/null
```

If you want to see logs about unimplemented hardware being touched:

```
-D ./log.txt -d unimp
```

For a list of log items: `-d help`. Also: in_asm, out_asm

If you want to perform tracing: `-trace "*"`. Again `-trace help` lists available.

## Future tasks

* Using FEL mode, demonstrate a working kernel with HDMI output
  (That might be the Armbian kernel)

## Completed work

* [Explain FEL mode](docs/FEL.md)
* Make devcontainer
* Build *any* Linux kernel - Built linux-sunxi
* Build U-Boot and ATF
* Build an initrd (buildroot)
* Get it booting with FEL mode, such that userland apps work in console

## Building

The following items have not make it to a makefile yet.

### rootfs 8m

```
wget https://buildroot.org/downloads/buildroot-2025.02.3.tar.xz
tar -xf buildroot-2025.02.3.tar.xz
make menuconfig
    aarch64 little endian
    cortex-a53
    Filesystem images >
        cpio the root filesystem
        compression: lzma
        Create u-Boot image of the root filesystem
make -j `nproc`
```

### Kernel 4m

Mainline:

```
git clone -b v6.15 https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
cd linux
cp ../armbian-build/config/kernel/linux-sunxi64-edge.config .config
yes "" | make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- oldconfig
make -j`nproc` ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- all

```

Sunxi:

```
git clone -b sunxi/for_next https://git.kernel.org/pub/scm/linux/kernel/git/sunxi/linux.git linux-sunxi
cd linux-sunxi
cp ../armbian-build/config/kernel/linux-sunxi64-edge.config .config
yes "" | make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- oldconfig
make -j`nproc` ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- all
```

### ARM Trusted Firmware 4s

As per: https://github.com/u-boot/u-boot/blob/master/board/sunxi/README.sunxi64

```
git clone -b lts-v2.12.3 https://github.com/TrustedFirmware-A/trusted-firmware-a.git
cd trusted-firmware-a
make PLAT=sun50i_h616 DEBUG=1 bl31
```

### U-Boot 6s

As per: https://docs.u-boot.org/en/stable/build/gcc.html

```
git clone -b v2025.04 https://source.denx.de/u-boot/u-boot.git
cd u-boot
ln -s ../trusted-firmware-a/build/sun50i_h616/debug/bl31.bin
make orangepi_zero3_defconfig
CROSS_COMPILE=aarch64-linux-gnu- make -j`nproc`
```

## FEL mode booting...

As per https://linux-sunxi.org/FEL/USBBoot, we get the offsets from the U-boot
code:

```
#define SDRAM_OFFSET(x) 0x4##x
#define BOOTM_SIZE        __stringify(0xa000000)
#define KERNEL_ADDR_R     __stringify(SDRAM_OFFSET(0080000))
#define KERNEL_COMP_ADDR_R __stringify(SDRAM_OFFSET(4000000))
#define KERNEL_COMP_SIZE  __stringify(0xb000000)
#define FDT_ADDR_R        __stringify(SDRAM_OFFSET(FA00000))
#define SCRIPT_ADDR_R     __stringify(SDRAM_OFFSET(FC00000))
#define PXEFILE_ADDR_R    __stringify(SDRAM_OFFSET(FD00000))
#define FDTOVERLAY_ADDR_R __stringify(SDRAM_OFFSET(FE00000))
#define RAMDISK_ADDR_R    __stringify(SDRAM_OFFSET(FF00000))
```

So that translates to the following locations:

```
bootm_size     = 0xa000000
kernel_addr_r  = 0x40080000
fdt_addr_r     = 0x4FA00000
scriptaddr     = 0x4FC00000
pxefile_addr_r = 0x4FD00000
ramdisk_addr_r = 0x4FF00000
```

We plug those values into a `sunxi-fel uboot` command as follows:

```
sunxi-fel -v uboot u-boot-sunxi-with-spl.bin \
             write 0x40080000 Image \
             write 0x4FA00000 sun50i-h618-orangepi-zero3.dtb \
             write 0x4FC00000 boot.scr \
             write 0x4FF00000 rootfs.cpio.lzma.uboot
```

apritzel's script automates some of that. In fact we don't need the DTB; that's
included in the u-boot-sunxi-with-spl.bin (?).

bootscript.cmd:
```
setenv bootargs "console=ttyS0,115200n8 earlycon"
booti $kernel_addr_r $ramdisk_addr_r:<LENGTH OF ROOTFS> $fdtcontroladdr
```

```
mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "boot script" -d assets/bootscript.cmd bootscript.scr
sunxi-fel -v uboot u-boot/u-boot-sunxi-with-spl.bin \
    write 0x40080000 linux/arch/arm64/boot/Image.gz \
    write 0x4FF00000 buildroot-2025.02.3/output/images/rootfs.cpio.uboot \
    write 0x4FC00000 bootscript.img

found DT name in SPL header: allwinner/sun50i-h618-orangepi-zero3
Stack pointers: sp_irq=0x00021400, sp=0x00053FFC
MMU is not enabled by BROM
=> Executing the SPL... done.
loading image "ARM Trusted Firmware" (53361 bytes) to 0x40000000
loading image "U-Boot" (748288 bytes) to 0x4a000000
loading DTB "allwinner/sun50i-h618-orangepi-zero3" (27816 bytes)
Passing boot info via sunxi SPL: script address = 0x4FC00000, uEnv length = 0
Starting U-Boot (0x40000000).
Store entry point 0x40000000 to RVBAR 0x08100040, and request warm reset with RMR mode 3... done.
```

This works! It takes around 44s though. (That was using the USB Type-A. Using
USB-C was even slower (1m50s)! Must have a problem with my ports.)

## U-Boot scripts

https://linux-sunxi.org/U-Boot/Configuration

## QEMU and Raspberry Pi references

* https://gist.github.com/cGandom/23764ad5517c8ec1d7cd904b923ad863

## END
