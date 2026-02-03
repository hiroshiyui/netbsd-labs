# Module 0: Building the EDK II Development Environment

This module outlines the procedure for creating a consistent and isolated build environment for the EFI Development Kit II (EDK II). By leveraging container technology (Podman), this setup guarantees a uniform toolchain (including GCC, NASM, and IASL) across different development machines and prevents modifications to the host system's configuration.

## Prerequisites

Before proceeding, ensure you have a functional Podman installation on your system.

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
