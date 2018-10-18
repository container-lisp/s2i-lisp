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

RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && yum update -y

RUN yum install -y libev libev-devel libuv libuv-devel && \
    yum clean all -y && \
    rpm -ivh http://ftp.altlinux.org/pub/distributions/ALTLinux/Sisyphus/x86_64/RPMS.classic/sbcl-1.4.12-alt1.x86_64.rpm && \
    localedef -i en_US -c -f UTF-8 en_US.UTF-8

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

ENV HOME=/opt/app-root \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

RUN mkdir -p /opt/app-root
WORKDIR /opt/app-root
RUN wget https://beta.quicklisp.org/quicklisp.lisp
COPY install.lisp /opt/app-root/install.lisp
RUN sbcl --non-interactive --load install.lisp
RUN chown -R 1001:1001 /opt/app-root && chmod -R go+rw /opt/app-root
USER 1001

# Set the default CMD to print the usage of the language image
CMD $STI_SCRIPTS_PATH/usage
