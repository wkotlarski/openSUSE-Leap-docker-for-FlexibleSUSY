FROM opensuse/leap:15.2

ARG BUILD_DATE
ARG VERSION

ENV SARAH_VERSION 4.14.5
ENV FEYNARTS_VERSION 3.11
ENV HIMALAYA_VERSION 4.1.1
ENV LOOPTOOLS_VERSION 2.16
ENV COLLIER_VERSION 1.2.5
ENV GM2Calc_VERSION 1.7.5
ENV MATH_VERSION 12.3
ENV TSIL_VERSION 1.45

LABEL maintainer = "wojciech.kotlarski@tu-dresden.de"
LABEL description = "openSUSY Leap docker image for FlexibleSUSY"
LABEL version = $VERSION
LABEL build-date = $BUILD_DATE

# update the default image
RUN zypper dup --no-confirm --no-recommends

# which is needed by FormCalc's compile script
RUN zypper in --no-recommends --no-confirm glibc-locale tar gzip wget which git vim emacs ruby
RUN zypper in --no-recommends --no-confirm make gcc-c++ gcc-fortran clang libboost_headers1_66_0-devel libboost_test1_66_0-devel gsl-devel eigen3-devel sqlite3-devel

# install Wolfram Engine
# Wolfram Engine > 12.1.1 requires xz
RUN zypper in --no-recommends --no-confirm xz
RUN wget -q https://account.wolfram.com/download/public/wolfram-engine/desktop/LINUX && bash LINUX -- -auto && rm LINUX
ENV PATH="/usr/local/Wolfram/WolframEngine/${MATH_VERSION}/Executables:${PATH}"

# activation of Wolfram Engine works only though wolframscript but it's not installed automatically on openSUSE
# installing this rpm tries to call xdm-mime
RUN zypper in --no-confirm --no-recommends xdg-utils
RUN rpm -i /usr/local/Wolfram/WolframEngine/${MATH_VERSION}/SystemFiles/Installation/wolframscript-*.x86_64.rpm

# install SARAH
RUN wget -q -O - https://sarah.hepforge.org/downloads/SARAH-${SARAH_VERSION}.tar.gz | tar -xzf -
RUN mkdir -p /root/.WolframEngine/Kernel
RUN echo "AppendTo[\$Path, \"/SARAH-${SARAH_VERSION}\"];" > /root/.WolframEngine/Kernel/init.m

# FlexibleSUSY extras

# install FeynArts
RUN wget -q -O - http://www.feynarts.de/FeynArts-${FEYNARTS_VERSION}.tar.gz | tar -xzf -
RUN echo "AppendTo[\$Path, \"/FeynArts-${FEYNARTS_VERSION}\"];" >> /root/.WolframEngine/Kernel/init.m

# install LoopTools
RUN wget -q http://www.feynarts.de/looptools/LoopTools-${LOOPTOOLS_VERSION}.tar.gz
RUN tar -xf LoopTools-${LOOPTOOLS_VERSION}.tar.gz
RUN cd LoopTools-${LOOPTOOLS_VERSION} && CC=gcc CXX=g++ FFLAGS=-fPIC CFLAGS=-fPIC CXXFLAGS=-fPIC ./configure --prefix=/LoopTools-g++ && make && make install
RUN rm -r LoopTools-${LOOPTOOLS_VERSION}
RUN tar -xf LoopTools-${LOOPTOOLS_VERSION}.tar.gz
RUN cd LoopTools-${LOOPTOOLS_VERSION} && CC=clang CXX=clang++ FFLAGS=-fPIC CFLAGS=-fPIC CXXFLAGS=-fPIC ./configure --prefix=/LoopTools-clang++ && make && make install
RUN rm -r LoopTools-${LOOPTOOLS_VERSION}*

# Himalaya and Collier need cmake
RUN zypper in --no-recommends --no-confirm cmake

# install Collier
# FS interface to Collier requires it to be compiled into a static library and in position independent mode
RUN cd /tmp && wget -q -O - https://collier.hepforge.org/downloads/collier-${COLLIER_VERSION}.tar.gz | tar -xzf -
# Collier cannot be compiled in parallel
RUN cd /tmp/COLLIER-${COLLIER_VERSION}/build && cmake -Dstatic=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_INSTALL_PREFIX=/COLLIER .. && make && make install
RUN rm -r /tmp/COLLIER-${COLLIER_VERSION}

# install Himalaya
RUN cd /tmp && wget -q -O - https://github.com/Himalaya-Library/Himalaya/archive/${HIMALAYA_VERSION}.tar.gz | tar -xzf -
RUN mkdir -p /tmp/Himalaya-${HIMALAYA_VERSION}/build
# there's a bug FindMathematica.cmake. We need libuuid-devel
RUN zypper in --no-recommends --no-confirm libuuid-devel
# without EIGEN3_INCLUDE_DIR cmake will not find Eigen3 if we also specify minimal version required
RUN cd /tmp/Himalaya-${HIMALAYA_VERSION}/build && cmake .. -DCMAKE_INSTALL_PREFIX=/Himalaya-g++ -DCMAKE_CXX_COMPILER=g++ -DEIGEN3_INCLUDE_DIR=/usr/include/eigen3 && make -j2 && make install
RUN rm -r /tmp/Himalaya-${HIMALAYA_VERSION}/build/*
RUN cd /tmp/Himalaya-${HIMALAYA_VERSION}/build && cmake .. -DCMAKE_INSTALL_PREFIX=/Himalaya-clang++ -DCMAKE_CXX_COMPILER=clang++ -DEIGEN3_INCLUDE_DIR=/usr/include/eigen3 && make -j2 && make install
RUN rm -r /tmp/Himalaya-${HIMALAYA_VERSION}

# install GM2Calc
RUN cd /tmp && wget -q -O - https://github.com/GM2Calc/GM2Calc/archive/v${GM2Calc_VERSION}.tar.gz | tar -xzf -
RUN mkdir /tmp/GM2Calc-${GM2Calc_VERSION}/build
RUN cd /tmp/GM2Calc-${GM2Calc_VERSION}/build && cmake .. -DCMAKE_INSTALL_PREFIX=/GM2Calc-g++ -DCMAKE_CXX_COMPILER=g++ -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DEIGEN3_INCLUDE_DIR=/usr/include/eigen3 && make -j2 && make install
RUN rm -r /tmp/GM2Calc-${GM2Calc_VERSION}/build && mkdir /tmp/GM2Calc-${GM2Calc_VERSION}/build
RUN cd /tmp/GM2Calc-${GM2Calc_VERSION}/build && cmake .. -DCMAKE_INSTALL_PREFIX=/GM2Calc-clang++ -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DEIGEN3_INCLUDE_DIR=/usr/include/eigen3 && make -j2 && make install
RUN rm -r /tmp/GM2Calc-${GM2Calc_VERSION}

# install TSIL
RUN cd /tmp && wget -q http://www.niu.edu/spmartin/TSIL/tsil-${TSIL_VERSION}.tar.gz
RUN cd /tmp && tar -xf tsil-${TSIL_VERSION}.tar.gz
RUN cp -r /tmp/tsil-${TSIL_VERSION} /tsil-clang++
RUN cp -r /tmp/tsil-${TSIL_VERSION} /tsil-g++
RUN rm -r /tmp/tsil-${TSIL_VERSION}*
RUN cd /tsil-clang++ && make CC=clang CFLAGS="-DTSIL_SIZE_LONG -O3 -funroll-loops -fPIC"
RUN cd /tsil-g++ && make CC=gcc CFLAGS="-DTSIL_SIZE_LONG -O3 -funroll-loops -fPIC"

# some tests require numdiff which is not in openSUSE package repo
RUN cd /tmp && wget -q -O - http://mirror.netcologne.de/savannah/numdiff/numdiff-5.9.0.tar.gz | tar -xzf -
RUN cd /tmp/numdiff-5.9.0 && ./configure && make && make install
RUN rm -r /tmp/numdiff-5.9.0

# extra packages required by tests
RUN zypper in --no-recommends --no-confirm bc

