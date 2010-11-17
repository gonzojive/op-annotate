(defpackage org.iodb.op-annotate.system
  (:use #:cl #:asdf))

(in-package :org.iodb.op-annotate.system)

(defsystem :op-annotate
  :description "Annotate op-eds"
  :version "0.0.1"
  :author "Red Daly <reddaly at gmail>"
  :license NIL
  :components ((:module "src"
			:components
			((:file "package")
			 (:file "conditions" :depends-on ("package"))
			 (:file "annotate-article" :depends-on ("conditions" "scrape-nyt"))
			 (:file "scrape-nyt" :depends-on ("conditions"))
                         
	       )))
  :depends-on ("anaphora" "alexandria" "webfunk" "drakma" "closure-html" "cxml-stp" "xpath" "cl-who" "css-sexp" "elephant" "cl-facebook"))



(defsystem :op-annotate-docs
  :components ((:module "doc"
                        :components
                        ((:file "op-annotate-docdown"))))
  :depends-on ("docdown" "alexandria"))

(setf (asdf:component-property (asdf:find-system :op-annotate) :website)
      "http://github.com/gonzojive/op-annotate")

(defsystem :op-annotate-tests
  :components ((:module "test"
                        :components ((:file "test-package"))))

  :depends-on ("op-annotate" "hu.dwim.stefil"))
