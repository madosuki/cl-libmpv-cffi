(require :asdf)

(let ((quicklisp-init (merge-pathnames #P"quicklisp/setup.lisp"
                                       (user-homedir-pathname))))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))

(asdf:load-asd (merge-pathnames #P"../cl-libmpv-cffi.asd" *load-truename*))
(asdf:load-system :cl-libmpv-cffi)

(defparameter *media-path* "/home/foo/Videos/bar.mp4")

(defun wait-for-playback-result (player &key (load-timeout-seconds 10))
  (let ((deadline (+ (get-universal-time) load-timeout-seconds))
        (loaded-p nil))
    (loop
      for event = (cl-libmpv-cffi:wait-event player :timeout 0.5d0)
      for event-id = (getf event :event-id)
      do (format t "Event: ~S~%" event)
      do (case event-id
           (:file-loaded
            (setf loaded-p t))
           ((:end-file :shutdown)
            (return event)))
      when (and (not loaded-p)
                (>= (get-universal-time) deadline))
        return (list :event-id :timeout))))

(defun main ()
  (format t "libmpv client API version: ~D~%" (cl-libmpv-cffi:api-version))
  (cl-libmpv-cffi:with-player (player :options '(("vo" . "gpu")
                                                 ("ao" . "pulse")))
    (format t "Client: ~A (~D)~%"
            (cl-libmpv-cffi:client-name player)
            (cl-libmpv-cffi:client-id player))
    (format t "Loading: ~A~%" *media-path*)
    (cl-libmpv-cffi:command player (list "loadfile" *media-path*))
    (let ((result (wait-for-playback-result player)))
      (format t "Playback result: ~S~%" result)
      result)))

(main)
