(defpackage :op-annotate
  (:use :cl :anaphora :alexandria)
  (:export ))

(in-package :op-annotate)
  

(webfunk:web-defpackage :op-annotate
  (:rootp t)
  (:root-function-name articles)
  (:lisp-packages :op-annotate))

