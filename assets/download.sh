#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DOWNLOAD_DIR=$(realpath $SCRIPT_DIR/../extern)
QEMU_IMG=$(realpath $SCRIPT_DIR/../q)/qemu-img
mkdir -p $DOWNLOAD_DIR
echo Downloading files to $DOWNLOAD_DIR...

FILE=$DOWNLOAD_DIR/buildroot-2025.02.3.tar.xz
if [ -f $FILE ]; then
    if [ "$(sha256sum $FILE | awk '{print $1}')" != "dc158b904f84c75289f26ecfd30521d3f5955afeca921c810b808be73c232da9" ]; then
        rm $FILE
    fi
fi
if [ ! -f $FILE ]; then
    wget -O $FILE https://buildroot.org/downloads/buildroot-2025.02.3.tar.xz
fi

FILE=$DOWNLOAD_DIR/Orangepipc_2.0.8_debian_buster_server_linux5.4.65.7z
if [ -f $FILE ]; then
    if [ "$(sha256sum $FILE | awk '{print $1}')" != "527f74f1003289b61c9c536d22ad01d1fa1df78ace65b461a44f45fd8fdb6a38" ]; then
        rm $FILE
    fi
fi
if [ ! -f $FILE ]; then
    wget -O $FILE https://electricworry.net/Orangepipc_2.0.8_debian_buster_server_linux5.4.65.7z
fi

FILE=$DOWNLOAD_DIR/Orangepizero3_1.0.4_debian_bookworm_server_linux6.1.31.7z
if [ -f $FILE ]; then
    if [ "$(sha256sum $FILE | awk '{print $1}')" != "bfbe35d89164329402990e8ceb93c94cdff69020f89a44b7cfbfefb73bfb7249" ]; then
        rm $FILE
    fi
fi
if [ ! -f $FILE ]; then
    wget -O $FILE https://electricworry.net/Orangepizero3_1.0.4_debian_bookworm_server_linux6.1.31.7z
fi

FILE=$DOWNLOAD_DIR/Orangepipc_2.0.8_debian_buster_server_linux5.4.65.img
if [ ! -f $FILE ]; then
    7z x -o$DOWNLOAD_DIR $(echo $FILE | sed 's/img$/7z/')
    $QEMU_IMG resize $FILE 2G
fi

FILE=$DOWNLOAD_DIR/Orangepizero3_1.0.4_debian_bookworm_server_linux6.1.31.img
if [ ! -f $FILE ]; then
    7z x -o$DOWNLOAD_DIR $(echo $FILE | sed 's/img$/7z/')
    $QEMU_IMG resize $FILE 4G
fi
