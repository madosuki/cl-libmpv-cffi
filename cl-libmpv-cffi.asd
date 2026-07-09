(defpackage :cl-libmpv-cffi-asd
  (:use :cl :asdf))

(in-package :cl-libmpv-cffi-asd)

(defsystem :cl-libmpv-cffi
  :name "cl-libmpv-cffi"
  :version "0.0.1"
  :author "madosuki"
  :license "MIT"
  :description "wrapper and binding of libmpv"
  :serial t
  :depends-on ("cffi" "cffi-libffi")
  :components ((:module "src"
                :components ((:file "binding")
                             (:file "cl-libmpv-cffi")
                             (:file "wrapper")))))
