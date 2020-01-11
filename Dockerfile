FROM opensuse/leap:latest

LABEL version = "0.2.0"
LABEL maintainer = "wojciech.kotlarski@tu-dresden.de"
LABEL description = "openSUSY Leap docker image for FlexibleSUSY"

# update the default image
RUN zypper dup --no-confirm --no-recommends

# which is needed by FormCalc's compile script
RUN zypper in --no-recommends --no-confirm glibc-locale tar gzip wget git which
RUN zypper in --no-recommends --no-confirm make gcc-c++ gcc-fortran clang libboost_headers1_66_0-devel libboost_test1_66_0-devel gsl-devel eigen3-devel

# install Wolfram Engine
RUN wget https://account.wolfram.com/download/public/wolfram-engine/desktop/LINUX && bash LINUX -- -auto -verbose && rm LINUX

# activation of Wolfram Engine works only though wolframscript but it's not installed automatically on openSUSE
# intsalling this rpm tries to call xdm-mime
RUN zypper in --no-confirm --no-recommends xdg-utils
RUN rpm -i /usr/local/Wolfram/WolframEngine/12.0/SystemFiles/Installation/wolframscript-1.3-2019101401.x86_64.rpm

# FlexibleSUSY extras

# conan
RUN zypper in --no-recommend --no-confirm python3-pip
RUN pip install conan
RUN conan remote add conan-hep https://api.bintray.com/conan/expander/conan-hep
RUN mkdir $HOME/.conan/profiles
COPY g++ $HOME/.conan/profiles
COPY clang++ $HOME/.conan/profiles

# Himalaya needs cmake
RUN zypper in --no-recommends --no-confirm cmake

# install LoopTools
# install FormCalc
# install Collier
