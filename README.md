# NetBSD Labs

This repository provides a streamlined environment for cross-compiling the NetBSD operating system using Podman/Docker.

## 1. Prerequisites: Source Code Acquisition

NetBSD uses CVS (Concurrent Versions System) for source control. You need to download the source tree to your local machine before building.

1. **Configure Environment Variables:**
   These variables tell CVS how to connect to the official NetBSD repository.
   ```bash
   export CVSROOT="anoncvs@anoncvs.NetBSD.org:/cvsroot"
   export CVS_RSH=ssh
   ```
2. **Checkout Source Tree:**
   Replace `<TAG>` with a specific release version (e.g., `netbsd-10-0-RELEASE`). This command downloads the source into a directory named `usr/src`.
   ```bash
   cvs checkout -r <TAG> -N -d usr -P src
   ```

## 2. Environment Provisioning

### Build the Development Container Image
To ensure a consistent build environment regardless of your host OS, we use a container.

```bash
podman build -t netbsd-labs .
```

## Run the container

```bash
podman run -it --rm \
  -v "$(pwd)/usr":/work \
  --name my-netbsd-labs \
  netbsd-labs
```

## Working in the container

### Building the NetBSD host compiler toolchain (tools)

```bash
cd /work/src && \
./build.sh -j10 -m evbarm -a aarch64 -U -O ../obj -T ../tools tools
```

### Building the targetd NetBSD ARM64 kernel

```bash
cd /work/src && \
./build.sh -j10 -m evbarm -a aarch64 -U -O ../obj -T ../tools kernel=GENERIC64
```

### Building the whole NetBSD ARM64 system (release)

```bash
cd /work/src && \
./build.sh -j10 -m evbarm -a aarch64 -U -O ../obj -T ../tools release
```
