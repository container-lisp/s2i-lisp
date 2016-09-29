Common Lisp + Quicklisp OpenShift Build Image
==============================================

This repository contains the source for building a Quicklisp based Common Lisp application as a reproducible docker image using [source-to-image](https://github.com/openshift/source-to-image). Users can choose between RHEL and CentOS based builder images.  The resulting image can be run using [docker](http://docker.io).


Usage
---------------------
To build a simple [sample-lisp-app](https://github.com/atgreen/sample-lisp-app) application using standalone [S2I](https://github.com/openshift/source-to-image) and then run the resulting image with [docker](http://docker.io) execute:

*  **For RHEL based image**
    ```
    $ s2i build https://github.com/atgreen/sample-lisp-app rhel/lisp-rhel7 sample-lisp-app
    $ docker run -p 8080:8080 sample-lisp-app
    ```

*  **For CentOS based image**
    ```
    $ s2i build https://github.com/atgreen/sample-lisp-app centos/lisp-centos7 sample-lisp-app
    $ docker run -p 8080:8080 sample-lisp-app
    ```

**Accessing the application:**
```
$ curl 127.0.0.1:8080
```


Repository organization
------------------------
* **Dockerfile**

        CentOS based Dockerfile.

* **Dockerfile.rhel7**

        RHEL based Dockerfile. In order to perform build or test actions on this
        Dockerfile you need to run the action on a properly subscribed RHEL machine.

* **`s2i/bin/`**

      This folder contains scripts that are run by [S2I](https://github.com/openshift/source-to-image) :

  *   **assemble**

            Used to install the sources into the location where the application
            will be run and prepare the application for deployment (eg. installing
            modules using bundler, etc.)

  *   **run**

            This script is responsible for running the application by using the
            application web server.

  *   **usage***

            This script prints the usage of this image.

Environment variables
---------------------

To set these environment variables, you can place them as a key value pair into a `.s2i/environment`
file inside your source code repository.

* **APP_EVAL1**

    SBCL evaluates this lisp form first at start up.  Use this to load
    the project with quicklisp like so: "(ql:quickload :webapp)".

* **APP_EVAL2**

    SBCL evaluates this lisp form second at start up.  Use this to
    start the project that was loaded in APP_EVAL1.  For
    instance: "(webapp:start-webapp)".


To change your source code in running container, use Docker's [exec](http://docker.io) command:
```
docker exec -it <CONTAINER_ID> /bin/bash
```

After you [docker exec](http://docker.io) into the running container, your current directory is set to `/opt/app-root`, and the source code is located under quicklisp/local-projects.
