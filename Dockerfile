FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    curl \
    xz-utils \
    git \
    build-essential \
    gdb \
    strace \
    file \
    less \
    vim \
    && rm -rf /var/lib/apt/lists/*

ARG ZIG_VERSION=0.15.2
RUN curl -kL --retry 5 --retry-delay 3 --max-time 600 \
    https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz | \
    tar -xJ -C /opt && \
    ln -s /opt/zig-x86_64-linux-${ZIG_VERSION}/zig /usr/local/bin/zig

WORKDIR /workspace

RUN echo 'alias ll="ls -la"' >> /root/.bashrc && \
    echo 'alias zb="zig build"' >> /root/.bashrc && \
    echo 'PS1="\[\033[1;32m\][zdb-dev]\[\033[0m\] \w\$ "' >> /root/.bashrc

CMD ["/bin/bash"]
