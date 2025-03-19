# Arbitrary docker container, will start off simple, before being based on an nvidia container.

# Roughly matching / inspired by https://github.com/celeritas-project/celeritas/blob/develop/scripts/docker/dev/Dockerfile as this is the base of the actual intended target.

# FROM rockylinux:9 AS builder
FROM nvidia/cuda:12.6.3-devel-rockylinux9 AS builder

ENV DEBIAN_FRONTEND=noninteractive \
    SPACK_ROOT=/opt/spack

# Install some build deps
RUN dnf update -y  \
&& dnf install -y epel-release  \
&& dnf update -y  \
&& dnf --enablerepo epel install -y bzip2 curl-minimal file findutils gcc-c++ gcc gcc-gfortran git gnupg2 hg hostname iproute make patch python3 python3-pip python3-setuptools svn unzip xz zstd \
&& rm -rf /var/cache/dnf  \
&& dnf clean all ;

# Fetch and extract spack
RUN mkdir -p $SPACK_ROOT \
  && curl -s -L https://api.github.com/repos/spack/spack/tarball/v0.23.1 \
  | tar xzC $SPACK_ROOT --strip 1

# Create some spack related symnlinks 
RUN ln -s $SPACK_ROOT/share/spack/docker/entrypoint.bash \
    /usr/local/bin/docker-shell \
&& ln -s $SPACK_ROOT/share/spack/docker/entrypoint.bash \
  /usr/local/bin/interactive-shell \
&& ln -s $SPACK_ROOT/share/spack/docker/entrypoint.bash \
  /usr/local/bin/spack-env

RUN mkdir -p /root/.spack \
&& cp $SPACK_ROOT/share/spack/docker/modules.yaml \
/root/.spack/modules.yaml \
&& rm -rf /root/*.* /run/nologin $SPACK_ROOT/.git

WORKDIR /root
SHELL ["docker-shell"]

# Bootstrap spack

RUN docker-shell spack bootstrap now \
  && spack bootstrap status --optional \
  && spack spec root

ENTRYPOINT ["/bin/bash", "/opt/spack/share/spack/docker/entrypoint.bash"]
CMD ["interactive-shell"]
