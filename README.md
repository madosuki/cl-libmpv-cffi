# cl-libmpv-cffi
unofficial wrapper of libmpv for Common Lisp

## Example

```lisp
(ql:quickload :cl-libmpv-cffi)

(cl-libmpv-cffi:with-player (player :options '(("vo" . "gpu")
                                               ("ao" . "pulse")))
  ;; Load a file. Command arguments are ordinary Lisp strings; the wrapper
  ;; allocates and frees the temporary C string vector internally.
  (cl-libmpv-cffi:command player '("loadfile" "/path/to/video.mp4"))

  ;; Read a property as a normal Common Lisp value.
  (format t "Paused: ~A~%"
          (cl-libmpv-cffi:get-property player "pause" :format :flag))

  ;; Poll one event. Event data is copied into Lisp lists/plists before return.
  (format t "Event: ~S~%"
          (cl-libmpv-cffi:wait-event player :timeout 0.0d0)))
```

For headless tests, use null outputs:

```lisp
(cl-libmpv-cffi:with-player (player :options '(("vo" . "null")
                                               ("ao" . "null")))
  (format t "Client: ~A (~D)~%"
          (cl-libmpv-cffi:client-name player)
          (cl-libmpv-cffi:client-id player)))
```
