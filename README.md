# NetBSD Labs: A Containerized Cross-Compilation Environment

This repository provides a streamlined, container-based environment for cross-compiling the [NetBSD](https://www.netbsd.org/) operating system.ating system. By leveraging a container engine like [Podman](https://podman.io/) or [Docker](https://www.docker.com/), you can build NetBSD for various target architectures (e.g., ARM64/AArch64) without managing complex dependencies or altering your host system's configuration. This approach ensures a consistent, reproducible build process across different Linux distributions.

This guide also provides instructions for emulating the resulting NetBSD ARM64 system using [QEMU](https://www.qemu.org/).

## 1. Prerequisites: Fetching the Source Code

NetBSD's official source code is managed using **CVS** (Concurrent Versions System). While many modern projects use Git, CVS remains the authoritative system for the NetBSD project. The following steps detail how to check out the source code securely.

### Configure Environment Variables

Set the following variables to instruct CVS to connect to the official NetBSD anonymous mirror over SSH.

```bash
export CVSROOT="anoncvs@anoncvs.NetBSD.org:/cvsroot"
export CVS_RSH=ssh
```

Run `source ./envsetup.sh` to load predefined paths.

### Check Out the Source Tree

This command checks out the NetBSD source code into `usr/src`, which is the standard directory structure required by the build system.

Replace `<TAG>` with a specific release tag (e.g., `netbsd-10-0-RELEASE`) or use `-A` for the latest cutting-edge (`-current`) sources.

```bash
# Example for a specific release:
cvs checkout -r netbsd-10-0-RELEASE -N -d usr -P src

# Example for the latest development branch:
# cvs checkout -A -N -d usr -P src
```

## 2. Setting Up the Containerized Build Environment

To ensure build reproducibility and encapsulate all necessary dependencies, we will use the provided `Containerfile`.

### Build the Container Image

This command builds a container image named `netbsd-labs` using the instructions in the `Containerfile`.

```bash
podman build -t netbsd-labs .
```

### Launch the Build Container

This command starts an interactive session inside the build container. The `-v` flag mounts the local `./usr` directory (containing the source code) into the `/work` directory inside the container, allowing the build scripts to access it.

```bash
podman run -it --rm \
  -v "$(pwd)/usr":/work \
  --name my-netbsd-labs \
  netbsd-labs
```
*All subsequent build commands should be run from within this container's shell.*

## 3. Building the NetBSD System

The NetBSD build process is orchestrated by a powerful shell script, `build.sh`. The following commands are run from the `/work/src` directory inside the container.

**Understanding the Build Flags:**
*   `-j10`: Specifies the number of parallel jobs to run (e.g., 10). Adjust based on your CPU cores.
*   `-m evbarm`: Sets the target machine architecture. `evbarm` is a generic board-support package for ARM platforms.
*   `-a aarch64`: Defines the specific CPU architecture (64-bit ARM).
*   `-U`: Disables building as a privileged user, which is a safe practice.
*   `-O ../obj`: Specifies the output directory for all compiled objects.
*   `-T ../tools`: Specifies the location of the host toolchain to be used for the build.

### Step 1: Build the Cross-Compilation Toolchain

This initial step compiles the compilers, linkers, and other tools that run on the host (inside the container) but produce binaries for the target architecture (`aarch64`).

```bash
cd /work/src && \
./build.sh -j10 -m evbarm -a aarch64 -U -O ../obj -T ../tools tools
```

### Step 2: Build the Kernel

With the toolchain ready, this command compiles the NetBSD kernel for the target system. `GENERIC64` is a standard kernel configuration with broad hardware support.

```bash
cd /work/src && \
./build.sh -j10 -m evbarm -a aarch64 -U -O ../obj -T ../tools kernel=GENERIC64
```

### Step 3: Build the World and Release

This final command builds all userland components (libraries, utilities) and packages everything, including the kernel, into a complete release in the `../obj/releasedir` directory.

```bash
cd /work/src && \
./build.sh -j10 -m evbarm -a aarch64 -U -O ../obj -T ../tools release
```

## 4. Emulating the System with QEMU

After the build completes, you can exit the container. The following steps are performed on your host machine to prepare a disk image and run the emulated system.

### Step 1: Prepare the Root Filesystem

First, create a directory to serve as the root filesystem. Then, extract the core `base` and `etc` sets from the release into this directory.

```bash
mkdir -p /work/rootfs_qemu && \
cd /work/ && \
for set in base etc; do
  tar -xpf ./obj/releasedir/evbarm-aarch64/binary/sets/${set}.tar.xz -C ./rootfs_qemu
done
```

### Step 2: Perform Basic System Configuration

Before creating the disk image, we must perform first-boot configuration:
1.  Enable `rc.conf` to signify that the system is configured.
2.  Use the `pwd_mkdb` tool (from our cross-compiled tools) to generate the secure password database from the `master.passwd` file.

```bash
cd /work/ && \
sed -i 's/rc_configured=NO/rc_configured=YES/' ./rootfs_qemu/etc/rc.conf && \
./tools/bin/nbpwd_mkdb -p -d rootfs_qemu ./rootfs_qemu/etc/master.passwd
```

### Step 3: Create the Disk Image

This command uses the `nbmakefs` tool to create a 1 GB filesystem image file, `qemu_disk.img`, populated with the contents of the `rootfs_qemu` directory.

```bash
cd /work/rootfs_qemu && \
../tools/bin/nbmakefs -s 1g ../qemu_disk.img .
```

### Step 4: Launch QEMU

This command starts a QEMU virtual machine to run your newly-built NetBSD system.

```bash
qemu-system-aarch64 -M virt -cpu cortex-a57 -smp 4 -m 2G \
  -kernel ./obj/sys/arch/evbarm/compile/GENERIC64/netbsd.img \
  -drive file=./qemu_disk.img,if=none,id=hd0,format=raw \
  -device virtio-blk-pci,drive=hd0 \
  -netdev user,id=net0 -device virtio-net-device,netdev=net0 \
  -append "root=ld4a console=fb" \
  -serial stdio
```

**Understanding the QEMU Flags:**
*   `-M virt`: Use QEMU's standard ARM 64-bit virtual machine platform.
*   `-cpu cortex-a57`: Emulate a specific, modern CPU core.
*   `-smp 4 -m 2G`: Assign 4 CPU cores and 2 GB of RAM to the VM.
*   `-kernel`: Path to the compiled kernel executable.
*   `-drive`: Defines the disk image file (`qemu_disk.img`) and its properties.
*   `-device`: Attaches the disk defined by `-drive` to the VM's virtio block device driver.
*   `-netdev ... -device ...`: Sets up user-mode networking, allowing the VM to access the host's network.
*   `-append "root=ld4a"`: Kernel boot arguments. This tells the kernel that the root filesystem is on the first partition (`a`) of the `ld4` disk.
*   `-nographic`: Redirects the serial console to the current terminal.

## Troubleshooting

### Missing `/etc/fstab`

If the boot process halts with an error like `Cannot open /etc/fstab`, it's because a default fstab was not included in the base sets for this custom configuration.

Press **Enter** to drop into the single-user emergency shell. Then, run the following commands to create a valid `/etc/fstab` file:

```sh
# Remount the root filesystem as read-write
mount -u -w /dev/ld4a /

# Create the fstab file with standard entries
cat << EOF > /etc/fstab
/dev/ld4a  /      ffs  rw  1 1
/dev/ld4b  none   swap sw  0 0
kernfs     /kern  kernfs rw
ptyfs      /dev/pts ptyfs rw
procfs     /proc  procfs rw
EOF
```

After creating the file, type `exit` and press **Enter**. The boot process will now resume normally.
