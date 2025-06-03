FROM mcr.microsoft.com/devcontainers/base:noble

RUN yes | unminimize
RUN apt update
RUN apt install -y apt-file && apt-file update

# Install cross-compilers
RUN apt install -y \
    gcc-aarch64-linux-gnu

# Install U-Boot dependencies
RUN apt install -y \
    bc bison build-essential coccinelle \
    device-tree-compiler dfu-util efitools flex gdisk graphviz imagemagick \
    liblz4-tool libgnutls28-dev libguestfs-tools libncurses-dev \
    libpython3-dev libsdl2-dev libssl-dev lz4 lzma lzma-alone openssl \
    pkg-config python3 python3-asteval python3-coverage python3-filelock \
    python3-pkg-resources python3-pycryptodome python3-pyelftools \
    python3-pytest python3-pytest-xdist python3-sphinxcontrib.apidoc \
    python3-sphinx-rtd-theme python3-subunit python3-testtools \
    python3-virtualenv swig uuid-dev

# Install other stuff
RUN apt install -y \
    python-is-python3 \
    binwalk \
    u-boot-tools \
    ncdu \
    ninja-build \
    python3-venv \
    python3-pip
