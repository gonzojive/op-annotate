(in-package :op-annotate)

(defun rounded-corners (amounts)
  (format nil
          "border-radius: ~A; -moz-border-radius: ~A; -webkit-border-radius: ~A; behavior: url(/static/css/border-radius.htc);~%  "
          amounts amounts amounts))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (css-sexp:defrule :xbrowser-border-radius (arg stream)
    `(write-string (rounded-corners ,arg) ,stream))
  (css-sexp:defrule :bookllama-gradient-background (arg stream)
    (declare (ignore arg))
    `(format ,stream "background-repeat: repeat-x; background-image: url(/static/images/common-gradient.png); background-color: #fff4eb;")))

(webfunk:web-defun css ()
  (css-sexp:with-css-output-to-string (stream)
    (:body :font-family "georgia,\"times new roman\",times,serif")
    (:h1 :font-size "1.5em" :margin ".5em 0")
    (:h2 :font-size "1.35em" :margin ".5em 0")
    (:h3 :font-size "1.25em" :margin ".3em 0")
    (:h4 :font-size "1.05em" :margin ".3em 0")

    ((css-sexp:ancestor :h1 :a) :color "#000000" :text-decoration "none")

    ;; layout
    (:.article :width "60%" :float "right")
    (:.annotations :width "35%" :position "fixed" :top "5px")

    ;; article overview mode
    ((css-sexp:ancestor :.article :.overview-mode)
     :width "50%" :font-size "6pt")

    ;; paragraph/sentence styling
    (:p.article-para :line-height "1.5em" :clear "both")
    ((css-sexp:ancestor :p.checked :.sentence)
     :border "1px solid #ddd"
     :background-color "#eee")

    (:.sentence\:hover :border "1px solid #ddd"
                       :background-color "#eee")
    (:.sentence :border "1px solid #fff")

    ;; tabs
    (:.tabs :display "block"
            :text-transform "uppercase"
            :white-space "nowrap"
            :font-family "arial,helvetica,sans-serif"
            :list-style "none outside none"
            :padding-left "0"
            :margin "0 0 0 10px"
            :overflow "hidden")
    ((css-sexp:direct-ancestor :.tabs :li)
     :background-color "#F0F4F5"
     :background-image "none"
     :border-color "#CCCCCC"
     :border-style "solid"
     :border-width "1px 1px 0 0"
     :display "block"
     :float "left"
     :font-size ".85em"
     :margin "0"
     :padding "4px 1em 3px"
     :white-space "nowrap"
     :margin "0") 
    (:.tab-content
     :border "1px solid #cccccc"
     :padding "10px 4px"
     :margin "0")
    ((css-sexp:direct-ancestor :.tabs :li\:first-child)
     :border-width "1px 1px 1px 1px"
     )
    ((css-sexp:direct-ancestor :.tabs :li.selected)
     :font-weight "bold"
     :border-bottom "1px solid white"
     :background-color "white")

    ;; labels
;    (:.tag :xbrowser-border-radius "5px" :font "9pt verdana,arial,sans-serif" :line-height "12px" :padding "2px 5px")
    (:.tag :xbrowser-border-radius "3px" :font "10px verdana,arial,sans-serif" :line-height "12px" :padding "2px 3px 2px 5px" :white-space "nowrap")
    (:.tag-inline :position "relative" :top "-8px")
    (:.tag-light :color "#F9FFEF")
    (:.tag-dark :color "#FFE3E3")

    ((css-sexp:direct-ancestor :.tag-buttons :a) :text-decoration "none")

    ((css-sexp:ancestor :.tag :.remove)
     :cursor "pointer"
     :border-left "1px solid white"
     :margin-left ".4em"
     :padding "0 .4em")

    ((css-sexp:ancestor :.tag :.remove\:hover)
     :background-color "#fafafa"
     :color "#333")

    ;; reactions
    ((css-sexp:ancestor :blockquote)
     :margin "1.5em"
     :border-left "4px solid #eee"
     :padding ".1em .5em"
     :line-height "1.5em")

    ((css-sexp:ancestor :blockquote :textarea)
     :width "98%"
     :min-height "10em")

    ;; checkbox
    (:p.article-para :position "relative" :left "-30px")
    (:.para-check :float "left" :display "block" :width "19px")
    ((css-sexp:direct-ancestor :p :.contents) :display "block" :margin-left "30px")

    ;; status
    (:.status :float "right" :background-color "#111" :border "1px solid #000" :color "#fff" :padding "1px 3px")
    ))