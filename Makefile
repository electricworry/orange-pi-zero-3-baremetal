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
	q/qemu-system-aarch64 -M orangepi-zero3 -nographic \
		-sd extern/Orangepizero3_1.0.4_debian_bookworm_server_linux6.1.31.img

# QEMU: full
qemu-kern-h616: q/qemu-system-aarch64
	@echo "[\`Ctrl-A x\` to terminate]"
	q/qemu-system-aarch64 -M orangepi-zero3 -D ./log.txt -d unimp -nographic \
		-kernel $(OPZ3_ARTIFACT_DIR)/Image \
		-append 'console=ttyS0,115200 root=/dev/mmcblk0p1 earlycon' \
		-dtb $(OPZ3_ARTIFACT_DIR)/sun50i-h618-orangepi-zero3.dtb \
		-initrd $(OPZ3_ARTIFACT_DIR)/initrd.img-6.1.31-sun50iw9 \
		-sd extern/Orangepizero3_1.0.4_debian_bookworm_server_linux6.1.31.img

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

extract-artefacts: download-extern
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
	mountpoint -q /mnt/orange-pi-pc && sudo umount /mnt/orange-pi-pc

mount-orange-pi-zero-3: download-extern
	mountpoint -q /mnt/orange-pi-zero-3 || ( \
		sudo mkdir -p /mnt/orange-pi-zero-3 && \
		sudo mount -o loop,offset=$$((8192 * 512)) \
			extern/Orangepizero3_1.0.4_debian_bookworm_server_linux6.1.31.img \
			/mnt/orange-pi-zero-3 \
	)

umount-orange-pi-zero-3:
	mountpoint -q /mnt/orange-pi-zero-3 && sudo umount /mnt/orange-pi-zero-3

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

fel-boot:
	sunxi-fel -v uboot u-boot/u-boot-sunxi-with-spl.bin \
		write 0x40080000 linux/arch/arm64/boot/Image \
		write 0x4FF00000 buildroot-2025.02.3/output/images/rootfs.cpio.uboot
