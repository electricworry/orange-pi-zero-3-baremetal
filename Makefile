################
# QEMU targets #
################

OPPC_ARTIFACT_DIR := extern/orange-pi-pc
OPZ3_ARTIFACT_DIR := extern/orange-pi-zero-3

.PHONY: qemu-kernel-only q/qemu-system-arm q/qemu-system-aarch64

# QEMU: kernel-only with no machine specified
qemu-kernel-only-h616: q/qemu-system-aarch64
	@echo "[\`Ctrl-A x\` to terminate]"
	q/qemu-system-aarch64 \
		-M virt \
		-cpu cortex-a57 \
		-kernel $(OPZ3_ARTIFACT_DIR)/Image \
		-serial mon:stdio

# QEMU: image-only
qemu-img-h616: q/qemu-system-aarch64
	@echo "[\`Ctrl-A x\` to terminate]"
	q/qemu-system-aarch64 -M orangepi-zero3  -D ./log.txt -d unimp -nographic \
		-sd extern/Orangepizero3_1.0.4_debian_bookworm_server_linux6.1.31.img

# QEMU: full - orangepi
aaa: q/qemu-system-aarch64
	@echo "[\`Ctrl-A x\` to terminate]"
	q/qemu-system-aarch64 -M orangepi-zero3 -D ./log.txt -d unimp -nographic \
		-kernel $(OPZ3_ARTIFACT_DIR)/Image \
		-append 'loglevel=8 console=ttyS0,115200 root=/dev/mmcblk0p1 earlycon' \
		-dtb $(OPZ3_ARTIFACT_DIR)/sun50i-h618-orangepi-zero3.dtb \
		-initrd $(OPZ3_ARTIFACT_DIR)/initrd.img-6.1.31-sun50iw9 \
		-sd extern/Orangepizero3_1.0.4_debian_bookworm_server_linux6.1.31.img

# QEMU: full - mainline
bbb: q/qemu-system-aarch64
	@echo "[\`Ctrl-A x\` to terminate]"
	q/qemu-system-aarch64 -M orangepi-zero3 -s -S -D ./log.txt -d unimp -nographic \
		-kernel linux/arch/arm64/boot/Image \
		-append 'core.dyndbg="file * +pflm" of_regulator.dyndbg="file * +pflm" pinmux.dyndbg="file * +pflm" loglevel=8 console=ttyS0,115200 root=/dev/mmcblk0p1 earlycon' \
		-dtb linux/arch/arm64/boot/dts/allwinner/sun50i-h618-orangepi-zero3.dtb \
		-initrd buildroot-2025.02.3/output/images/rootfs.cpio.lzma \
		-sd extern/Orangepizero3_1.0.4_debian_bookworm_server_linux6.1.31.img

# QEMU: full - armbian
ccc: q/qemu-system-aarch64
	@echo "[\`Ctrl-A x\` to terminate]"
	q/qemu-system-aarch64 -M orangepi-zero3 -D ./log.txt -d unimp -nographic \
		-kernel extern/armbian/Image \
		-append 'loglevel=8 console=ttyS0,115200 root=/dev/mmcblk0p1 earlycon' \
		-dtb extern/armbian/sun50i-h618-orangepi-zero3.dtb \
		-initrd extern/armbian/initrd.img-6.15.0-edge-sunxi64 \
		-sd armbian-build/output/images/Armbian-unofficial_25.08.0-trunk_Orangepizero3_bookworm_edge_6.15.0_minimal.img

# QEMU: image-only
qemu-img-h3: q/qemu-system-arm
	@echo "[\`Ctrl-A x\` to terminate]"
	q/qemu-system-arm -M orangepi-pc -nographic \
 		-sd extern/Orangepipc_2.0.8_debian_buster_server_linux5.4.65.img

# QEMU: full
qemu-kern-h3: q/qemu-system-arm
	@echo "[\`Ctrl-A x\` to terminate]"
	q/qemu-system-arm -M orangepi-pc -D ./log.txt -d unimp -nographic \
		-kernel $(OPPC_ARTIFACT_DIR)/zImage \
		-append 'console=ttyS0,115200 root=/dev/mmcblk0p1 earlycon' \
		-dtb $(OPPC_ARTIFACT_DIR)/sun8i-h3-orangepi-pc.dtb \
		-initrd $(OPPC_ARTIFACT_DIR)/initrd.img-5.4.65-sunxi \
		-sd extern/Orangepipc_2.0.8_debian_buster_server_linux5.4.65.img

##############
# QEMU setup #
##############

.PHONY: download-extern extract-artefacts mount-orange-pi-pc umount-orange-pi-pc mount-orange-pi-zero-3 umount-orange-pi-zero-3

download-extern: q/qemu-img
	assets/download.sh

extract-artefacts: mount-orange-pi-pc mount-orange-pi-zero-3
	mkdir -p $(OPZ3_ARTIFACT_DIR)
	cp /mnt/orange-pi-zero-3/boot/Image                                        $(OPZ3_ARTIFACT_DIR)
	cp /mnt/orange-pi-zero-3/boot/initrd.img-6.1.31-sun50iw9                   $(OPZ3_ARTIFACT_DIR)
	cp /mnt/orange-pi-zero-3/boot/dtb/allwinner/sun50i-h618-orangepi-zero3.dtb $(OPZ3_ARTIFACT_DIR)
	mkdir -p $(OPPC_ARTIFACT_DIR)
	cp /mnt/orange-pi-pc/boot/zImage                       $(OPPC_ARTIFACT_DIR)
	cp /mnt/orange-pi-pc/boot/initrd.img-5.4.65-sunxi      $(OPPC_ARTIFACT_DIR)
	cp /mnt/orange-pi-pc/boot/dtb/sun8i-h3-orangepi-pc.dtb $(OPPC_ARTIFACT_DIR)

q/Makefile:
	mkdir -p q
	cd q && \
		../qemu/configure --target-list="aarch64-softmmu arm-softmmu"

q/qemu-img q/qemu-system-arm q/qemu-system-aarch64: q/Makefile
	cd q && make -j`nproc`

mount-orange-pi-pc: download-extern
	mountpoint -q /mnt/orange-pi-pc || ( \
		sudo mkdir -p /mnt/orange-pi-pc && \
		sudo mount -o loop,offset=$$((8192 * 512)) \
			extern/Orangepipc_2.0.8_debian_buster_server_linux5.4.65.img \
			/mnt/orange-pi-pc \
	)

umount-orange-pi-pc:
	-mountpoint -q /mnt/orange-pi-pc && sudo umount /mnt/orange-pi-pc
	if [ -d /mnt/orange-pi-pc ]; then \
		sudo rmdir /mnt/orange-pi-pc; \
	fi

mount-orange-pi-zero-3: download-extern
	mountpoint -q /mnt/orange-pi-zero-3 || ( \
		sudo mkdir -p /mnt/orange-pi-zero-3 && \
		sudo mount -o loop,offset=$$((8192 * 512)) \
			extern/Orangepizero3_1.0.4_debian_bookworm_server_linux6.1.31.img \
			/mnt/orange-pi-zero-3 \
	)

umount-orange-pi-zero-3:
	-mountpoint -q /mnt/orange-pi-zero-3 && sudo umount /mnt/orange-pi-zero-3
	if [ -d /mnt/orange-pi-zero-3 ]; then \
		sudo rmdir /mnt/orange-pi-zero-3; \
	fi

############
# Physical #
############

console:
		tio /dev/ttyUSB1

run-openocd-orange-pi-zero-3: build/src/openocd
		build/src/openocd -f config/interface/ft2232h.cfg -f config/board/orange_pi_zero_3.cfg

build/src/openocd:
	cd openocd && \
		./bootstrap
	mkdir -p o && cd o && \
		../openocd/configure && \
		make -j

# FEL mode boot - around 45s to upload to device
fel-boot:
	sed s/RAMDISK_SIZE/$$(stat -c %s "buildroot-2025.02.3/output/images/rootfs.cpio.uboot" | rax2 -)/ assets/bootscript.cmd > ./bootscript.cmd
	mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "boot script" -d bootscript.cmd bootscript.scr
	sunxi-fel -v uboot u-boot/u-boot-sunxi-with-spl.bin \
		write 0x40080000 linux/arch/arm64/boot/Image.gz \
		write 0x4FF00000 buildroot-2025.02.3/output/images/rootfs.cpio.uboot \
    	write 0x4FC00000 bootscript.scr
