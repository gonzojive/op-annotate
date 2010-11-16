(in-package :op-annotate)

(defun output-article-html (article)
  (cl-who:with-html-output-to-string (stream)
    (:h2 (who:esc (article-title article)))
    (:div :class "byline" "By " (who:esc (article-byline article)))

    (:form
     (loop :for para :in (article-paragraphs article)
           :for i :from 1
           :do
           (who:htm
            (:p                         ;(who:fmt "~A:  " i)
              :id (format nil "paragraph-~A" i)
              (:input :type "checkbox" :class "para-check")
              (:span 
               :class "contents"
               (loop :for j :from 1
                     :for sent :in (split-sentences para)
                     :do
                     (who:htm
                      (:span :class "sentence"
                             :id (format nil "sentence-~A-~A" i j)
                             :title (format nil "Paragraph ~A, sentence ~A" i j)
                                    (who:esc sent)
                                        ;(who:fmt "[~A]  " (elt "abcdefghi" j))
                             )
                         "  "))
               (when (< (random 100) 20)
                 (who:htm
                  (:span :class "tag tag-dark tag-inline" :style "background-color: #CC0000;;"
                         "inane"))))))))))

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

    ;; layout
    (:.article :width "60%" :float "right")
    (:.annotations :width "38%" :float "left")

    ;; paragraph/sentence styling
    (:p :line-height "1.5em")
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
     :font-size ".95em"
     :margin "0"
     :padding "4px 1em 3px"
     :white-space "nowrap"
     :margin "0") 
    (:.tab-content
     :border-top "1px solid #cccccc"
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
    (:.tag :xbrowser-border-radius "3px" :font "10px verdana,arial,sans-serif" :line-height "12px" :padding "2px 5px")
    (:.tag-inline :position "relative" :top "-8px")
    (:.tag-light :color "#F9FFEF")
    (:.tag-dark :color "#FFE3E3")

    ;; checkbox
    (:p :position "relative" :left "-20px")
    (:.para-check :float "left" :display "block" :width "19px")
    ((css-sexp:direct-ancestor :p :.contents) :display "block" :margin-left "20px")

    ;; status
    (:.status :float "right" :background-color "#111" :border "1px solid #000" :color "#fff" :padding "1px 3px")
    ))
    


(webfunk:web-defun article (url)
  (let ((article  (if url
                      (download-article url)
                      *test-nyt-article*)))
  (cl-who:with-html-output-to-string (stream nil :prologue t)
    (:html
     (:head (:title "Op-Annotate: React to NYT Op-Eds")
            (:style :type "text/css" (who:str (css))))
     (:body
      (:div :class "annotations"
            (:h1 "Op-Annotate")
            (:h4 "React to NYT articles on the merits")
            #+nil
            (:h3 "Tags")
            #+nil
            (:p "Drag tags onto sentences, or sentences onto tags.")
            (:div 
             :style "position: relative; bottom: -1px;"
             (:ul
              :class "tabs"
              (:li "Blah")
              (:li :class "selected" "Tag")))
            (:div :class "tab-content"
                  (:div :id "status" :class "status" "Paragraph 3, sentence 8")
                  (:h3 "Tags")
                  (:span :class "tag tag-dark" :style "background-color: #CC0000;;"
                         "inane")
                  "  "
                  (:span :class "tag tag-light" :style "background-color: #64992C;"
                         "insightful"))
            #+nil
            (:h3 "Stats")
            #+nil
            (multiple-value-bind (wc uwc words uwords)
                (article-wordcount article)
              (who:htm
               (:div ""
                     (who:fmt "~A words, ~A unique words: " wc uwc)))))
                 
      (:div :class "article"
            (:form :action "/article" :method "GET"
                   (:input :type "text" :name "url" :style "width: 30em")
                   (:input :type "submit" :value "Scrape Article"))
            (who:str (output-article-html article)))

      (:script :type "text/javascript" :src "/static/jquery-1.4.3.js")
      (:script :type "text/javascript" :src "/static/op-annotate.js"))))))

(webfunk:web-defun static (rest-of-uri)
  (let ((given-path (format nil "/~{~A~^/~}" rest-of-uri)))
    (webfunk:serve-static-file
     given-path
     (asdf:system-relative-pathname (asdf:find-system :op-annotate)
				    "static/"))))