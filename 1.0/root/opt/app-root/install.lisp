(defvar *dist-url* "http://beta.quicklisp.org/dist/quicklisp/2021-05-31/distinfo.txt")

(load "quicklisp.lisp")

(quicklisp-quickstart:install :path "/opt/app-root/quicklisp/" :dist-url *dist-url*)

(format t "Patching quicklisp to automatically use a local quicklisp mirror...~%")
(uiop:run-program "patch -p0 < quicklisp-mirror.patch" :output *standard-output*)

;; Pre-load/compile slynk and swank
(ql:quickload :swank)
(ql:quickload :slynk)

(with-open-file (out "/opt/app-root/.sbclrc" :direction :output)
  (format out "
  (setf sb-ext:*exit-timeout* 15)
  (load \"/opt/app-root/quicklisp\/setup.lisp\")
  (let ((backend (sb-ext:posix-getenv \"DEV_BACKEND\"))
        (backend-port (sb-ext:posix-getenv \"DEV_BACKEND_PORT\")))
    (setq backend-port
          (if backend-port
              (parse-integer (remove #\\\" backend-port))
              4005))
    (when backend
      (ql:quickload backend)
      (setq backend (string-upcase backend))
      (funcall (find-symbol \"CREATE-SERVER\" (find-package backend))
               :port backend-port :dont-close t)))~%"))
