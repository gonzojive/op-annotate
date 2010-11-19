(eval-when (:compile-toplevel :load-toplevel :execute)
  (asdf:operate 'asdf:load-op :op-annotate))

(op-annotate::open-store)
(webfunk:start-http-server :port 4000)


