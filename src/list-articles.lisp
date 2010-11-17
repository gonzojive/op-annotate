(in-package :op-annotate)

(webfunk:web-defun articles ()
  (with-user (user)
    (cl-who:with-html-output-to-string (stream nil :prologue t)
      (:html
       (:head (:title "Op-Annotate: React to NYT Op-Eds")
              (:style :type "text/css" (who:str (css))))
       (:body
        (:div :class "annotations"
              (:h1 (:a :href "/" "Op-Annotate"))
              (:h4 "React to NYT articles on the merits")
              (:div 
               :style "position: relative; bottom: -1px;"
               (:ul
                :class "tabs"
                (:li :class "selected" "All Articles")))
              (:div :class "tab-content" :style "border-right: 1px solid "
                    (:div :id "status" :class "status" "")
                    (:ol
                     (let ((i 0))
                       (block article-loop
                         (ele:map-inverted-index
                          #'(lambda (value article)
                              (who:htm
                               (:li 
                                (:a :href (article-local-url article)
                                    (who:esc (article-title article)))
                                " -- " (who:esc (article-byline article))))
                              (when (= (incf i) 20)
                                (return-from article-loop t)))
                          'article 'creation-date))))))
        
        (:div :class "article"
              (when (user-admin? user)
                (who:htm
                 (:form :action "/admin-scrape-article" :method "GET"
                        (:input :type "text" :name "url" :style "width: 30em")
                        (:input :type "submit" :value "Scrape Article")))))


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
        )))))