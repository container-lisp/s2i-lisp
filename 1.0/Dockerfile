FROM openshift/base-centos7
#FROM registry.access.redhat.com/rhel7-atomic

# This image provides a Common Lisp environment based on QuickLisp and
# that you can use to run your Common Lisp applications.

MAINTAINER Harald Judt <hjudt@gmx.at>

EXPOSE 8080

ENV LISP_VERSION 1.0

LABEL io.k8s.description="Platform for building and running Common Lisp applications" \
      io.k8s.display-name="Common Lisp" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,cl,lisp,sbcl" \
      io.openshift.s2i.scripts-url=image://$STI_SCRIPTS_PATH

RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    yum update -y && \
    yum clean all -y && \
    localedef -i en_US -c -f UTF-8 en_US.UTF-8

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

ENV HOME=/opt/app-root \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    BASH_ENV=/opt/app-root/etc/scl_enable \
    ENV=/opt/app-root/etc/scl_enable \
    PROMPT_COMMAND=". /opt/app-root/etc/scl_enable" \
    PATH=/opt/app-root/src/bin:/opt/app-root/bin:/opt/rh/devtoolset-7/root/usr/bin/:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN yum install -y centos-release-scl && \
    yum install -y devtoolset-7-gcc* && \
    yum install -y libuv libuv-devel && \
    yum clean all -y && \
    scl enable devtoolset-7 bash && \
    gcc --version && \
    rpm -ivh http://ftp.altlinux.org/pub/distributions/ALTLinux/Sisyphus/x86_64/RPMS.classic/libev4-4.24-alt1.x86_64.rpm && \
    rpm -ivh http://ftp.altlinux.org/pub/distributions/ALTLinux/Sisyphus/x86_64/RPMS.classic/libev-devel-4.24-alt1.x86_64.rpm && \
    rm -rf /var/cache/yum

WORKDIR /opt/app-root
COPY ./root/ /

RUN wget --progress=bar:force "https://downloads.sourceforge.net/project/sbcl/sbcl/1.4.14/sbcl-1.4.14-x86-64-linux-binary.tar.bz2" && \
    tar -xvf sbcl-1.4.14-x86-64-linux-binary.tar.bz2 && \
    cd sbcl-1.4.14-x86-64-linux && \
    ./install.sh && \
    cd .. && rm -rf sbcl-1.4.14-x86-64-linux-binary.tar.bz2 sbcl-1.4.14-x86-64-linux && \
    wget https://beta.quicklisp.org/quicklisp.lisp && \
    sbcl --non-interactive --load install.lisp && \
    chown -R 1001:1001 /opt/app-root && \
    chmod -R go+rw /opt/app-root

USER 1001

# Set the default CMD to print the usage of the language image
CMD $STI_SCRIPTS_PATH/usage
