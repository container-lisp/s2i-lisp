[![Build Status](https://travis-ci.org/container-lisp/s2i-lisp.svg?branch=master)](https://travis-ci.org/container-lisp/s2i-lisp)

Common Lisp + Quicklisp OpenShift Build Image
=============================================

This repository contains the source for building a Quicklisp based
Common Lisp application as a reproducible docker image using
[source-to-image](https://github.com/openshift/source-to-image). This
docker image is CentOS based, but the project includes
Dockerfile.rhel7 for creating a RHEL based image as well. The
resulting images can be run using [docker](http://docker.io).

Usage
-----
To build a simple
[sample-lisp-app](https://github.com/container-lisp/sample-lisp-app)
application using standalone
[S2I](https://github.com/openshift/source-to-image) and then run the
resulting image with [docker](http://docker.io) execute:

    ```
    $ s2i build https://github.com/container-lisp/sample-lisp-app containerlisp/lisp-10-centos7 sample-lisp-app
    $ docker run -p 8080:8080 sample-lisp-app
    ```

**Accessing the application:**

Run interactively as above, you can access the sample-lisp-app like so:
```
$ curl 127.0.0.1:8080
```

You will likely, however, prefer [OpenShift](https://www.openshift.com), where applications are created like so:
```
$ oc new-app containerlisp/lisp-10-centos7~git://github.com/container-lisp/sample-lisp-app
```

A [slynk](https://github.com/joaotavora/sly) server will be started on
port 4005 for every application.  With OpenShift, you can forward port
4005 to your local host and connect to it with
[SLY](https://github.com/joaotavora/sly) for interactive
[Emacs](https://www.gnu.org/software/emacs/) based development.  Just
identify the pod running your container with `oc get pods`, and
then....

```oc port-forward sample-lisp-app-1-h5o5f 4005```

Follow this up in Emacs with...

```M-x sly-connect RET RET```

To teach Emacs how to translate filenames between the remote and local
machines, you'll need to define
[```sly-filename-translations```](http://joaotavora.github.io/sly/#Setting-up-pathname-translations)."

There are a number of excellent screencasts and tutorials on using SLY
on the project web site at
[https://github.com/joaotavora/sly](https://github.com/joaotavora/sly).

Note that slynk, by default, is configured to only listen on the
localhost loopback device.  This works well with OpenShift port
forwarding, as above, but if you run this container by hand you will
want to use the docker `--net host` option to allow for connections to
swank.

Also note that instead of using sly, you can also decide to use
slime, the traditional emacs common lisp development environment.
See below the section about environment variable DEV_ENV on how
to do this.

To install this image along with sample application template into OpenShift, run the following as the cluster manager:

    ```
    $ oc create -f lisp-image-streams.json -n openshift
    $ oc create -f lisp-web-basic-s2i.json -n openshift
    ```

Environment variables
---------------------

To set these environment variables, you can place them as a key value
pair into a `.s2i/environment` file inside your source code
repository.

* **APP_SYSTEM_NAME**

    The name that quicklisp will know this application by and which
    will become the name of the directory in the quicklisp
    local-project subdirectory, where the application source code will
    be copied into and build and run from.

* **APP_EVAL**

    SBCL evaluates this lisp form after ql:quickload'ing
    `:$APP_SYSTEM_NAME`, e.g. "`(webapp:start-webapp)`". This only happens
    when `:$APP_SCRIPT` is not used.

* **APP_SCRIPT**

    SBCL loads this script and executes it instead of evaluating
    `:$APP_EVAL`. This script needs to take care of setting up and
    quickloading the application but thus gives full control over the
    startup process. Note that this variable should point to a
    relative path, which will be within the quicklisp project defined
    by `APP_SYSTEM_NAME`, e.g. "`.s2i/run.lisp`".

* **APP_BUILD_SCRIPT**

    SBCL loads this script and executes it during the build process.
    If this is used, `:$APP_EVAL` and `$APP_SYSTEM_NAME` will not be used
    for quickloading and building the app. Instead, the script
    specified needs to take care of setting up and quickloading the
    application but thus gives more control over the build
    process. Note that this variable should point to a relative path,
    which will be within the quicklisp project defined by
    `APP_SYSTEM_NAME`, e.g. "`.s2i/build.lisp`".

* **APP_MEM**

    This value will be passed to sbcl via `--dynamic-space-size` and
    should be set to the amount of memory the application needs. It
    will be used for both building the image as well as running it.
    Its default value is 256M.

* **DEV_BACKEND**

    Set this variable to `slynk` or `swank` to choose the development
    backend to start, or leave it unset to start no backend at all.

* **DEV_BACKEND_PORT**

    The default slynk/swank port is 4005. Set this value to something
    else for your application to use a different port (e.g. if your
    application needs to use this port). This setting will only come
    into effect when a development backend has been selected via
    `DEV_ENV`.
