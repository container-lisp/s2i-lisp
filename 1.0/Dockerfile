FROM registry.access.redhat.com/ubi8/s2i-core

# This image provides a Common Lisp environment based on QuickLisp and
# that you can use to run your Common Lisp applications.

MAINTAINER The container-lisp hackers @ github.com/container-lisp

EXPOSE 8080

LABEL io.k8s.description="Platform for building and running Common Lisp applications" \
      io.k8s.display-name="Common Lisp" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,cl,lisp,sbcl" \
      io.openshift.s2i.scripts-url=image://$STI_SCRIPTS_PATH

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

ENV HOME=/opt/app-root \
    LC_ALL=C.utf8 \
    LANG=C.utf8 \
    LANGUAGE=C.utf8 \
    LISP_VERSION=1.0 \
    SBCL_VERSION=2.2.1 \
    LIBEV_VERSION=4.33 \
    LIBSSH2_VERSION=1.9.0

RUN rm /etc/rhsm-host && \
    yum install -y \
        bzip2 git make patch automake autoconf libtool gcc gcc-c++ libuv openssl-devel && \
    yum clean -y all && \
    locale -a && \
    gcc --version

WORKDIR $HOME
COPY ./root/ /

# Build libev from source since it is not available in ubi8-base nor ubi8-app-stream repos
RUN curl -O "http://dist.schmorp.de/libev/Attic/libev-${LIBEV_VERSION}.tar.gz" && \
    tar xvf libev-${LIBEV_VERSION}.tar.gz && \
    cd libev-${LIBEV_VERSION} && \
    chmod +x autogen.sh && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make && \
    make install && \
    cd "$HOME" && \
    rm -rf libev*

# Build libssh2 from source since it is not available in ubi8-base nor ubi8-app-stream repos
RUN curl -O "https://www.libssh2.org/download/libssh2-${LIBSSH2_VERSION}.tar.gz" && \
    tar xvf libssh2-${LIBSSH2_VERSION}.tar.gz && \
    cd libssh2-${LIBSSH2_VERSION} && \
    ./configure --prefix=/usr --with-crypto=openssl && \
    make && \
    make install && \
    cd "$HOME" && \
    rm -rf libssh2* && \
    mkdir -p /opt/app-root/.ssh && \
    dnf remove -y openssl-devel && ls -la /opt/app-root

RUN curl -L -O "https://downloads.sourceforge.net/project/sbcl/sbcl/${SBCL_VERSION}/sbcl-${SBCL_VERSION}-x86-64-linux-binary.tar.bz2" && \
    curl -L -O https://beta.quicklisp.org/quicklisp.lisp && \
    tar -xvf sbcl-${SBCL_VERSION}-x86-64-linux-binary.tar.bz2 && \
    cd sbcl-${SBCL_VERSION}-x86-64-linux && \
    ./install.sh && \
    cd .. && \
    rm -rf sbcl-${SBCL_VERSION}-x86-64-linux-binary.tar.bz2 \
       sbcl-${SBCL_VERSION}-x86-64-linux && \
    git clone --depth 1 https://github.com/joaotavora/sly-quicklisp.git && \
    mv sly-quicklisp common-lisp && \
    sbcl --non-interactive --disable-debugger --load install.lisp

RUN usermod -d ${HOME} default && \
    chown -R 1001:0 ${HOME} && \
    chmod -R g+rwX,o= ${HOME}

USER 1001

RUN touch /opt/app-root/.ssh/trivial_ssh_hosts

# Set the default CMD to print the usage of the language image
CMD $STI_SCRIPTS_PATH/usage
