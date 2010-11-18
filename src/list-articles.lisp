(in-package :op-annotate)

(defvar *day-names*
    '("Monday" "Tuesday" "Wednesday"
      "Thursday" "Friday" "Saturday"
      "Sunday"))

(multiple-value-bind
      (second minute hour date month year day-of-week dst-p tz)
    (get-decoded-time)
  (format t "It is now ~2,'0d:~2,'0d:~2,'0d of ~a, ~d/~2,'0d/~d (GMT~@d)"
          hour
          minute
          second
          (nth day-of-week *day-names*)
          month
          date
          year
          (- tz)))

(webfunk:web-defun testpage ()
  (setf (hunchentoot:content-type*) "text/plain; charset=utf-8")
  (setf (hunchentoot:reply-external-format*) :utf-8)
  "Madam Secretary → Middle East")

(webfunk:web-defun testpage1 ()
  (setf (hunchentoot:content-type*) "text/plain; charset=utf-8")
  (setf (hunchentoot:reply-external-format*) :utf-8)
  (values (drakma:http-request "http://localhost:4000/testpage")))

(webfunk:web-defun testpage2 ()
  (setf (hunchentoot:content-type*) "text/plain; charset=utf-8")
  (setf (hunchentoot:reply-external-format*) :utf-8)
  (values (drakma:http-request "http://pseudoliberals.com/testpage")))

(defun top-articles-sidebar (stream)
  (ele:ensure-transaction ()
    (cl-who:with-html-output (stream stream :prologue nil)
      (:div 
       :style "position: relative; bottom: -1px;"
       (:ul
        :class "tabs"
        (:li :class "selected" "All Articles")))
      (:div :class "tab-content"
            (:ol
             (let ((i 0))
               (block article-loop
                 (ele:map-inverted-index
                  #'(lambda (value article)
                      (who:htm
                       (:li 
                        (:a :href (article-local-url article)
                            (who:esc (article-title article)))
                        (:span :class "byline"
                               " -- " (who:esc (article-byline article)))))
                      (when (= (incf i) 20)
                        (return-from article-loop t)))
                  'article 'publication-date :from-end t))))))))

(webfunk:web-defun articles ()
  (ele:ensure-transaction ()
    (with-user (user)
      (cl-who:with-html-output-to-string (stream nil :prologue t)
        (:html
         :xmlns\:fb "http://facebook.com/ns/"
         (:head (:title "Op-Annotate: React to NYT Op-Eds")
                (:style :type "text/css" (who:str (css))))
         (:body
          (:div :class "annotations"
                (:h1 (:a :href "/" "Op-Annotate"))
                (:h4 "React to NYT articles on the merits")
                (when (or (not user) (not (user-facebook-session user)))
                  (who:htm (:fb\:login-button)))
                (top-articles-sidebar stream))

        
          (:div :class "article"
                (when (user-admin? user)
                  (who:htm
                   (:form :action "/admin-scrape-article" :method "GET"
                          (:input :type "text" :name "url" :id "scrape-url" :style "width: 30em")
                          (:input :type "checkbox" :name "force" )
                          (:input :type "submit" :value "Scrape Article"))
                   (:h2 "Latest NYT op-eds")
                   (:ul
                    (dolist (op-ed (fetch-latest-op-eds))
                      (who:htm
                       (:li :class "fetched-op-ed"
                            (:a :href (article-url op-ed)
                                (who:esc (article-title op-ed)))
                            "  "
                            (who:esc (article-author op-ed)))))))))


          (:script :type "text/javascript" :src "/static/jquery-1.4.3.js")
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
          ))))))

