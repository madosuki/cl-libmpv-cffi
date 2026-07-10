(defpackage :cl-libmpv-cffi
  (:use :cl)
  ;; Public wrapper API only. Do not export CFFI pointers, foreign structs, or
  ;; raw mpv handles here unless the libmpv API cannot be represented safely in
  ;; Lisp; if that becomes necessary, document the lifetime rule at the export.
  (:export
   #:mpv-error
   #:mpv-error-code
   #:mpv-error-message
   #:mpv-player
   #:make-player
   #:with-player
   #:initialize-player
   #:destroy-player
   #:player-destroyed-p
   #:client-name
   #:client-id
   #:api-version
   #:set-option
   #:set-property
   #:get-property
   #:get-property-string
   #:command
   #:command-string
   #:command-async
   #:observe-property
   #:unobserve-property
   #:request-event
   #:request-log-messages
   #:wait-event
   #:wakeup
   #:wait-async-requests
   #:hook-add
   #:hook-continue
   #:mpv-render-context
   #:make-opengl-render-context
   #:with-opengl-render-context
   #:destroy-render-context
   #:render-context-destroyed-p
   #:set-render-update-callback
   #:render-context-update
   #:render-context-next-frame-info
   #:render-opengl
   #:render-context-report-swap))

(in-package :cl-libmpv-cffi)
