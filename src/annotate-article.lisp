(in-package :op-annotate)

(defun article-local-url (article)
  (format nil "/article?oid=~A" (oid article)))

(defun output-article-html (article)
  (cl-who:with-html-output-to-string (stream)
    (:h2 (:a :href (article-url article)
             :target "_blank"
             (who:esc (article-title article))))
    (:div :class "byline" "By " (who:esc (article-byline article)))

    (:form
     :class "overviewable"
     :id "article-form"
     (loop :for para :in (article-paragraphs article)
           :for i :from 1
           :do
           (who:htm
            (:p                         ;(who:fmt "~A:  " i)
              :id (format nil "paragraph-~A" i)
              :class "article-para"
              (:input :type "checkbox" :class "para-check")
              (:span 
               :class "contents"
               (loop :for j :from 1
                     :for sent :in (list para) ;;(split-sentences para)
                     :do
                     (who:htm
                      (:span :class "sentence"
                             :id (format nil "sentence-~A-~A" i j)
                             :title (format nil "Paragraph ~A" i);(format nil "Paragraph ~A, sentence ~A" i j)
                                    (who:esc sent)
                                        ;(who:fmt "[~A]  " (elt "abcdefghi" j))
                             )
                         "  "))
               (:span :class "tag-container")
               #+nil
               (when (< (random 100) 20)
                 (who:htm
                  (:span :class "tag tag-dark tag-inline" :style "background-color: #CC0000;;"
                         "inane"))))
              (when (eql i 1)
                (who:htm
                 (:blockquote
                  "There are numerous examples of liberals who expound moralism in all its forms.  To suggest that modern liberals care not for morals is absurd.  Many would argue the opposite, that they care deeply for the poor but conservatives lack the common decency to blah.")))


              ))))))

(webfunk:web-defun admin-scrape-article (url)
  (setf (hunchentoot:content-type*) "text/plain")
  (aif (with-user (user)
         (when (user-admin? user)
           (let ((article (download-article url)))
             (hunchentoot:redirect (article-local-url article))
             (format nil "Redirecting to \"~A\"" (article-title article)))))
       it
       "No access!"))

(webfunk:web-defun article ((oid :parameter-type 'integer) scraped-html)
  (ele:ensure-transaction ()
    (let ((article  (if oid
                      (get-instance-by-oid oid 'article)
                      nil)))
      (cond
        ((null article)
         (hunchentoot:redirect "/"))
        ((and article scraped-html)
         (article-html-page article))
        (article
         (cl-who:with-html-output-to-string (stream nil :prologue t)
           (:html
            (:head (:title "Op-Annotate: React to NYT Op-Eds")
                   (:style :type "text/css" (who:str (css))))
            (:body
             (:div :class "annotations"
                   (:h1 (:a :href "/" "Op-Annotate"))
                   (:h4 "React to NYT articles on the merits")
                   #+nil
                   (:h3 "Tags")
                   #+nil
                   (:p "Drag tags onto sentences, or sentences onto tags.")
                   (:div 
                    :style "position: relative; bottom: -1px;"
                    (:ul
                     :class "tabs"
                     (:li (:a :href "/" "All Articles"))
                     (:li :class "selected" "React")))
                   (:div :class "tab-content"
                         (:div :id "status" :class "status" "Paragraph 3, sentence 8")
                         (:h3 "Tags")
                         (:div :class "tag-buttons")
                         (:h3 "Overview Mode")
                         (:span :class "toggle-overview overviewable" "hover"))
                   #+nil
                   (:h3 "Stats")
                   #+nil
                   (multiple-value-bind (wc uwc words uwords)
                       (article-wordcount article)
                     (who:htm
                      (:div ""
                            (who:fmt "~A words, ~A unique words: " wc uwc)))))
                 
             (:div :class "article"
                   (who:str (output-article-html article)))

             (:script :type "text/javascript" :src "/static/jquery-1.4.3.js")
                                        ;      (:script :type "text/javascript" :src "/static/jquery.jeditable.js")
             (:script :type "text/javascript" :src "/static/jquery.editable-1.3.3.js")
             (:script :type "text/javascript" :src "/static/op-util.js")
             (:script :type "text/javascript" :src "/static/op-annotate.js")
             (:div :id "fb-root")
             (:script :type "text/javascript"
                      "window.fbAsyncInit = function() {
    FB.init({appId: '" (who:str *fb-app-id*) "', status: true, cookie: true,
             xfbml: true});
    opAnnotateFBInit();
  };
  (function() {
    var e = document.createElement('script'); e.async = true;
    e.src = document.location.protocol +
      '//connect.facebook.net/en_US/all.js';
    document.getElementById('fb-root').appendChild(e);
  }());")
             ))))))))


(webfunk:web-defun static (rest-of-uri)
  (let ((given-path (format nil "/~{~A~^/~}" rest-of-uri)))
    (webfunk:serve-static-file
     given-path
     (asdf:system-relative-pathname (asdf:find-system :op-annotate)
				    "static/"))))
