# SimpleOS

A minimal 16-bit operating system written in x86 assembly with 13 functions including a RAM-based file system.

## 🖥️ Features

- **13 Commands**: HELP, LIST, CLEAR, ECHO, TIME, DATE, PEEK, POKE, REBOOT, CREATE, DELETE, RENAME, FILES
- **Custom Bootloader**: Loads kernel from disk on boot
- **Command-Line Shell**: Interactive text-based interface
- **File System**: In-memory file storage (8 files, 64 bytes each)
- **Memory Operations**: Direct memory read/write (PEEK/POKE)
- **Real-Time Clock**: System time and date via BIOS interrupts
- **Direct Video Memory**: VGA text mode manipulation

## 📋 System Requirements

- macOS (Apple Silicon or Intel)
- NASM (Netwide Assembler)
- QEMU
- Terminal

## 🚀 Build & Run (macOS)

### Step 1: Install Homebrew

Run the official installer:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Step 2: Install NASM and QEMU

Install required tools for assembling and running the OS:

```bash
brew install nasm qemu
```

Verify installation:

```bash
nasm --version
qemu-system-i386 --version
```

### Step 3: Clone Repository

```bash
git clone https://github.com/yourusername/simpleos-x86.git
cd simpleos-x86
```

### Step 4: Navigate to Project Directory

```bash
cd ~/Desktop/my_os
ls
```

### Step 5: Make Build Script Executable

```bash
chmod +x build.sh
```

### Step 6: Build and Run

Execute the script that builds and launches your OS:

```bash
./build.sh
```

The OS will automatically launch in QEMU!

## 💻 Available Commands

Once SimpleOS boots, try these commands:

### System Information
```
HELP          - Show all available commands
LIST          - Display system information
CLEAR         - Clear the screen
ECHO <text>   - Print text to screen
```

### Time & Date
```
TIME          - Show current system time
DATE          - Show current date
```

### Memory Operations
```
PEEK <addr>   - Read byte from memory (hex)
POKE <a> <v>  - Write byte to memory (hex)
```

### File System
```
CREATE <n> <content>  - Create new file
FILES                 - List all files
RENAME <old> <new>    - Rename a file
DELETE <name>         - Delete a file
```

### System Control
```
REBOOT        - Restart the computer
```

## 🛠️ Manual Build

If you want to build manually without the script:

```bash
# Compile bootloader
nasm -f bin boot.asm -o boot.bin

# Compile kernel
nasm -f bin kernel.asm -o kernel.bin

# Create OS image
cat boot.bin kernel.bin > os.img

# Pad to floppy size
dd if=/dev/zero bs=512 count=2880 >> os.img 2>/dev/null

# Run in QEMU
qemu-system-x86_64 os.img
```

## 📁 Project Structure

```
simpleos-x86/
├── boot.asm       # Bootloader (512 bytes)
├── kernel.asm     # Kernel with all 13 functions
├── build.sh       # Build script
├── boot.bin       # Compiled bootloader (generated)
├── kernel.bin     # Compiled kernel (generated)
├── os.img         # Final disk image (generated)
└── README.md      # This file
```

## 🔧 Troubleshooting

### Problem: "operation not permitted"

**Solution:**
```bash
xattr -d com.apple.quarantine build.sh
chmod +x build.sh
./build.sh
```

### Problem: Command not found (nasm/qemu)

**Solution:**
```bash
# Add Homebrew to PATH (Apple Silicon)
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Reinstall
brew install nasm qemu
```

### Problem: QEMU warning about raw image

**Solution:** This warning is harmless. To suppress it:
```bash
qemu-system-x86_64 -drive file=os.img,format=raw
```

## 📊 Technical Specifications

- **Language**: x86 Assembly (NASM syntax)
- **Architecture**: 16-bit Real Mode
- **Total Lines**: 1,333 lines
  - boot.asm: 97 lines
  - kernel.asm: 1,236 lines
- **Boot Sector**: 512 bytes at 0x7C00
- **Kernel Size**: 4096 bytes (8 sectors) at 0x1000
- **Video Mode**: VGA 80x25 Text Mode

## 🔄 Exiting QEMU

To exit the emulator:
- Close the QEMU window, or
- Press `Ctrl + C` in terminal

