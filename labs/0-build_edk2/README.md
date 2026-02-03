# Module 0: Building the EDK II Development Environment

This module outlines the procedure for creating a consistent and isolated build environment for the EFI Development Kit II (EDK II). By leveraging container technology (Podman), this setup guarantees a uniform toolchain (including GCC, NASM, and IASL) across different development machines. This approach ensures build reproducibility, eliminates "works on my machine" issues, and prevents modifications to the host system's configuration.

## Prerequisites

Before proceeding, ensure you have the following software installed on your host system:

*   A functional [Podman](https://podman.io/getting-started/installation) installation.
*   [QEMU](https://www.qemu.org/download/), specifically the `qemu-system-aarch64` binary for running the compiled firmware.

## Environment Setup

### 1. Initialize Git Submodules

The EDK II project incorporates several external libraries and components, such as OpenSSL for cryptographic functions and Mbed TLS for security protocols, which are managed as Git submodules. To ensure all necessary code is available, you must initialize and recursively update these submodules.

Execute the following command from the root of the repository:

```bash
git submodule update --init --recursive
```

This command initializes any uninitialized submodules and clones the required revisions of their respective repositories.

### 2. Build the Development Container Image

The provided `Containerfile` defines a container image that encapsulates all necessary build tools and dependencies. Build the image using Podman:

```bash
podman build --squash-all -t edk2-build .
```

**Command Breakdown:**
*   `podman build`: The standard command to build a container image.
*   `--squash-all`: This option optimizes the resulting image by squashing all layers into a single new layer, reducing its final size. This is particularly useful for environments where storage is a concern.
*   `-t edk2-build`: Tags the newly created image with the name `edk2-build` for easy reference in subsequent commands.
*   `.`: Specifies that the build context (including the `Containerfile`) is the current directory.

### 3. Launch the Interactive Development Container

Once the image is built, you can launch an interactive container to begin development. This provides an isolated shell environment with the EDK II source code mounted and ready for compilation.

```bash
podman run -it --rm \
  -v "$(pwd)":/work \
  --name my-edk2-build \
  edk2-build
```

**Command Breakdown:**
*   `podman run`: The command to start a new container from an image.
*   `-it`: Allocates an interactive pseudo-TTY, providing a shell prompt inside the container.
*   `--rm`: Automatically removes the container's filesystem when it exits, which is ideal for temporary development sessions.
*   `-v "$(pwd)":/work`: Mounts the current working directory from the host (`$(pwd)`) into the `/work` directory inside the container. This allows you to edit files on your host machine and compile them inside the container without needing to copy them back and forth.
*   `--name my-edk2-build`: Assigns a convenient name to the running container instance for easier management (e.g., `podman stop my-edk2-build`).
*   `edk2-build`: Specifies the image to use for creating the container.

You are now in a shell environment within the container, ready to proceed with the EDK II build process.

## Building EDK II

Once inside the container, you are ready to compile the EDK II source code. This involves setting up the build environment and then invoking the main build tool.

### 1. Build the BaseTools

The EDK II build system relies on a set of host-based utilities known as `BaseTools` for tasks like generating firmware files and processing configuration data. These tools must be compiled first using the compiler within the container.

```bash
cd ./edk2/ && \
make -C BaseTools
```

### 2. Configure the Build Environment

The `edksetup.sh` script prepares the shell environment by setting necessary variables.

From the `/work` directory inside the container, source the script:

```bash
source edk2/edksetup.sh
```

### 3. Compile the Firmware

With the environment configured, you can now compile a target platform. We will use `ArmVirtPkg` as an example, which is designed for QEMU ARM-based virtual machines. The toolchain prefix needs to be set to match the cross-compiler installed in the container.

```bash
export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
build -a AARCH64 -t GCC5 -p ArmVirtPkg/ArmVirtQemu.dsc -b DEBUG
```

**Command Breakdown:**
*   `export GCC5_AARCH64_PREFIX=...`: This environment variable tells the EDK II build system where to find the AARCH64 cross-compiler.
*   `build`: The primary EDK II build script.
*   `-a AARCH64`: Specifies the target architecture.
*   `-t GCC5`: Defines the toolchain profile to use (GCC version 5 or compatible).
*   `-p ArmVirtPkg/ArmVirtQemu.dsc`: Points to the platform description (`.dsc`) file, which dictates which components are included in the final firmware.
*   `-b DEBUG`: Specifies a debug build, which includes extra symbols and information useful for development. For release builds, you would use `-b RELEASE`.

After a successful build, the resulting firmware artifacts will be located in the `edk2/Build/ArmVirtQemu-AArch64/DEBUG_GCC5/FV/` directory. The primary output file is typically `QEMU_EFI.fd`.

## Running the Firmware with QEMU

After successfully building the firmware, you can test it by running it in QEMU. This allows you to boot a virtual machine using your compiled firmware.

### Execute QEMU on the host system (not in the development container)

From the project root, run the following command:

```bash
qemu-system-aarch64 \
  -M virt \
  -cpu cortex-a57 \
  -m 1024 \
  -bios edk2/Build/ArmVirtQemu-AArch64/DEBUG_GCC5/FV/QEMU_EFI.fd \
  -nographic \
  -serial pty
```

Attach the serial console by running `screen` such as `screen /dev/pts/3`.
