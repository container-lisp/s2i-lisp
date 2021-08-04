[![Build Status](https://github.com/container-lisp/s2i-lisp/actions/workflows/build.yml/badge.svg)](https://github.com/container-lisp/s2i-lisp/actions)

Common Lisp + Quicklisp OpenShift Build Image
=============================================

This repository contains the source for building a Quicklisp based
Common Lisp application as a reproducible docker image using
[source-to-image](https://github.com/openshift/source-to-image). This
docker image is UBI-8 based. The resulting images can be run using
[docker](http://docker.io).

Usage
-----
To build a simple
[sample-lisp-app](https://github.com/container-lisp/sample-lisp-app)
application using standalone
[S2I](https://github.com/openshift/source-to-image) and then run the
resulting image with [docker](http://docker.io) execute:
```
$ s2i build https://github.com/container-lisp/sample-lisp-app quay.io/containerlisp/lisp-10-ubi8 sample-lisp-app
$ docker run -p 8080:8080 sample-lisp-app
```

**Accessing the application:**

Run interactively as above, you can access the sample-lisp-app like so:
```
$ curl 127.0.0.1:8080
```

You will likely, however, prefer [OpenShift](https://www.openshift.com), where applications are created like so:
```
$ oc new-app quay.io/containerlisp/lisp-10-ubi8~git://github.com/container-lisp/sample-lisp-app
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
[```sly-filename-translations```](http://joaotavora.github.io/sly/#Setting-up-pathname-translations).

There are a number of excellent screencasts and tutorials on using SLY
on the project web site at
[https://github.com/joaotavora/sly](https://github.com/joaotavora/sly).

Also note that instead of using sly, you can also decide to use slime,
the traditional emacs common lisp development environment. See below
the section about environment variable `DEV_BACKEND` on how to do
this.

To install this image along with sample application template into OpenShift, run the following as the cluster manager:
```
$ oc create -f lisp-image-streams.json -n openshift
$ oc create -f lisp-web-basic-s2i.json -n openshift
```

Overriding Quicklisp Packages
-----------------------------

If the top-level directory of your source repo contains a
`local-projects` directory, then all of the contents of that directory
will be moved to quicklisp's `local-projects` directory before
build-time.  This is useful is you ever need to use a different
version of a quicklisp-provided package, perhaps with local changes.


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
    Its default value is 90% of available memory as reported by
    cgroups.

* **DEV_BACKEND**

    Set this variable to `slynk` or `swank` to choose the development
    backend to start, or leave it unset to start no backend at all.

* **DEV_BACKEND_PORT**

    The default slynk/swank port is 4005. Set this value to something
    else for your application to use a different port (e.g. if your
    application needs to use this port). This setting will only come
    into effect when a development backend has been selected via
    `DEV_BACKEND`.

Public Container Images
-----------------------

The ubi8-based S2I images are published on quay.io, as
`quay.io/containerlisp/lisp-10-ubi8`.  Image tags are as follows:

* `latest`: the most recent build of the very latest quicklisp, SBCL
  and OS bits.

* Quicklisp dist version date (eg. `20181210`): The latest build based
  on this quicklisp distribution version.  If you use this tag, the
  quicklisp bits will never change, but the underlying OS and SBCL
  bits may.

* Git commit hash (eg. `b6ef12a`): The semantics of this tag are the
  same as above. It is provided as a convenience in order to map back
  to the original source version.

* Quicklisp dist version date + build number (eg. `20181210.26`):
  This identifies a specific build for a specific
  quicklisp distribution.  This is a unique build, and will never
  change.
