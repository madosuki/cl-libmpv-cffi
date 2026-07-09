(in-package :cl-libmpv-cffi)

(defconstant +success+ 0)

(defmacro %with-mpv-float-traps-masked (&body body)
  #+sbcl
  `(sb-int:with-float-traps-masked (:invalid :inexact :overflow :underflow
                                    :divide-by-zero)
     ,@body)
  #-sbcl
  `(progn ,@body))

(define-condition mpv-error (error)
  ((code :initarg :code :reader mpv-error-code)
   (message :initarg :message :reader mpv-error-message))
  (:report (lambda (condition stream)
             (format stream "libmpv error ~D: ~A"
                     (mpv-error-code condition)
                     (mpv-error-message condition)))))

(defclass mpv-player ()
  ((handle :initarg :handle :accessor %player-handle)
   (destroyed-p :initform nil :accessor player-destroyed-p)))

(defun api-version ()
  "Return the libmpv client API version as an integer."
  (cl-libmpv-cffi.binding:mpv-client-api-version))

(defun %error-message (code)
  (or (cl-libmpv-cffi.binding:mpv-error-string code)
      "unknown error"))

(defun %check-error (code)
  (when (< code +success+)
    (error 'mpv-error :code code :message (%error-message code)))
  code)

(defun %ensure-player (player)
  (check-type player mpv-player)
  (when (player-destroyed-p player)
    (error "The mpv player has already been destroyed."))
  (%player-handle player))

(defun %normalize-string (value)
  (etypecase value
    (string value)
    (symbol (string-downcase value))
    (integer (write-to-string value))
    (float (write-to-string value))))

(defun make-player (&key options (initialize t))
  "Create an mpv player.

OPTIONS is an alist of option names and values. Values are passed through
mpv_set_option_string after conversion to strings. No foreign pointer is
exposed by this constructor."
  (let ((handle (%with-mpv-float-traps-masked
                 (cl-libmpv-cffi.binding:mpv-create))))
    (when (cffi:null-pointer-p handle)
      (error "mpv_create returned NULL."))
    (let ((player (make-instance 'mpv-player :handle handle)))
      (handler-case
          (progn
            (dolist (option options)
              (set-option player (car option) (cdr option)))
            (when initialize
              (initialize-player player))
            player)
        (error (condition)
          (cl-libmpv-cffi.binding:mpv-terminate-destroy handle)
          (setf (player-destroyed-p player) t)
          (error condition))))))

(defmacro with-player ((var &rest args) &body body)
  "Bind VAR to a player and always terminate/destroy it on exit."
  `(let ((,var (make-player ,@args)))
     (unwind-protect
          (progn ,@body)
       (unless (player-destroyed-p ,var)
         (destroy-player ,var :terminate t)))))

(defun initialize-player (player)
  (let ((handle (%ensure-player player)))
    (%check-error (cl-libmpv-cffi.binding:mpv-initialize handle)))
  player)

(defun destroy-player (player &key terminate)
  "Destroy PLAYER. TERMINATE asks libmpv to quit the core before detaching."
  (check-type player mpv-player)
  (unless (player-destroyed-p player)
    (let ((handle (%player-handle player)))
      (if terminate
          (cl-libmpv-cffi.binding:mpv-terminate-destroy handle)
          (cl-libmpv-cffi.binding:mpv-destroy handle)))
    (setf (player-destroyed-p player) t))
  nil)

(defun client-name (player)
  (cl-libmpv-cffi.binding:mpv-client-name (%ensure-player player)))

(defun client-id (player)
  (cl-libmpv-cffi.binding:mpv-client-id (%ensure-player player)))

(defun set-option (player name value)
  (%check-error
   (cl-libmpv-cffi.binding:mpv-set-option-string
    (%ensure-player player)
    (%normalize-string name)
    (%normalize-string value))))

(defun set-property (player name value &key (format :string))
  "Set an mpv property.

FORMAT may be :string, :flag, :int64, or :double. Values are copied into
temporary foreign storage only for the duration of the call."
  (let ((handle (%ensure-player player))
        (name (%normalize-string name)))
    (ecase format
      (:string
       (%check-error
        (cl-libmpv-cffi.binding:mpv-set-property-string
         handle name (%normalize-string value))))
      (:flag
       (cffi:with-foreign-object (ptr :int)
         (setf (cffi:mem-ref ptr :int) (if value 1 0))
         (%check-error
          (cl-libmpv-cffi.binding:mpv-set-property handle name :flag ptr))))
      (:int64
       (cffi:with-foreign-object (ptr :int64)
         (setf (cffi:mem-ref ptr :int64) value)
         (%check-error
          (cl-libmpv-cffi.binding:mpv-set-property handle name :int64 ptr))))
      (:double
       (cffi:with-foreign-object (ptr :double)
         (setf (cffi:mem-ref ptr :double) value)
         (%check-error
          (cl-libmpv-cffi.binding:mpv-set-property handle name :double ptr)))))))

(defun get-property-string (player name &key osd)
  "Return a property string as a Lisp string, or NIL if libmpv returns NULL."
  (let* ((handle (%ensure-player player))
         (ptr (if osd
                  (cl-libmpv-cffi.binding:mpv-get-property-osd-string
                   handle (%normalize-string name))
                  (cl-libmpv-cffi.binding:mpv-get-property-string
                   handle (%normalize-string name)))))
    (unless (cffi:null-pointer-p ptr)
      (unwind-protect
           (cffi:foreign-string-to-lisp ptr)
        (cl-libmpv-cffi.binding:mpv-free ptr)))))

(defun get-property (player name &key (format :string))
  "Get an mpv property as a Lisp value.

FORMAT may be :string, :osd-string, :flag, :int64, :double, or :node. :node
returns a recursively copied Lisp representation and frees libmpv-owned node
contents before returning."
  (let ((handle (%ensure-player player))
        (name (%normalize-string name)))
    (ecase format
      (:string (get-property-string player name))
      (:osd-string (get-property-string player name :osd t))
      (:flag
       (cffi:with-foreign-object (ptr :int)
         (%check-error
          (cl-libmpv-cffi.binding:mpv-get-property handle name :flag ptr))
         (not (zerop (cffi:mem-ref ptr :int)))))
      (:int64
       (cffi:with-foreign-object (ptr :int64)
         (%check-error
          (cl-libmpv-cffi.binding:mpv-get-property handle name :int64 ptr))
         (cffi:mem-ref ptr :int64)))
      (:double
       (cffi:with-foreign-object (ptr :double)
         (%check-error
          (cl-libmpv-cffi.binding:mpv-get-property handle name :double ptr))
         (cffi:mem-ref ptr :double)))
      (:node
       (cffi:with-foreign-object (node '(:struct cl-libmpv-cffi.binding:mpv-node))
         (%check-error
          (cl-libmpv-cffi.binding:mpv-get-property handle name :node node))
         (unwind-protect
              (%node-to-lisp node)
           (cl-libmpv-cffi.binding:mpv-free-node-contents node)))))))

(defun %with-string-vector (strings thunk)
  (let ((foreign-strings nil))
    (unwind-protect
         (progn
           (let ((normalized (mapcar #'%normalize-string strings)))
             (cffi:with-foreign-object (argv :pointer (1+ (length normalized)))
               (loop for string in normalized
                     for i from 0
                     for foreign = (cffi:foreign-string-alloc string)
                     do (push foreign foreign-strings)
                        (setf (cffi:mem-aref argv :pointer i) foreign))
               (setf (cffi:mem-aref argv :pointer (length normalized))
                     (cffi:null-pointer))
               (funcall thunk argv))))
      (dolist (ptr foreign-strings)
        (cffi:foreign-string-free ptr)))))

(defun command (player args)
  "Run an mpv command from a list of strings/symbols/numbers."
  (%with-string-vector
   args
   (lambda (argv)
     (%check-error
      (cl-libmpv-cffi.binding:mpv-command (%ensure-player player) argv)))))

(defun command-string (player string)
  "Run an mpv command using mpv's command string parser."
  (%check-error
   (cl-libmpv-cffi.binding:mpv-command-string
    (%ensure-player player)
    string)))

(defun command-async (player reply-userdata args)
  "Queue an asynchronous command. REPLY-USERDATA is returned in later events."
  (%with-string-vector
   args
   (lambda (argv)
     (%check-error
      (cl-libmpv-cffi.binding:mpv-command-async
       (%ensure-player player)
       reply-userdata
       argv)))))

(defun observe-property (player reply-userdata name &key (format :none))
  (%check-error
   (cl-libmpv-cffi.binding:mpv-observe-property
    (%ensure-player player)
    reply-userdata
    (%normalize-string name)
    format)))

(defun unobserve-property (player reply-userdata)
  (%check-error
   (cl-libmpv-cffi.binding:mpv-unobserve-property
    (%ensure-player player)
    reply-userdata)))

(defun request-event (player event enable)
  (%check-error
   (cl-libmpv-cffi.binding:mpv-request-event
    (%ensure-player player)
    event
    (if enable 1 0))))

(defun request-log-messages (player min-level)
  (%check-error
   (cl-libmpv-cffi.binding:mpv-request-log-messages
    (%ensure-player player)
    (%normalize-string min-level))))

(defun wait-event (player &key (timeout 0.0d0))
  "Wait for and return the next event as a plist.

All known event data is copied into Lisp objects before returning. No pointer
inside libmpv's event queue is exposed."
  (%event-to-lisp
   (cl-libmpv-cffi.binding:mpv-wait-event
    (%ensure-player player)
    (coerce timeout 'double-float))))

(defun wakeup (player)
  (cl-libmpv-cffi.binding:mpv-wakeup (%ensure-player player))
  nil)

(defun wait-async-requests (player)
  (cl-libmpv-cffi.binding:mpv-wait-async-requests (%ensure-player player))
  nil)

(defun hook-add (player reply-userdata name &key (priority 0))
  (%check-error
   (cl-libmpv-cffi.binding:mpv-hook-add
    (%ensure-player player)
    reply-userdata
    (%normalize-string name)
    priority)))

(defun hook-continue (player id)
  (%check-error
   (cl-libmpv-cffi.binding:mpv-hook-continue (%ensure-player player) id)))

(defun %nullable-string (ptr)
  (unless (cffi:null-pointer-p ptr)
    (cffi:foreign-string-to-lisp ptr)))

(defun %node-format (node)
  (cffi:foreign-slot-value node '(:struct cl-libmpv-cffi.binding:mpv-node)
                           'cl-libmpv-cffi.binding::format))

(defun %node-union-pointer (node)
  (cffi:foreign-slot-pointer node '(:struct cl-libmpv-cffi.binding:mpv-node)
                             'cl-libmpv-cffi.binding::u))

(defun %node-list-to-lisp (list-ptr map-p)
  (let* ((num (cffi:foreign-slot-value
               list-ptr '(:struct cl-libmpv-cffi.binding:mpv-node-list)
               'cl-libmpv-cffi.binding::num))
         (values (cffi:foreign-slot-value
                  list-ptr '(:struct cl-libmpv-cffi.binding:mpv-node-list)
                  'cl-libmpv-cffi.binding::values))
         (keys (cffi:foreign-slot-value
                list-ptr '(:struct cl-libmpv-cffi.binding:mpv-node-list)
                'cl-libmpv-cffi.binding::keys)))
    (loop for i below num
          for node = (cffi:mem-aptr values
                                    '(:struct cl-libmpv-cffi.binding:mpv-node)
                                    i)
          for value = (%node-to-lisp node)
          if map-p
            collect (cons (cffi:foreign-string-to-lisp
                           (cffi:mem-aref keys :pointer i))
                          value)
          else
            collect value)))

(defun %byte-array-to-lisp (ba-ptr)
  (let* ((data (cffi:foreign-slot-value
                ba-ptr '(:struct cl-libmpv-cffi.binding:mpv-byte-array)
                'cl-libmpv-cffi.binding::data))
         (size (cffi:foreign-slot-value
                ba-ptr '(:struct cl-libmpv-cffi.binding:mpv-byte-array)
                'cl-libmpv-cffi.binding::size)))
    (let ((bytes (make-array size :element-type '(unsigned-byte 8))))
      (loop for i below size
            do (setf (aref bytes i) (cffi:mem-aref data :uint8 i)))
      bytes)))

(defun %node-to-lisp (node)
  (let ((format (%node-format node))
        (u (%node-union-pointer node)))
    (ecase format
      (:none nil)
      (:string (%nullable-string
                (cffi:foreign-slot-value
                 u '(:union cl-libmpv-cffi.binding:mpv-node-u)
                 'cl-libmpv-cffi.binding::string)))
      (:flag (not (zerop
                   (cffi:foreign-slot-value
                    u '(:union cl-libmpv-cffi.binding:mpv-node-u)
                    'cl-libmpv-cffi.binding::flag))))
      (:int64 (cffi:foreign-slot-value
               u '(:union cl-libmpv-cffi.binding:mpv-node-u)
               'cl-libmpv-cffi.binding::int64))
      (:double (cffi:foreign-slot-value
                u '(:union cl-libmpv-cffi.binding:mpv-node-u)
                'cl-libmpv-cffi.binding::double))
      (:node-array
       (%node-list-to-lisp
        (cffi:foreign-slot-value
         u '(:union cl-libmpv-cffi.binding:mpv-node-u)
         'cl-libmpv-cffi.binding::list)
        nil))
      (:node-map
       (%node-list-to-lisp
        (cffi:foreign-slot-value
         u '(:union cl-libmpv-cffi.binding:mpv-node-u)
         'cl-libmpv-cffi.binding::list)
        t))
      (:byte-array
       (%byte-array-to-lisp
        (cffi:foreign-slot-value
         u '(:union cl-libmpv-cffi.binding:mpv-node-u)
         'cl-libmpv-cffi.binding::ba))))))

(defun %event-to-lisp (event)
  (let* ((event-id (cffi:foreign-slot-value
                    event '(:struct cl-libmpv-cffi.binding:mpv-event)
                    'cl-libmpv-cffi.binding::event-id))
         (error-code (cffi:foreign-slot-value
                      event '(:struct cl-libmpv-cffi.binding:mpv-event)
                      'cl-libmpv-cffi.binding::error))
         (reply-userdata (cffi:foreign-slot-value
                          event '(:struct cl-libmpv-cffi.binding:mpv-event)
                          'cl-libmpv-cffi.binding::reply-userdata))
         (data (cffi:foreign-slot-value
                event '(:struct cl-libmpv-cffi.binding:mpv-event)
                'cl-libmpv-cffi.binding::data)))
    (list :event-id event-id
          :error error-code
          :reply-userdata reply-userdata
          :data (%event-data-to-lisp event-id data))))

(defun %event-data-to-lisp (event-id data)
  (when (cffi:null-pointer-p data)
    (return-from %event-data-to-lisp nil))
  (case event-id
    ((:get-property-reply :property-change)
     (let ((format (cffi:foreign-slot-value
                    data '(:struct cl-libmpv-cffi.binding:mpv-event-property)
                    'cl-libmpv-cffi.binding::format))
           (value-ptr (cffi:foreign-slot-value
                       data '(:struct cl-libmpv-cffi.binding:mpv-event-property)
                       'cl-libmpv-cffi.binding::data)))
       (list :name (%nullable-string
                    (cffi:foreign-slot-value
                     data '(:struct cl-libmpv-cffi.binding:mpv-event-property)
                     'cl-libmpv-cffi.binding::name))
             :format format
             :value (%property-event-value format value-ptr))))
    (:log-message
     (list :prefix (%nullable-string
                    (cffi:foreign-slot-value
                     data '(:struct cl-libmpv-cffi.binding:mpv-event-log-message)
                     'cl-libmpv-cffi.binding::prefix))
           :level (%nullable-string
                   (cffi:foreign-slot-value
                    data '(:struct cl-libmpv-cffi.binding:mpv-event-log-message)
                    'cl-libmpv-cffi.binding::level))
           :text (%nullable-string
                  (cffi:foreign-slot-value
                   data '(:struct cl-libmpv-cffi.binding:mpv-event-log-message)
                   'cl-libmpv-cffi.binding::text))
           :log-level (cffi:foreign-slot-value
                       data '(:struct cl-libmpv-cffi.binding:mpv-event-log-message)
                       'cl-libmpv-cffi.binding::log-level)))
    (:start-file
     (list :playlist-entry-id
           (cffi:foreign-slot-value
            data '(:struct cl-libmpv-cffi.binding:mpv-event-start-file)
            'cl-libmpv-cffi.binding::playlist-entry-id)))
    (:end-file
     (list :reason (cffi:foreign-slot-value
                    data '(:struct cl-libmpv-cffi.binding:mpv-event-end-file)
                    'cl-libmpv-cffi.binding::reason)
           :error (cffi:foreign-slot-value
                   data '(:struct cl-libmpv-cffi.binding:mpv-event-end-file)
                   'cl-libmpv-cffi.binding::error)
           :playlist-entry-id
           (cffi:foreign-slot-value
            data '(:struct cl-libmpv-cffi.binding:mpv-event-end-file)
            'cl-libmpv-cffi.binding::playlist-entry-id)
           :playlist-insert-id
           (cffi:foreign-slot-value
            data '(:struct cl-libmpv-cffi.binding:mpv-event-end-file)
            'cl-libmpv-cffi.binding::playlist-insert-id)
           :playlist-insert-num-entries
           (cffi:foreign-slot-value
            data '(:struct cl-libmpv-cffi.binding:mpv-event-end-file)
            'cl-libmpv-cffi.binding::playlist-insert-num-entries)))
    (:client-message
     (let ((num-args (cffi:foreign-slot-value
                      data '(:struct cl-libmpv-cffi.binding:mpv-event-client-message)
                      'cl-libmpv-cffi.binding::num-args))
           (args (cffi:foreign-slot-value
                  data '(:struct cl-libmpv-cffi.binding:mpv-event-client-message)
                  'cl-libmpv-cffi.binding::args)))
       (loop for i below num-args
             collect (cffi:foreign-string-to-lisp
                      (cffi:mem-aref args :pointer i)))))
    (:hook
     (list :name (%nullable-string
                  (cffi:foreign-slot-value
                   data '(:struct cl-libmpv-cffi.binding:mpv-event-hook)
                   'cl-libmpv-cffi.binding::name))
           :id (cffi:foreign-slot-value
                data '(:struct cl-libmpv-cffi.binding:mpv-event-hook)
                'cl-libmpv-cffi.binding::id)))
    (:command-reply
     (let ((node (cffi:foreign-slot-pointer
                  data '(:struct cl-libmpv-cffi.binding:mpv-event-command)
                  'cl-libmpv-cffi.binding::result)))
       (%node-to-lisp node)))
    (otherwise nil)))

(defun %property-event-value (format ptr)
  (if (or (eq format :none) (cffi:null-pointer-p ptr))
      nil
      (ecase format
        (:string (%nullable-string (cffi:mem-ref ptr :pointer)))
        (:osd-string (%nullable-string (cffi:mem-ref ptr :pointer)))
        (:flag (not (zerop (cffi:mem-ref ptr :int))))
        (:int64 (cffi:mem-ref ptr :int64))
        (:double (cffi:mem-ref ptr :double))
        (:node (%node-to-lisp ptr))
        (:node-array (%node-to-lisp ptr))
        (:node-map (%node-to-lisp ptr))
        (:byte-array (%node-to-lisp ptr)))))
