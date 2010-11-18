(in-package :op-annotate)

(webfunk:web-defun admin-scrape-article (url force)
  (setf (hunchentoot:content-type*) "text/plain")
  (aif (with-user (user)
         (when (user-admin? user)
           (let ((article (download-article url :force (not (not force)))))
             (hunchentoot:redirect (article-local-url article))
             (format nil "Redirecting to \"~A\"" (article-title article)))))
       it
       "No access!"))