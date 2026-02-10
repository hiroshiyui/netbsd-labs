# Module 2: Build NetBSD for Raspberry Pi 1 Model B

This guide details the process of building a complete NetBSD system for the Raspberry Pi 1 Model B.

## 1. Development Environment

### Prerequisites

Before you begin, ensure you have set up the development environment as described in the main [README.md](../../README.md). This includes fetching the required source code and initializing the environment with:

```bash
# From the project root directory
source ./envsetup.sh
```

### Launching the Build Container

This lab includes a `Makefile` to simplify container management.

1.  **Build the container image:**
    ```bash
    make build-dev-container
    ```

2.  **Launch the container:**
    ```bash
    make run-container
    ```

3.  **Change directory to the NetBSD source tree:**
    ```bash
    cd /work/src
    ```

You will now be in a shell inside the container, at the `/work/src` directory, which is the NetBSD source tree. All subsequent build commands should be run from this directory.

## 2. Building the System

The NetBSD build process is orchestrated by the `./build.sh` script. We will build the toolchain, kernel, and userland (world) in separate steps.

### Build Parameters Explained

The commands below use several common flags:

-   `-j10`: Specifies the number of parallel jobs to run (adjust based on your CPU cores).
-   `-m evbarm`: Sets the target machine architecture to `evbarm`.
-   `-a earmv6hf`: Specifies the ARM architecture variant for the Raspberry Pi 1B.
-   `-U`: Disables building as a privileged user (important for container builds).
-   `-O ../obj`: Sets the output directory for build artifacts to `/work/obj`.
-   `-T ../tools`: Specifies the location of the cross-compilation toolchain.

### Step 1: Build the Cross-Compilation Toolchain

This command builds the compilers and other tools needed to cross-compile NetBSD for ARM from an x86 host.

```bash
./build.sh -j10 -m evbarm -a earmv6hf -U -O ../obj -T ../tools tools
```

### Step 2: Build the Kernel

This builds the NetBSD kernel using the `RPI` configuration, which is tailored for the Raspberry Pi.

```bash
./build.sh -j10 -m evbarm -a earmv6hf -U -O ../obj -T ../tools kernel=RPI
```

### Step 3: Build the World and Create the Release

This builds all userland programs and libraries ("the world") and packages them into a release structure.

```bash
./build.sh -j10 -m evbarm -a earmv6hf -U -O ../obj -T ../tools release
```

## 3. Generating and Writing the SD Card Image

### Step 4: Check the Created Disk Image

After the release is built, a compressed bootable disk image (`.img`) file should be created at `/work/obj/releasedir/evbarm-earmv6hf/binary/gzimg/rpi.img.gz`

```bash
ls /work/obj/releasedir/evbarm-earmv6hf/binary/gzimg/
# A valid output should be similar to the following:
rpi.img.gz  rpi_inst.img.gz
```

### Writing the Image to an SD Card

After the image is generated, exit the container. The image is accessible from the host machine at:
```bash
$LABSROOT/usr/obj/releasedir/evbarm-earmv6hf/binary/gzimg/rpi.img.gz
```

Use the `dd` utility to write the image to your SD card.

> **⚠️ WARNING: DATA LOSS RISK**
>
> This command will completely overwrite the target device. **Double-check your device path** with `lsblk` or a similar utility before proceeding. An incorrect path can lead to permanent data loss on your host system.

```bash
# Replace /dev/sdX with your SD card's device path
zcat $LABSROOT/usr/obj/releasedir/evbarm-earmv6hf/binary/gzimg/rpi.img.gz | sudo dd of=/dev/sdX bs=1M status=progress conv=fsync
```

### Expand filesystem to maximum available capacity

By default, the generated image has a fixed size. To utilize the full capacity of your SD card, you can use the `resize_ffs` utility on the first boot or from another NetBSD system.

1.  **Boot the Raspberry Pi** with the newly created SD card.
2.  **Run the following commands** as root:
    ```bash
    # Grow the partition in the disklabel (if necessary)
    # Then resize the filesystem
    service resize_root start
    ```
    *Note: NetBSD's `resize_root` rc.d script can automate this process if `resize_root=YES` is set in `/etc/rc.conf`.*

## 4. Troubleshooting

Here are some common issues and solutions.

### Missing Firmware Files

-   **Symptom:** The Raspberry Pi does not boot at all; the screen remains blank and the activity LED shows no disk access.
-   **Cause:** The Raspberry Pi requires proprietary firmware files (`bootcode.bin`, `start.elf`, etc.) on the FAT32 boot partition. While the build process attempts to include them, they may be outdated or missing.
-   **Solution:** Manually download the latest firmware from the [Raspberry Pi Firmware Repository](https://github.com/raspberrypi/firmware/tree/master/boot) and copy the `.bin` and `.elf` files to the first partition (labeled `MS-DOS`) of the SD card, overwriting any existing files.

### No Video Output (HDMI)

-   **Symptom:** The board boots (activity LED blinks), but there is no output on the connected HDMI monitor.
-   **Cause:** The Raspberry Pi may not be detecting the HDMI monitor correctly and is falling back to composite video or has disabled video output.
-   **Solution:** Mount the first partition of the SD card and edit the `config.txt` file. Add or uncomment the following lines to force HDMI output:
    ```ini
    # Force HDMI even if no monitor is detected
    hdmi_force_hotplug=1

    # Use standard HDMI mode (for video and audio) instead of DVI (video only)
    hdmi_drive=2
    ```

### Accessing the Serial Console

-   **Symptom:** You have no HDMI display or want to see early boot messages for debugging.
-   **Cause:** The default kernel configuration often uses the serial port as the primary console.
-   **Solution:** Connect a USB-to-TTL serial adapter to the Raspberry Pi's GPIO pins (Pin 6 - GND, Pin 8 - TXD, Pin 10 - RXD). Use a terminal emulator on your host machine to connect.
    ```bash
    # Connect to the serial device at 115200 baud
    screen /dev/ttyUSB0 115200
    ```
