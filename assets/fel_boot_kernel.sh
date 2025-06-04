#!/bin/sh

# Sunxi FEL mode boot script
#
# Copyright (C) 2025 Andre Przywara (https://gist.github.com/apritzel)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# ADJUST to match your setup
INITRD=/srv/tftp/busybox.initrd.gz
UBOOT_DIR=/src/u-boot.git

if [ $# -eq 0 -o "$1" = "-h" ]
then
	echo "usage: %0 <kernel.img> [<cmdline>]"
	exit 0
fi

kernel="$1"
shift

if [ $# -lt 1 ]
then
	cmdline="console=ttyS0,115200n8 earlycon"
else
	cmdline="$1"
	shift
fi

ramdisk_size=$(stat -c %s "$INITRD" | rax2 -)

tmpf="/tmp/bootscript.$$"

echo "setenv bootargs \"$cmdline\"" > $tmpf
echo "booti \$kernel_addr_r \$ramdisk_addr_r:$ramdisk_size \$fdtcontroladdr" >> $tmpf

mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "boot script" -d $tmpf ${tmpf}.img > /dev/null

$ECHO sunxi-fel -v -p uboot $UBOOT_DIR/u-boot-sunxi-with-spl.bin write 0x40080000 "$kernel" write 0x4ff00000 "$INITRD" write 0x4fe00000 ${tmpf}.img

rm -f $tmpf ${tmpf}.img
