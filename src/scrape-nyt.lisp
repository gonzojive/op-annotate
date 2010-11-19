(in-package :op-annotate)


(defclass article ()
  ((paragraphs :initarg  :paragraphs :initform nil     :accessor article-paragraphs)
   (html-page :initarg  :html-page :initform nil     :accessor article-html-page)
   (byline     :accessor article-byline :initarg  :byline :index t)
   (title      :accessor article-title  :initarg  :title)
   (url        :accessor article-url :initarg :url :initform nil :index t)
   (creation-date :accessor article-creation-date :initarg :creation-date :initform (get-universal-time) :index t)
   (publication-date :accessor article-publication-date :initarg :publication-date :initform (get-universal-time) :index t))
  (:metaclass ele:persistent-metaclass))

(defclass article-annotation ()
  ((article :initarg  :article :initform nil     :accessor annotation-article :index t)
   (paragraph-index :initarg  :paragraph-index :initform nil     :accessor annotation-paragraph-index)
   (tag :initarg :tag :initform nil     :accessor annotation-tag :index t)
   (comment :initarg :comment :initform nil :accessor annotation-comment)
   (user :initarg :user :initform nil :accessor annotation-user :index t))
  (:metaclass ele:persistent-metaclass))

(defun open-store ()
  (ele:open-store (list :bdb (asdf:system-relative-pathname (asdf:find-system :op-annotate)
                                                            "data/eledb/"))))

(defun split-words (string)
  (let ((n nil))
    (ppcre:do-matches-as-strings (sent "(\\w+)|(\\$\\d+\\.\\d+)|([^\\w\\s]+)" string)
      (push sent n))
    (nreverse n)))
;  (ppcre:split  string))

;;(defun split-sentences (string)
;;  (ppcre:split "\\s\\s|[\\.\\!\\?] " string))
;;  (let ((n nil))
;;    (ppcre:do-matches-as-strings (sent "(\\S.+?[.!?])(?=\\s+|$)" string)
;;      (push sent n))
;;    (nreverse n)))

(defun download-article (url &key force)
  (multiple-value-bind (page existing)
      (aif (ele:get-instance-by-value 'article 'url url)
           (values (if force
                       (setf (article-html-page it) (download-article* url :force force))
                       (article-html-page it))
                   it)
           (values (download-article* url :force force)))
    (parse-nyt-article page url existing)))

(defparameter *article-cache* (make-hash-table :test #'equal))
(defun download-article* (url &key force)
  (let ((page
         (or (and (not force) (gethash url *article-cache*))
             (setf (gethash url *article-cache*)
                   (drakma:http-request url
                                        :external-format-in :utf-8
                                        :cookie-jar (make-instance 'drakma:cookie-jar))))))
    page))

;(defparameter *test-nyt-article* (download-article
;                                  "http://www.nytimes.com/2010/11/04/opinion/04orszag.html?partner=rssnyt&emc=rss"))

(defun regex-trim (string)
  (ppcre:regex-replace-all "^\\s+|\\s+$" string ""))

(defun article-wordcount (article)
  (let* ((words (article-words article))
         (unique-words (remove-duplicates words :test #'equalp)))
    (values (length words)
            (length unique-words)
            words 
            unique-words)))

(defun article-words (article)
  (flet ((trivialp (str)
           (or (not str)
               (equal "" str))))
    (let ((words (mapcan #'split-words (article-paragraphs article))))
      (remove-if #'trivialp words))))

(defun parse-nyt-article (string url existing)
  (let ((doc (closure-html:parse string (stp:make-builder))))
    (defparameter *doc* doc)
;  (let ((doc (cxml:parse string (stp:make-builder))))
    (xpath:with-namespaces (("xhtml" "http://www.w3.org/1999/xhtml"))
      (let* ((nodes (xpath:evaluate "//*[@class='articleBody']//xhtml:p" doc))
             (paragraph-strings (xpath:map-node-set->list #'stp:string-value
                                                          nodes))
             (paragraphs-clean
              (remove nil
                      (mapcar #'(lambda (str)
                                  (let ((str (ppcre:regex-replace-all "^\\s+|\\s+$" str "")))
                                    (unless (equal "" str)
                                      str)))
                              paragraph-strings)))
             (byline (subseq (stp:string-value (xpath:first-node (xpath:evaluate "//xhtml:h6[@class='byline']" doc)))
                             3))
             (dateline (subseq (stp:string-value (xpath:first-node (xpath:evaluate "//xhtml:h6[@class='dateline']" doc)))
                               11))
             (pubtime (when dateline (date:parse-time dateline)))
;             (title-elem (xpath:first-node (xpath:evaluate "//xhtml:h1[@class='articleHeadline']" doc)))
;             (title (stp:string-value (stp:first-child title-elem))))
             (title (ppcre:register-groups-bind (headline)
                        ("(.*) - NYTimes.com$"
                         (regex-trim (stp:string-value
                                      (xpath:first-node (xpath:evaluate "//xhtml:title" doc)))))
                      headline)))
        
        (let ((common-args (list
                            :paragraphs paragraphs-clean
                            :title title
                            :byline byline
                            :html-page string
                            :url url
                            :publication-date pubtime)))
          (if existing
              (apply #'reinitialize-instance existing common-args)
              (apply #'make-instance 'article common-args)))))))


