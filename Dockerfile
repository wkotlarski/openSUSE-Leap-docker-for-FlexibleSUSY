FROM opensuse/leap:latest

LABEL version = "0.0.1"
LABEL maintainer = "wojciech.kotlarski@tu-dresden.de"
LABEL description = "openSUSY Leap docker image for FlexibleSUSY"

RUN zypper dup --no-confirm --no-recommends
RUN zypper in --no-confirm sudo
RUN zypper in --no-confirm --no-recommends curl avahi wget sshpass openssh vim expect libasound2 Mesa-libGL1 fontconfig tar gzip wget git

# install FlexibleSUSY system dependencies
RUN zypper in --no-confirm --no-recommends gcc-c++ gcc-fortran boost-devel gsl-devel eigen3-devel

# install Wolfram Engine
RUN wget https://account.wolfram.com/download/public/wolfram-engine/desktop/LINUX && sudo bash LINUX -- -auto -verbose && rm LINUX

# FlexibleSUSY extras

# install LoopTools
# install FeynArts
# install FormCalc
# install Collier

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.conf
