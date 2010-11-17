(in-package :op-annotate)

(defparameter *fb-app-id* "157190964324203")
(defparameter *fb-api-key* "a80e37d96fba0e0953becb88341b851a")
(defparameter *fb-secret* "402d680be36dfff3d591682715dcb194")


(defclass user ()
  ((facebook-session :initarg :facebook-session :initform nil :accessor user-facebook-session
                     :documentation "Facebook session object that can be used
to used to post things to facebook.")
   (facebook-uid :initarg :facebook-uid :initform nil :accessor user-facebook-uid
                 :index t
                 :documentation "Facebook user id.  Integer.")
   (email :initarg :email :accessor usermail :initform nil :accessor user-email
          :index t
          :documentation "A user's email address")
   (registration-time :initarg :registration-time :initform nil :accessor user-registration-time
                      :index t
                      :documentation "Set the user's "))
  (:metaclass ele:persistent-metaclass))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; function and method implementations
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defmacro nontrivial-setf (place value &rest etc)
  "Like SETF, but first tests the place for a non-null value, and then
checks the value being assigned for anon-null value.  Note that due to
the complexities of SETF, this function uses the place form twice
without ensuring that subforms are  only evaluated once."
  `(progn
     ,(once-only ((place-now place))
        `(when (not ,place-now)
           ,(once-only (value)
              `(when ,value
                 (setf ,place ,value)))))
     ,@(when etc
         (list `(nontrivial-setf ,@etc)))))


(defun update-user-with-facebook (user)
  "Infers information about a user from facebook, and sets the
appropriate slots etc. in the database regarding the user."
  (multiple-value-bind (email)
      (infer-user-details-from-facebook user)

    (nontrivial-setf (user-email user) email)))

(defun infer-user-details-from-facebook (user)
  "Infers the user's university and email from the Facebook session
attached to the user, and returns them as multiple values."
  (when-let* ((user user)
              (fb-session (user-facebook-session user))
              (me (facebook::graph-request fb-session "/me")))
    (cdr (assoc :email me))))

(defun user-from-request (request &key (create? t) (update? t) (update-session? t))
  "Returns a user from the cookies embedded in the HTTP request, or
creates one if the user is logged in."
  (declare (optimize (debug 3)))
  (ele:ensure-transaction ()
    (let* ((cookie-header (hunchentoot:header-in "Cookie" request))
           (fb-session (and cookie-header
                            (facebook:session-from-connect-cookies
                             cookie-header *fb-api-key* *fb-secret* :app-id *fb-app-id*)))
           (existing-user (acond
                            (fb-session
                             (ele:get-instance-by-value 'user 'facebook-uid
                                                        (facebook:uid fb-session)))
                            ((hunchentoot:session-value 'user-oid)
                             (get-instance-by-oid it 'user)))))
      ;(defparameter *cookies* cookie-header)
      ;(format *wiretap* "~A ~A ~A" fb-session
      (when (and existing-user
                 fb-session
                 (or (not (user-facebook-session existing-user))
                     (not (eql (facebook:expires (user-facebook-session existing-user))
                               (facebook:expires fb-session)))))
        (setf (user-facebook-uid existing-user) (facebook:uid fb-session)
              (user-facebook-session existing-user) fb-session))
      
      (cond
        ((and (not existing-user) create?)
         (setf existing-user
               (make-instance 'user
                              :facebook-uid (when fb-session (facebook:uid fb-session))
                              :facebook-session fb-session)))

        ((and update? existing-user) (update-user-with-facebook existing-user)))

      (when (and existing-user update-session?)
        (setf (hunchentoot:session-value 'user-oid) (oid existing-user)))

      (setf *user* existing-user)

      existing-user)))

(defvar *user* nil)

(defun user-admin? (user)
  (eql 213690 (user-facebook-uid user)))

(defmacro with-user ((user-var &key (request 'hunchentoot:*request*) (create? t)) &body body)
  `(let* ((,user-var (user-from-request ,request :create? ,create?))
          (*user* ,user-var))
     (declare (special *user*))
     ,@body))

(defun get-instance-by-oid (oid &optional class)
  (let ((instance (ele::controller-recreate-instance ele:*store-controller* oid)))
    (when (and instance (or (null class) (typep instance class)))
      instance)))

(defun oid (obj)
  (when obj
    (ele::oid obj)))