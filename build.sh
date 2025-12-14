≈#!/bin/bash
# SimpleOS Build Script

echo "========================================"
echo "   SimpleOS v2.0 Build System"
echo "========================================"

# Step 1: Assemble bootloader
echo "[1/4] Assembling bootloader..."
nasm -f bin boot.asm -o boot.bin
if [ $? -ne 0 ]; then
    echo "ERROR: Bootloader assembly failed!"
    exit 1
fi
echo "      boot.bin created ($(stat -f%z boot.bin 2>/dev/null || stat -c%s boot.bin) bytes)"

# Step 2: Assemble kernel
echo "[2/4] Assembling kernel..."
nasm -f bin kernel.asm -o kernel.bin
if [ $? -ne 0 ]; then
    echo "ERROR: Kernel assembly failed!"
    exit 1
fi
echo "      kernel.bin created ($(stat -f%z kernel.bin 2>/dev/null || stat -c%s kernel.bin) bytes)"

# Step 3: Create disk image
echo "[3/4] Creating disk image..."
dd if=/dev/zero of=os.img bs=512 count=2880 status=none
dd if=boot.bin of=os.img bs=512 count=1 conv=notrunc status=none
dd if=kernel.bin of=os.img bs=512 seek=1 conv=notrunc status=none
echo "      os.img created (1.44 MB floppy image)"

# Step 4: Run in QEMU
echo "[4/4] Starting QEMU..."
echo ""
echo "========================================"
echo "   OS is running! Try these commands:"
echo "   HELP, LIST, CLEAR, ECHO, TIME,"
echo "   DATE, COLOR, PEEK, POKE, REBOOT"
echo "========================================"
echo ""

qemu-system-i386 -fda os.img
