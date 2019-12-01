FROM opensuse/leap:latest

LABEL version = "0.0.1"
LABEL maintainer = "wojciech.kotlarski@tu-dresden.de"
LABEL description = "openSUSY Leap docker image for FlexibleSUSY"

RUN zypper dup --no-confirm --no-recommends
RUN zypper in --no-confirm sudo
RUN zypper in --no-confirm --no-recommends curl avahi sshpass openssh expect tar gzip wget git

# install FlexibleSUSY system dependencies
RUN zypper in --no-confirm --no-recommends make gcc-c++ gcc-fortran libboost_headers1_66_0-devel libboost_test1_66_0-devel gsl-devel eigen3-devel

# install Wolfram Engine
RUN wget https://account.wolfram.com/download/public/wolfram-engine/desktop/LINUX && sudo bash LINUX -- -auto -verbose && rm LINUX

# activation of Wolfram Engine works only though wolframscript but it's not installed automatically on openSUSE
RUN rpm -i /usr/local/Wolfram/WolframEngine/12.0/SystemFiles/Installation/wolframscript-1.3-2019101401.x86_64.rpm

# FlexibleSUSY extras

# install LoopTools
# install FeynArts
# install FormCalc
# install Collier

# RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.conf
