# Module 1: Booting NetBSD ARM64 System from UEFI

This module demonstrates how to bridge the EDK II firmware built in Module 0 with the NetBSD distribution built in the root project. We will use the UEFI-ready disk image provided by the NetBSD build system.

## 1. Prepare and Verify the NetBSD ARM64 Disk Image

First, extract the pre-built GPT disk image. This image contains both an EFI System Partition (ESP) and the NetBSD root partition.

```bash
# Ensure you have defined $LABS_M1_ROOT and $LABSROOT in your environment (run `source ./envsetup.sh` from project root directory)
cd $LABS_M1_ROOT && \
gunzip -c $LABSROOT/usr/obj/releasedir/evbarm-aarch64/binary/gzimg/arm64.img.gz > netbsd_arm64.img && \
/sbin/sgdisk -p netbsd_arm64.img
```

A valid output should look something like this:

```
Disk netbsd_arm64.img: 2443264 sectors, 1.2 GiB
Sector size (logical): 512 bytes
Disk identifier (GUID): F772076F-E96C-4774-9542-32B1152608AA
Partition table holds up to 16 entries
Main partition table begins at sector 2 and ends at sector 5
First usable sector is 6, last usable sector is 2443258
Partitions will be aligned on 2048-sector boundaries
Total free space is 34805 sectors (17.0 MiB)

Number  Start (sector)    End (sector)  Size       Code  Name
   1           32768          196607   80.0 MiB    EF00  EFI
   2          196608         2441215   1.1 GiB     A902  netbsd-root
```

## Booting the NetBSD ARM64 system with UEFI under QEMU

```bash
cd $LABS_M1_ROOT && \
qemu-system-aarch64 \
    -M virt \
    -cpu cortex-a57 \
    -m 2048 \
    -bios $LABS_M0_ROOT/edk2/Build/ArmVirtQemu-AArch64/DEBUG_GCC5/FV/QEMU_EFI.fd \
    -drive if=none,file=./netbsd_arm64.img,id=hd0,format=raw \
    -device virtio-blk-device,drive=hd0 \
    -object rng-random,filename=/dev/urandom,id=rng0 \
    -device virtio-rng-pci,rng=rng0 \
    -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
    -nographic \
    -serial pty
```

Attach the serial console by running `screen` such as `screen /dev/pts/3`. Or using `minicom` like `minicom -b 115200 -p /dev/pts/3`.
