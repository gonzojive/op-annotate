(in-package :op-annotate)


(defclass article ()
  ((paragraphs :initarg  :paragraphs :initform nil     :accessor article-paragraphs)
   (html-page :initarg  :html-page :initform nil     :accessor article-html-page)
   (byline     :accessor article-byline :initarg  :byline)
   (title      :accessor article-title  :initarg  :title)))

(defun split-words (string)
  (let ((n nil))
    (ppcre:do-matches-as-strings (sent "(\\w+)|(\\$\\d+\\.\\d+)|([^\\w\\s]+)" string)
      (push sent n))
    (nreverse n)))
;  (ppcre:split  string))

(defun split-sentences (string)
  (let ((n nil))
    (ppcre:do-matches-as-strings (sent "(\\S.+?[.!?])(?=\\s+|$)" string)
      (push sent n))
    (nreverse n)))

(defparameter *article-cache* (make-hash-table :test #'equal))
(defun download-article (url)
  (let ((page
         (or (gethash url *article-cache*)
             (setf (gethash url *article-cache*)
                   (drakma:http-request url
                                        :external-format-in :utf-8
                                        :cookie-jar (make-instance 'drakma:cookie-jar))))))
    (parse-nyt-article page)))

(defparameter *test-nyt-article* (download-article
                                  "http://www.nytimes.com/2010/11/04/opinion/04orszag.html?partner=rssnyt&emc=rss"))

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

(defun parse-nyt-article (string)
  (let ((doc (closure-html:parse string (stp:make-builder))))
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
;             (title-elem (xpath:first-node (xpath:evaluate "//xhtml:h1[@class='articleHeadline']" doc)))
;             (title (stp:string-value (stp:first-child title-elem))))
             (title (ppcre:register-groups-bind (headline)
                        ("(.*) - NYTimes.com$"
                         (regex-trim (stp:string-value
                                      (xpath:first-node (xpath:evaluate "//xhtml:title" doc)))))
                      headline)))
        
        (make-instance 'article
                       :paragraphs paragraphs-clean
                       :title title
                       :byline byline
                       :html-page string)))))


(defun parse-nyt-article (string)
  (let ((doc (closure-html:parse string (stp:make-builder))))
    (xpath:with-namespaces (("xhtml" "http://www.w3.org/1999/xhtml"))
      (xpath:evaluate "//*[@class='articleBody']//xhtml:p" doc))))

