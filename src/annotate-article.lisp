(in-package :op-annotate)

(defun article-local-url (article)
  (format nil "/article?oid=~A" (oid article)))

(defun output-article-html (article)
  (cl-who:with-html-output-to-string (stream)
    (:h2 (:a :href (article-url article)
             :target "_blank"
             (who:esc (article-title article))))
    (:div :class "byline" "By " (who:esc (article-byline article)))

    (:script :type "text/javascript"
             "var ARTICLE_ANNOTATIONS_SUMMARY = "
             (who:str (user-get-annotations :article-oid (oid article)))
             ";")

    (:form
     :class "overviewable"
     :id "article-form"
     (:span :class "article-oid" :style "display: none" (who:fmt "~A" (oid article)))
     (loop :for para :in (article-paragraphs article)
           :for i :from 1
           :do
           (who:htm
            (:div
              :class "paragraph-container"
                     (:p
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
                                     :title (format nil "Paragraph ~A" i) ;;"Paragraph ~A, sentence ~A" i j
                                            
                                            (who:esc sent))
                                 "  "))
                       (:span :class "tag-container")
                       "  "
                       (:a :class "add-comment" :href (format nil "#add-comment/~A/~A" i (random 100000))
                           (who:esc "> comment"))))
                     (:blockquote "")))))))

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
                     ;(:li (:a :href "/" "All Articles"))
                     (:li :class "selected" "React")))
                   (:div :class "tab-content"
                         (:div :id "status" :class "status" "Paragraph 3, sentence 8")
                         (:h3 "Tags")
                         (:div :class "tag-buttons")
                         (:h3 "Overview Mode")
                         (:span :class "toggle-overview overviewable" "hover"))
                   
                   (top-articles-sidebar stream)
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
             (:script :type "text/javascript" :src "/static/json2.js")
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


(defclass article-user-commentary ()
  ((article :initarg :article :initform nil :accessor commentary-article)
   (paragraph-annotation-alist :initarg :paragraph-annotation-alist :accessor commentary-paragraph-annotation-alist)))

(defmethod commentary-annotations-for-paragraph (commentary pnum)
  (cdr (assoc pnum (commentary-paragraph-annotation-alist commentary))))

(defun get-commentary (user article)
  (let ((annotations
         (remove article
                 (ele:get-instances-by-value 'article-annotation 'user user)
                 :key #'annotation-article
                 :test (complement #'eql))))
    (let ((hash  (make-hash-table)))
      (dolist (annotation annotations)
        (push annotation (gethash (annotation-paragraph-index annotation) hash)))
      (make-instance 'article-user-commentary
                     :article article
                     :paragraph-annotation-alist (sort (hash-table-alist hash) #'< :key #'car)))))
        
    
  

(webfunk:web-defun user-submit-annotations ((article-oid :parameter-type 'integer)
                                            (annotations-obj :parameter-type :json))
  (declare (optimize (debug 3)))
  (defparameter *annotatins-obj* annotations-obj)
  (ele:ensure-transaction ()
    (with-user (user)
      (when user
        (let* ((article (get-instance-by-oid article-oid 'article))
               (commentary (get-commentary user article)))
          (loop :for paragraph-index :from 0
                :for paragraph-annotation :in annotations-obj
                :for tags = (cdr (assoc :tags paragraph-annotation :test #'equal))
                :for comments = (cdr (assoc :comments paragraph-annotation :test #'equal))
                :for commentary-annotations = (commentary-annotations-for-paragraph commentary paragraph-index)
                :do (let* ((tags-to-insert tags)
                           (comment-annotation nil)
                           (annotations-to-remove
                            (remove-if #'(lambda (annotation)
                                           (let ((tag (annotation-tag annotation)))
                                             (cond
                                               ;; keep annotations arround that match an existing tag
                                               ((member tag tags :test #'equalp)
                                                (removef tags-to-insert tag :test #'equalp)
                                                t)
                                               ;; keep an annotation for a comment when the user still has a comment
                                               ((and comments (annotation-comment annotation))
                                                (setf comment-annotation annotation)
                                                t)
                                               (t
                                                nil))))
                                       commentary-annotations)))
                      (dolist (tag tags-to-insert)
                        (make-instance 'article-annotation 
                                       :user user :article article
                                       :tag tag 
                                       :paragraph-index paragraph-index))
                      (when comments
                        (if comment-annotation
                            (setf (annotation-comment comment-annotation) (first comments))
                            (make-instance 'article-annotation 
                                           :user user :article article
                                           :comment (first comments)
                                           :paragraph-index paragraph-index)))
                      (ele:drop-instances annotations-to-remove)))
          (json:encode-json-to-string "success"))))))

(webfunk:web-defun user-get-annotations ((article-oid :parameter-type 'integer))
  (ele:ensure-transaction ()
    (with-user (user)
      (json:encode-json-to-string
       (when user
         (let* ((article (get-instance-by-oid article-oid 'article))
                (commentary (get-commentary user article)))
           (loop :for paragraph-index :from 0 :upto (- (length (article-paragraphs article)) 1)
                 :for commentary-annotations = (commentary-annotations-for-paragraph commentary paragraph-index)
                 :collect (plist-hash-table
                           (list "tags" (remove nil (mapcar #'annotation-tag commentary-annotations))
                                 "comments" (remove nil (mapcar #'annotation-comment commentary-annotations)))))))))))

