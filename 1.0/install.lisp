(defvar *dist-url* "http://beta.quicklisp.org/dist/quicklisp/2015-03-02/distinfo.txt")

(load "quicklisp.lisp")

(quicklisp-quickstart:install :path "/opt/app-root/quicklisp/" :dist-url *dist-url*)

; Pre-load/compile useful content...
(ql:quickload :hunchentoot)

(with-open-file (out "/opt/app-root/.sbclrc" :direction :output)
  (format out "(load \"/opt/app-root/quicklisp\/setup.lisp\")"))
