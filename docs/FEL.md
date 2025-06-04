# Getting a device into FEL mode

As per the [documentation](https://linux-sunxi.org/FEL#Entering_FEL_mode)
FEL mode is cool.

A pristine Orange Pi Zero 3 can be *made* to boot into FEL mode by flashing the
image in assets/fel-sdboot.sunxi onto a microSD card and booting from that.

```
sudo bmaptool copy --nobmap assets/fel-sdboot.sunxi /dev/sdX
```

(The image is just the image from the above website with 8KiB of zero padding
before it to make flashing easier.)

The `sunxi-fel` tool can be used to interact with the device over USB when the
device is in FEL mode (so you need to be powering it over USB from your host).

Here's how the factory installed image can be extracted from the device's SPI
flash:

```
$ sunxi-fel -l
USB device 001:038   Allwinner H616    33802000:4c004808:01474788:2c6c22d1
$ sunxi-fel spiflash-info
Manufacturer: Unknown (5Eh), model: 40h, size: 16777216 bytes.
$ sunxi-fel spiflash-read 0x0 16777216 assets/factory-spi.sunxi
```

You can flash a FEL mode image to the SPI flash. Here we do that:

```
$ sunxi-fel spiflash-write 0x0 assets/fel-spi.sunxi 
electricworry@BOB1:~/projects/mace-iw/orange-pi-zero-3-baremetal/assets$ sunxi-fel -l
# And after rebooting, confirmation:
$ sunxi-fel -l
USB device 001:039   Allwinner H616    33802000:4c004808:01474788:2c6c22d1
```

(The image is just the image from the above website; no padding required.)

## JTAG

Luckily JTAG mode is already enabled too:

```
$ sunxi-fel readl 0x0300B0B4
0x07373733
```

If that was not the case, we would use `writel` to write that value to the
register.

## Things to do in FEL mode

Apart from the SPI flashing which we did, there are far more important things
FEL can do, such as booting.

From IRC chat:

```
2025-05-11

10:13 <tokyovigilante> electricworry: I'm just working on a v10 of the display engine patches, then will send a new LCD series with macromorgan's fixes. Then there are YUV and HDMI patches on top which I will clean up as a new out-of-tree branch, but they will need rework and input form jernej and others before they are ready for mainline
15:47 <electricworry> tokyovigilante: Thanks. I will keep an eye on the mailing list.
16:08 <electricworry> I've been using Yocto to build Orange Pi Zero 3 images for testing. Do people have recommendations for a more lightweight apparatus for quickly testing kernel changes on devices? I find the change-build-flash loop for testing code changes to be a bit unweildy.
16:42 <apritzel> electricworry: there are quite some ways, depends on what you prefer: you can for instance build mainline U-Boot and flash that to the SPI flash: https://docs.u-boot.org/en/latest/board/allwinner/sunxi.html#installing-on-spi-flash
16:43 <apritzel> electricworry: then load the kernel via Ethernet/TFTP, either with some simple initrd, or with a rootfs from SD card
16:44 <apritzel> or you load U-Boot and the kernel via FEL: sunxi-fel uboot u-boot-sunxi-with-spl.bin write 0x40080000 Image.gz
17:07 <electricworry> apritzel: That sounds excellent. I've played around with FEL mode for testing baremetal code on some boards but not for loading the kernel. Is it possible to load a minimal rootfs with some userland tools also via that method?
18:12 <apritzel> electricworry: yes, I made a script to load U-Boot, the kernel and my testing initramfs, and automatically boot it
18:14 <apritzel> (or you just add: "write 0x4ff00000 initramfs.gz")
18:20 <apritzel> https://gist.github.com/apritzel/22d5d2a8f87625e477a9b2a3209c0381
18:23 <apritzel> oh, and I recommend to gzip your kernel before uploading it, that saves quite some time (the BootROM OTG implementation isn't particularly fast). U-Boot detects the compression automatically and decompresses it
20:18 <electricworry> apritzel: Thank you very much! I should have a few hours this week to test that all out. I'll ask further questions only if I run into a wall. You're tremendously helpful here.
20:49 <dlan> for compression, just use "make Image.gz" to build the kernel image 

2025-05-12

01:36 <junari> electricworry: I build the package using makepkg and PKGBUILD, specifying local storage of the source files. The build is fast, as the compilation only affects the modified files. After that, the compiled package is sent to the device and installed via pacman -U 
```