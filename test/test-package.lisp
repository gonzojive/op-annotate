(defpackage :op-annotate-tests
  (:use :cl :anaphora :hu.dwim.stefil :op-annotate)
  (:export #:run-tests))

(in-package :op-annotate-tests)

(defsuite op-annotate-tests)

(in-suite op-annotate-tests)

(defun run-tests ()
  (op-annotate-tests))
