(defpackage :cl-libmpv-cffi.binding
  (:use :cl :cffi)
  (:export
   ;; Library and constants
   #:libmpv
   #:+mpv-client-api-version+
   #:+mpv-render-api-type-opengl+
   #:+mpv-render-api-type-sw+
   ;; Types
   #:mpv-handle
   #:mpv-render-context
   #:mpv-error
   #:mpv-format
   #:mpv-event-id
   #:mpv-log-level
   #:mpv-end-file-reason
   #:mpv-render-param-type
   #:mpv-render-frame-info-flag
   #:mpv-render-context-flag
   #:mpv-node-u
   #:mpv-node
   #:mpv-node-list
   #:mpv-byte-array
   #:mpv-event-property
   #:mpv-event-log-message
   #:mpv-event-start-file
   #:mpv-event-end-file
   #:mpv-event-client-message
   #:mpv-event-hook
   #:mpv-event-command
   #:mpv-event
   #:mpv-render-param
   #:mpv-render-frame-info
   #:mpv-opengl-init-params
   #:mpv-opengl-fbo
   #:mpv-opengl-drm-params
   #:mpv-opengl-drm-draw-surface-size
   #:mpv-opengl-drm-params-v2
   ;; Functions
   #:mpv-client-api-version
   #:mpv-error-string
   #:mpv-free
   #:mpv-client-name
   #:mpv-client-id
   #:mpv-create
   #:mpv-initialize
   #:mpv-destroy
   #:mpv-terminate-destroy
   #:mpv-create-client
   #:mpv-create-weak-client
   #:mpv-load-config-file
   #:mpv-get-time-ns
   #:mpv-get-time-us
   #:mpv-free-node-contents
   #:mpv-set-option
   #:mpv-set-option-string
   #:mpv-command
   #:mpv-command-node
   #:mpv-command-ret
   #:mpv-command-string
   #:mpv-command-async
   #:mpv-command-node-async
   #:mpv-abort-async-command
   #:mpv-set-property
   #:mpv-set-property-string
   #:mpv-del-property
   #:mpv-set-property-async
   #:mpv-get-property
   #:mpv-get-property-string
   #:mpv-get-property-osd-string
   #:mpv-get-property-async
   #:mpv-observe-property
   #:mpv-unobserve-property
   #:mpv-event-name
   #:mpv-event-to-node
   #:mpv-request-event
   #:mpv-request-log-messages
   #:mpv-wait-event
   #:mpv-wakeup
   #:mpv-set-wakeup-callback
   #:mpv-wait-async-requests
   #:mpv-hook-add
   #:mpv-hook-continue
   #:mpv-get-wakeup-pipe
   #:mpv-render-context-create
   #:mpv-render-context-set-parameter
   #:mpv-render-context-get-info
   #:mpv-render-context-set-update-callback
   #:mpv-render-context-update
   #:mpv-render-context-render
   #:mpv-render-context-report-swap
   #:mpv-render-context-free))

(in-package :cl-libmpv-cffi.binding)

(define-foreign-library libmpv
  (:darwin (:or "libmpv.2.dylib" "libmpv.dylib"))
  (:unix (:or "libmpv.so.2" "libmpv.so"))
  (:windows (:or "mpv-2.dll" "libmpv-2.dll"))
  (t (:default "libmpv")))

(use-foreign-library libmpv)

(defconstant +mpv-client-api-version+ #x00020005)
(defparameter +mpv-render-api-type-opengl+ "opengl")
(defparameter +mpv-render-api-type-sw+ "sw")

(defctype mpv-handle :pointer)
(defctype mpv-render-context :pointer)

(defcenum mpv-error
  (:success 0)
  (:event-queue-full -1)
  (:nomem -2)
  (:uninitialized -3)
  (:invalid-parameter -4)
  (:option-not-found -5)
  (:option-format -6)
  (:option-error -7)
  (:property-not-found -8)
  (:property-format -9)
  (:property-unavailable -10)
  (:property-error -11)
  (:command -12)
  (:loading-failed -13)
  (:ao-init-failed -14)
  (:vo-init-failed -15)
  (:nothing-to-play -16)
  (:unknown-format -17)
  (:unsupported -18)
  (:not-implemented -19)
  (:generic -20))

(defcenum mpv-format
  (:none 0)
  (:string 1)
  (:osd-string 2)
  (:flag 3)
  (:int64 4)
  (:double 5)
  (:node 6)
  (:node-array 7)
  (:node-map 8)
  (:byte-array 9))

(defcunion mpv-node-u
  (string :pointer)
  (flag :int)
  (int64 :int64)
  (double :double)
  (list :pointer)
  (ba :pointer))

(defcstruct mpv-node
  (u (:union mpv-node-u))
  (format mpv-format))

(defcstruct mpv-node-list
  (num :int)
  (values :pointer)
  (keys :pointer))

(defcstruct mpv-byte-array
  (data :pointer)
  (size :size))

(defcenum mpv-event-id
  (:none 0)
  (:shutdown 1)
  (:log-message 2)
  (:get-property-reply 3)
  (:set-property-reply 4)
  (:command-reply 5)
  (:start-file 6)
  (:end-file 7)
  (:file-loaded 8)
  (:idle 11)
  (:tick 14)
  (:client-message 16)
  (:video-reconfig 17)
  (:audio-reconfig 18)
  (:seek 20)
  (:playback-restart 21)
  (:property-change 22)
  (:queue-overflow 24)
  (:hook 25))

(defcstruct mpv-event-property
  (name :pointer)
  (format mpv-format)
  (data :pointer))

(defcenum mpv-log-level
  (:none 0)
  (:fatal 10)
  (:error 20)
  (:warn 30)
  (:info 40)
  (:v 50)
  (:debug 60)
  (:trace 70))

(defcstruct mpv-event-log-message
  (prefix :pointer)
  (level :pointer)
  (text :pointer)
  (log-level mpv-log-level))

(defcenum mpv-end-file-reason
  (:eof 0)
  (:stop 2)
  (:quit 3)
  (:error 4)
  (:redirect 5))

(defcstruct mpv-event-start-file
  (playlist-entry-id :int64))

(defcstruct mpv-event-end-file
  (reason mpv-end-file-reason)
  (error :int)
  (playlist-entry-id :int64)
  (playlist-insert-id :int64)
  (playlist-insert-num-entries :int))

(defcstruct mpv-event-client-message
  (num-args :int)
  (args :pointer))

(defcstruct mpv-event-hook
  (name :pointer)
  (id :uint64))

(defcstruct mpv-event-command
  (result (:struct mpv-node)))

(defcstruct mpv-event
  (event-id mpv-event-id)
  (error :int)
  (reply-userdata :uint64)
  (data :pointer))

(defcenum mpv-render-param-type
  (:invalid 0)
  (:api-type 1)
  (:opengl-init-params 2)
  (:opengl-fbo 3)
  (:flip-y 4)
  (:depth 5)
  (:icc-profile 6)
  (:ambient-light 7)
  (:x11-display 8)
  (:wl-display 9)
  (:advanced-control 10)
  (:next-frame-info 11)
  (:block-for-target-time 12)
  (:skip-rendering 13)
  (:drm-display 14)
  (:drm-draw-surface-size 15)
  (:drm-display-v2 16)
  (:sw-size 17)
  (:sw-format 18)
  (:sw-stride 19)
  (:sw-pointer 20))

(defcstruct mpv-render-param
  (type mpv-render-param-type)
  (data :pointer))

(defcenum mpv-render-frame-info-flag
  (:present 1)
  (:redraw 2)
  (:repeat 4)
  (:block-vsync 8))

(defcstruct mpv-render-frame-info
  (flags :uint64)
  (target-time :int64))

(defcenum mpv-render-context-flag
  (:frame 1))

(defcstruct mpv-opengl-init-params
  (get-proc-address :pointer)
  (get-proc-address-ctx :pointer))

(defcstruct mpv-opengl-fbo
  (fbo :int)
  (w :int)
  (h :int)
  (internal-format :int))

(defcstruct mpv-opengl-drm-params
  (fd :int)
  (crtc-id :int)
  (connector-id :int)
  (atomic-request-ptr :pointer)
  (render-fd :int))

(defcstruct mpv-opengl-drm-draw-surface-size
  (width :int)
  (height :int))

(defcstruct mpv-opengl-drm-params-v2
  (fd :int)
  (crtc-id :int)
  (connector-id :int)
  (atomic-request-ptr :pointer)
  (render-fd :int))

(defcfun ("mpv_client_api_version" mpv-client-api-version) :ulong)
(defcfun ("mpv_error_string" mpv-error-string) :string
  (error :int))
(defcfun ("mpv_free" mpv-free) :void
  (data :pointer))
(defcfun ("mpv_client_name" mpv-client-name) :string
  (ctx mpv-handle))
(defcfun ("mpv_client_id" mpv-client-id) :int64
  (ctx mpv-handle))
(defcfun ("mpv_create" mpv-create) mpv-handle)
(defcfun ("mpv_initialize" mpv-initialize) :int
  (ctx mpv-handle))
(defcfun ("mpv_destroy" mpv-destroy) :void
  (ctx mpv-handle))
(defcfun ("mpv_terminate_destroy" mpv-terminate-destroy) :void
  (ctx mpv-handle))
(defcfun ("mpv_create_client" mpv-create-client) mpv-handle
  (ctx mpv-handle)
  (name :string))
(defcfun ("mpv_create_weak_client" mpv-create-weak-client) mpv-handle
  (ctx mpv-handle)
  (name :string))
(defcfun ("mpv_load_config_file" mpv-load-config-file) :int
  (ctx mpv-handle)
  (filename :string))
(defcfun ("mpv_get_time_ns" mpv-get-time-ns) :int64
  (ctx mpv-handle))
(defcfun ("mpv_get_time_us" mpv-get-time-us) :int64
  (ctx mpv-handle))
(defcfun ("mpv_free_node_contents" mpv-free-node-contents) :void
  (node :pointer))
(defcfun ("mpv_set_option" mpv-set-option) :int
  (ctx mpv-handle)
  (name :string)
  (format mpv-format)
  (data :pointer))
(defcfun ("mpv_set_option_string" mpv-set-option-string) :int
  (ctx mpv-handle)
  (name :string)
  (data :string))
(defcfun ("mpv_command" mpv-command) :int
  (ctx mpv-handle)
  (args :pointer))
(defcfun ("mpv_command_node" mpv-command-node) :int
  (ctx mpv-handle)
  (args :pointer)
  (result :pointer))
(defcfun ("mpv_command_ret" mpv-command-ret) :int
  (ctx mpv-handle)
  (args :pointer)
  (result :pointer))
(defcfun ("mpv_command_string" mpv-command-string) :int
  (ctx mpv-handle)
  (args :string))
(defcfun ("mpv_command_async" mpv-command-async) :int
  (ctx mpv-handle)
  (reply-userdata :uint64)
  (args :pointer))
(defcfun ("mpv_command_node_async" mpv-command-node-async) :int
  (ctx mpv-handle)
  (reply-userdata :uint64)
  (args :pointer))
(defcfun ("mpv_abort_async_command" mpv-abort-async-command) :void
  (ctx mpv-handle)
  (reply-userdata :uint64))
(defcfun ("mpv_set_property" mpv-set-property) :int
  (ctx mpv-handle)
  (name :string)
  (format mpv-format)
  (data :pointer))
(defcfun ("mpv_set_property_string" mpv-set-property-string) :int
  (ctx mpv-handle)
  (name :string)
  (data :string))
(defcfun ("mpv_del_property" mpv-del-property) :int
  (ctx mpv-handle)
  (name :string))
(defcfun ("mpv_set_property_async" mpv-set-property-async) :int
  (ctx mpv-handle)
  (reply-userdata :uint64)
  (name :string)
  (format mpv-format)
  (data :pointer))
(defcfun ("mpv_get_property" mpv-get-property) :int
  (ctx mpv-handle)
  (name :string)
  (format mpv-format)
  (data :pointer))
(defcfun ("mpv_get_property_string" mpv-get-property-string) :pointer
  (ctx mpv-handle)
  (name :string))
(defcfun ("mpv_get_property_osd_string" mpv-get-property-osd-string) :pointer
  (ctx mpv-handle)
  (name :string))
(defcfun ("mpv_get_property_async" mpv-get-property-async) :int
  (ctx mpv-handle)
  (reply-userdata :uint64)
  (name :string)
  (format mpv-format))
(defcfun ("mpv_observe_property" mpv-observe-property) :int
  (mpv mpv-handle)
  (reply-userdata :uint64)
  (name :string)
  (format mpv-format))
(defcfun ("mpv_unobserve_property" mpv-unobserve-property) :int
  (mpv mpv-handle)
  (registered-reply-userdata :uint64))
(defcfun ("mpv_event_name" mpv-event-name) :string
  (event mpv-event-id))
(defcfun ("mpv_event_to_node" mpv-event-to-node) :int
  (dst :pointer)
  (src :pointer))
(defcfun ("mpv_request_event" mpv-request-event) :int
  (ctx mpv-handle)
  (event mpv-event-id)
  (enable :int))
(defcfun ("mpv_request_log_messages" mpv-request-log-messages) :int
  (ctx mpv-handle)
  (min-level :string))
(defcfun ("mpv_wait_event" mpv-wait-event) :pointer
  (ctx mpv-handle)
  (timeout :double))
(defcfun ("mpv_wakeup" mpv-wakeup) :void
  (ctx mpv-handle))
(defcfun ("mpv_set_wakeup_callback" mpv-set-wakeup-callback) :void
  (ctx mpv-handle)
  (cb :pointer)
  (d :pointer))
(defcfun ("mpv_wait_async_requests" mpv-wait-async-requests) :void
  (ctx mpv-handle))
(defcfun ("mpv_hook_add" mpv-hook-add) :int
  (ctx mpv-handle)
  (reply-userdata :uint64)
  (name :string)
  (priority :int))
(defcfun ("mpv_hook_continue" mpv-hook-continue) :int
  (ctx mpv-handle)
  (id :uint64))
(defcfun ("mpv_get_wakeup_pipe" mpv-get-wakeup-pipe) :int
  (ctx mpv-handle))

(defcfun ("mpv_render_context_create" mpv-render-context-create) :int
  (res :pointer)
  (mpv mpv-handle)
  (params :pointer))
(defcfun ("mpv_render_context_set_parameter" mpv-render-context-set-parameter) :int
  (ctx mpv-render-context)
  (param (:struct mpv-render-param)))
(defcfun ("mpv_render_context_get_info" mpv-render-context-get-info) :int
  (ctx mpv-render-context)
  (param (:struct mpv-render-param)))
(defcfun ("mpv_render_context_set_update_callback" mpv-render-context-set-update-callback) :void
  (ctx mpv-render-context)
  (callback :pointer)
  (callback-ctx :pointer))
(defcfun ("mpv_render_context_update" mpv-render-context-update) :uint64
  (ctx mpv-render-context))
(defcfun ("mpv_render_context_render" mpv-render-context-render) :int
  (ctx mpv-render-context)
  (params :pointer))
(defcfun ("mpv_render_context_report_swap" mpv-render-context-report-swap) :void
  (ctx mpv-render-context))
(defcfun ("mpv_render_context_free" mpv-render-context-free) :void
  (ctx mpv-render-context))
