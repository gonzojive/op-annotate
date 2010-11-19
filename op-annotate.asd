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
			 (:file "user" :depends-on ("conditions"))
			 (:file "css" :depends-on ("conditions"))
			 (:file "scrape-nyt" :depends-on ("conditions"))
			 (:file "annotate-article" :depends-on ("conditions" "scrape-nyt" "user"))
			 (:file "list-articles" :depends-on ("conditions" "user" "scrape-nyt"))
			 (:file "scrape-article" :depends-on ("conditions" "user" "scrape-nyt"))
			 (:file "admin-nyt" :depends-on ("conditions" "user" "scrape-nyt"))
                         
	       )))
  :depends-on ("anaphora" "alexandria" "webfunk" "drakma" "closure-html" "cxml-stp" "xpath" "cl-who" "css-sexp" "elephant" "cl-facebook" "net-telent-date"))



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
