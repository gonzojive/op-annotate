(in-package :op-annotate)

(defparameter *nyt-columnists-rss-url* 
  "http://topics.nytimes.com/top/opinion/editorialsandoped/oped/columnists/index.html?rss=1")

(defclass nyt-op-ed ()
  ((title :initform nil :accessor article-title :initarg :title)
   (author :initarg :author :accessor article-author)
   (url :initarg :url :accessor article-url)
   (publication-date :initarg :publication-date :initform nil :accessor article-publication-date)))

(defun fetch-latest-op-eds ()
  (let* ((xml (drakma:http-request *nyt-columnists-rss-url*))
         (doc (cxml:parse xml (stp:make-builder)))
         (items (xpath:evaluate "//item" doc)))
    (xpath:map-node-set->list 
     #'(lambda (item)
         (make-instance 'nyt-op-ed
                        :title (stp:string-value (xpath:first-node (xpath:evaluate "title" item)))
                        :author (stp:string-value (xpath:first-node (xpath:evaluate "author" item)))
                        :url (stp:string-value (xpath:first-node (xpath:evaluate "link" item)))
                        :publication-date (date:parse-time (stp:string-value (xpath:first-node (xpath:evaluate "pubDate" item))))))
     items)))

;; Article urls
;;http://www.nytimes.com                       /2010/11/18/opinion/18collins.html?ref=opinion
;;http://community.nytimes.com/article/comments/2010/11/18/opinion/18collins.html
    
  