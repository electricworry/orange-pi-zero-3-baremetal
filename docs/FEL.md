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

# JTAG

Luckily JTAG mode is already enabled too:

```
$ sunxi-fel readl 0x0300B0B4
0x07373733
```

If that was not the case, we would use `writel` to write that value to the
register.

# Things to do in FEL mode

Apart from the SPI flashing which we did, there are far more important things
FEL can do.
