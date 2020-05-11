FROM opensuse/leap:latest

ARG BUILD_DATE
ARG VERSION

LABEL maintainer = "wojciech.kotlarski@tu-dresden.de"
LABEL description = "openSUSY Leap docker image for FlexibleSUSY"
LABEL version = $VERSION
LABEL build-date = $BUILD_DATE

# update the default image
RUN zypper dup --no-confirm --no-recommends

# which is needed by FormCalc's compile script
RUN zypper in --no-recommends --no-confirm glibc-locale tar gzip wget which git vim
RUN zypper in --no-recommends --no-confirm make gcc-c++ gcc-fortran clang libboost_headers1_66_0-devel libboost_test1_66_0-devel gsl-devel eigen3-devel sqlite3-devel

# install Wolfram Engine
RUN wget -q https://account.wolfram.com/download/public/wolfram-engine/desktop/LINUX && bash LINUX -- -auto && rm LINUX
ENV PATH="/usr/local/Wolfram/WolframEngine/12.1/Executables:${PATH}"

# activation of Wolfram Engine works only though wolframscript but it's not installed automatically on openSUSE
# intsalling this rpm tries to call xdm-mime
RUN zypper in --no-confirm --no-recommends xdg-utils
RUN rpm -i /usr/local/Wolfram/WolframEngine/12.1/SystemFiles/Installation/wolframscript-*.x86_64.rpm

# FlexibleSUSY extras

# conan
# RUN zypper in --no-recommend --no-confirm python3-pip
# RUN pip install conan
# RUN conan remote add conan-hep https://api.bintray.com/conan/expander/conan-hep
# RUN mkdir /root/.conan/profiles
# COPY g++ /root/.conan/profiles/g++
# COPY clang++ /root/.conan/profiles/clang++

# Himalaya and Collier need cmake
RUN zypper in --no-recommends --no-confirm cmake

# install Collier
# FS interface to Collier requires it to be compiled into a static library and in position independent mode
RUN wget -q -O - https://collier.hepforge.org/downloads/collier-1.2.4.tar.gz | tar -xzf -
RUN cd COLLIER-1.2.4/build && cmake -Dstatic=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_INSTALL_PREFIX=/COLLIER .. && make && make install
RUN rm -r COLLIER-1.2.4

# some tests require numdiff which is not in openSUSE package repo
RUN cd /tmp && wget -q -O - http://mirror.netcologne.de/savannah/numdiff/numdiff-5.9.0.tar.gz | tar -xzf -
RUN cd /tmp/numdiff-5.9.0 && ./configure && make && make install
RUN rm -r /tmp/numdiff-5.9.0

# extra packages required by tests
RUN zypper in --no-recommends --no-confirm bc
