FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

# ---- base deps (only what we need to build/run chatafl + llvm_mode) ----
RUN apt-get -y update && \
    apt-get -y install sudo \ 
    apt-utils \
    build-essential \
    openssl \
    clang \
    graphviz-dev \
    git \
    autoconf \
    libgnutls28-dev \
    llvm \
    python3-pip \
    nano \
    net-tools \
    vim \
    gdb \
    netcat \
    strace \
    libcap-dev \
    libpcre2-dev \
    libpcre2-8-0 \
    libcurl4-openssl-dev \
    libjson-c-dev \
    wget

# (optional) keep your gcovr pin (can remove if you don't need it)
RUN pip3 install --no-cache-dir gcovr==4.2

# Import environment variable to pass as parameter to make (e.g. -j8)
ARG MAKE_OPT="-j128"

# ---- build chatafl only ----
# root 模式下不需要 --chown
COPY chatafl /opt/chatafl
WORKDIR /opt/chatafl

RUN make clean all ${MAKE_OPT}
RUN cd llvm_mode && make ${MAKE_OPT}

# ---- env vars (point AFL_PATH to chatafl, not aflnet) ----
ENV AFL_PATH=/opt/chatafl
ENV PATH="${PATH}:/opt/chatafl:/root/.local/bin"
ENV AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 \
    AFL_SKIP_CPUFREQ=1 \
    AFL_NO_AFFINITY=1

WORKDIR /root
CMD ["bash"]