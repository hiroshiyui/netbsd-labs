FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    zlib1g-dev \
    libssl-dev \
    bison \
    flex \
    texinfo \
    unzip \
    curl \
    git \
    vim \
    mkbootimg \
    cpio \
    && apt-get clean

RUN apt-get update && apt-get install -y locales && \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /work

ENV TMPDIR /work/tmp

CMD ["/bin/bash"]
