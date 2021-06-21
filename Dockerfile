FROM opensuse/leap:15.3

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
RUN zypper in --no-recommends --no-confirm glibc-locale tar gzip wget which git vim emacs ruby curl
RUN zypper in --no-recommends --no-confirm make gcc-c++ gcc-fortran clang libboost_headers1_66_0-devel libboost_test1_66_0-devel gsl-devel eigen3-devel sqlite3-devel

# install intel compiler suite
COPY oneAPI.repo /etc/yum.repos.d
RUN zypper addrepo https://yum.repos.intel.com/oneapi oneAPI
RUN rpm --import https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
RUN zypper in --no-recommends --no-confirm intel-oneapi-compiler-dpcpp-cpp-and-cpp-classic intel-oneapi-compiler-fortran
RUN source /opt/intel/oneapi/setvars.sh

# install Wolfram Engine
# Wolfram Engine > 12.1.1 requires xz
RUN zypper in --no-recommends --no-confirm xz
RUN wget -q https://account.wolfram.com/download/public/wolfram-engine/desktop/LINUX && bash LINUX -- -auto && rm LINUX
ENV PATH="/usr/local/Wolfram/WolframEngine/${MATH_VERSION}/Executables:${PATH}"
# remove some leftovers
RUN rm -rf applications-merged

# activation of Wolfram Engine works only though wolframscript but it's not installed automatically on openSUSE
# installing this rpm tries to call xdm-mime
RUN zypper in --no-confirm --no-recommends xdg-utils
RUN rpm -i /usr/local/Wolfram/WolframEngine/${MATH_VERSION}/SystemFiles/Installation/wolframscript-*.x86_64.rpm

RUN mkdir -p /fs_dependencies/mathematica

# install SARAH
RUN cd /fs_dependencies/mathematica && wget -q -O - https://sarah.hepforge.org/downloads/SARAH-${SARAH_VERSION}.tar.gz | tar -xzf -
RUN mkdir -p /root/.WolframEngine/Kernel
RUN echo "AppendTo[\$Path, \"/fs_dependencies/mathematica/SARAH-${SARAH_VERSION}\"];" > /root/.WolframEngine/Kernel/init.m

# FlexibleSUSY extras

# install FeynArts
RUN cd /fs_dependencies/mathematica && wget -q -O - http://www.feynarts.de/FeynArts-${FEYNARTS_VERSION}.tar.gz | tar -xzf -
RUN echo "AppendTo[\$Path, \"/fs_dependencies/mathematica/FeynArts-${FEYNARTS_VERSION}\"];" >> /root/.WolframEngine/Kernel/init.m

RUN mkdir -p /fs_dependencies/clang /fs_dependencies/gcc /fs_dependencies/intel
RUN mkdir /tmp/source

# install LoopTools
RUN cd /tmp/source && wget -q http://www.feynarts.de/looptools/LoopTools-${LOOPTOOLS_VERSION}.tar.gz
RUN cd /tmp/source && tar -xf LoopTools-${LOOPTOOLS_VERSION}.tar.gz
RUN cd /tmp/source/LoopTools-${LOOPTOOLS_VERSION} && CC=gcc CXX=g++ FC=gfortran FFLAGS=-fPIC CFLAGS=-fPIC CXXFLAGS=-fPIC ./configure --prefix=/fs_dependencies/gcc/LoopTools && make && make install
RUN rm -r /tmp/source/LoopTools-${LOOPTOOLS_VERSION}
RUN cd /tmp/source && tar -xf LoopTools-${LOOPTOOLS_VERSION}.tar.gz
RUN cd /tmp/source/LoopTools-${LOOPTOOLS_VERSION} && CC=clang CXX=clang++ FS=gfortran FFLAGS=-fPIC CFLAGS=-fPIC CXXFLAGS=-fPIC ./configure --prefix=/fs_dependencies/clang/LoopTools && make && make install
RUN rm -r /tmp/source/LoopTools-${LOOPTOOLS_VERSION}
RUN cd /tmp/source && tar -xf LoopTools-${LOOPTOOLS_VERSION}.tar.gz
RUN cd /tmp/source/LoopTools-${LOOPTOOLS_VERSION} && source /opt/intel/oneapi/setvars.sh && CC=icc CXX=icpc FC=ifort FFLAGS=-fPIC CFLAGS=-fPIC CXXFLAGS=-fPIC ./configure --prefix=/fs_dependencies/intel/LoopTools && make && make install
RUN rm -r /tmp/source/LoopTools-${LOOPTOOLS_VERSION}*

# Himalaya and Collier need cmake
RUN zypper in --no-recommends --no-confirm cmake

# install Collier
# FS interface to Collier requires it to be compiled into a static library and in position independent mode
RUN cd /tmp/source && wget -q -O - https://collier.hepforge.org/downloads/collier-${COLLIER_VERSION}.tar.gz | tar -xzf -
# Collier cannot be compiled in parallel
RUN cd /tmp/source/COLLIER-${COLLIER_VERSION}/build && cmake -Dstatic=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_INSTALL_PREFIX=/fs_dependencies/gcc/COLLIER -DCMAKE_Fortran_COMPILER=gfortran .. && make && make install
RUN rm -r /tmp/source/COLLIER-${COLLIER_VERSION}/build/*
RUN cd /tmp/source/COLLIER-${COLLIER_VERSION}/build && source /opt/intel/oneapi/setvars.sh && cmake -Dstatic=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_INSTALL_PREFIX=/fs_dependencies/intel/COLLIER -DCMAKE_Fortran_COMPILER=ifort .. && make && make install
RUN rm -r /tmp/source/COLLIER-${COLLIER_VERSION}

# install Himalaya
RUN cd /tmp/source && wget -q -O - https://github.com/Himalaya-Library/Himalaya/archive/${HIMALAYA_VERSION}.tar.gz | tar -xzf -
RUN mkdir -p /tmp/source/Himalaya-${HIMALAYA_VERSION}/build
# there's a bug FindMathematica.cmake. We need libuuid-devel
RUN zypper in --no-recommends --no-confirm libuuid-devel
# without EIGEN3_INCLUDE_DIR cmake will not find Eigen3 if we also specify minimal version required
RUN cd /tmp/source/Himalaya-${HIMALAYA_VERSION}/build && cmake .. -DCMAKE_INSTALL_PREFIX=/fs_dependencies/gcc/Himalaya -DCMAKE_CXX_COMPILER=g++ -DEIGEN3_INCLUDE_DIR=/usr/include/eigen3 && make -j2 && make install
RUN rm -r /tmp/source/Himalaya-${HIMALAYA_VERSION}/build/*
RUN cd /tmp/source/Himalaya-${HIMALAYA_VERSION}/build && cmake .. -DCMAKE_INSTALL_PREFIX=/fs_dependencies/clang/Himalaya -DCMAKE_CXX_COMPILER=clang++ -DEIGEN3_INCLUDE_DIR=/usr/include/eigen3 && make -j2 && make install
RUN rm -r /tmp/source/Himalaya-${HIMALAYA_VERSION}/build/*
RUN cd /tmp/source/Himalaya-${HIMALAYA_VERSION}/build && source /opt/intel/oneapi/setvars.sh && cmake .. -DCMAKE_INSTALL_PREFIX=/fs_dependencies/intel/Himalaya -DCMAKE_CXX_COMPILER=icpc -DEIGEN3_INCLUDE_DIR=/usr/include/eigen3 && make -j2 && make install
RUN rm -r /tmp/source/Himalaya-${HIMALAYA_VERSION}

# install GM2Calc
RUN cd /tmp/source && wget -q -O - https://github.com/GM2Calc/GM2Calc/archive/v${GM2Calc_VERSION}.tar.gz | tar -xzf -
RUN mkdir /tmp/source/GM2Calc-${GM2Calc_VERSION}/build
RUN cd /tmp/source/GM2Calc-${GM2Calc_VERSION}/build && cmake .. -DCMAKE_INSTALL_PREFIX=/fs_dependencies/gcc/GM2Calc -DCMAKE_CXX_COMPILER=g++ -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DEIGEN3_INCLUDE_DIR=/usr/include/eigen3 && make -j2 && make install
RUN rm -r /tmp/source/GM2Calc-${GM2Calc_VERSION}/build/*
RUN cd /tmp/source/GM2Calc-${GM2Calc_VERSION}/build && cmake .. -DCMAKE_INSTALL_PREFIX=/fs_dependencies/clang/GM2Calc -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DEIGEN3_INCLUDE_DIR=/usr/include/eigen3 && make -j2 && make install
RUN rm -r /tmp/source/GM2Calc-${GM2Calc_VERSION}/build/*
RUN cd /tmp/source/GM2Calc-${GM2Calc_VERSION}/build && source /opt/intel/oneapi/setvars.sh && cmake .. -DCMAKE_INSTALL_PREFIX=/fs_dependencies/intel/GM2Calc -DCMAKE_CXX_COMPILER=icpc -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DEIGEN3_INCLUDE_DIR=/usr/include/eigen3 && make -j2 && make install
RUN rm -r /tmp/source/GM2Calc-${GM2Calc_VERSION}

# install TSIL
RUN cd /tmp/source && wget -q http://www.niu.edu/spmartin/TSIL/tsil-${TSIL_VERSION}.tar.gz
RUN cd /tmp/source && tar -xf tsil-${TSIL_VERSION}.tar.gz
RUN for comp in gcc clang intel; do cp -r /tmp/source/tsil-${TSIL_VERSION} /fs_dependencies/$comp/tsil; done
RUN rm -r /tmp/source/tsil-${TSIL_VERSION}*
RUN cd /fs_dependencies/clang/tsil && make CC=clang CFLAGS="-DTSIL_SIZE_LONG -O3 -funroll-loops -fPIC"
RUN cd /fs_dependencies/gcc/tsil && make CC=gcc CFLAGS="-DTSIL_SIZE_LONG -O3 -funroll-loops -fPIC"
RUN cd /fs_dependencies/intel/tsil && source /opt/intel/oneapi/setvars.sh && make CC=icc CFLAGS="-DTSIL_SIZE_LONG -O3 -funroll-loops -fPIC"

# some tests require numdiff which is not in openSUSE package repo
RUN cd /tmp/source && wget -q -O - http://mirror.netcologne.de/savannah/numdiff/numdiff-5.9.0.tar.gz | tar -xzf -
RUN cd /tmp/source/numdiff-5.9.0 && ./configure && make && make install
RUN rm -r /tmp/source/numdiff-5.9.0

RUN rm -r /tmp/source

# extra packages required by tests
RUN zypper in --no-recommends --no-confirm bc

RUN zypper clean -a
