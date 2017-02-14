(defvar *dist-url* "http://beta.quicklisp.org/dist/quicklisp/2017-01-24/distinfo.txt")

(load "quicklisp.lisp")

(quicklisp-quickstart:install :path "/opt/app-root/quicklisp/" :dist-url *dist-url*)

; Pre-load/compile useful content...
(ql:quickload :hunchentoot)
(ql:quickload :swank)

(with-open-file (out "/opt/app-root/.sbclrc" :direction :output)
  (format out "(load \"/opt/app-root/quicklisp\/setup.lisp\")")
  (format out "(ql:quickload :swank)")
  (format out "(swank:create-server :port 4005 :dont-close t)"))


