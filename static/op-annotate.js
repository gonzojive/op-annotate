var ARTICLE = null;
$(function() {
      ARTICLE = new Article($(".article")[0]);
      ARTICLE.highlightParas();
      
      var tagButtonsContainer = $(".tag-buttons");
      TAGS.map(function (tag) {
                   tagButtonsContainer.append(new TagButton(tag).elem);
                   tagButtonsContainer.append($("<span>").text("  "));
               });
      
      $(".toggle-overview").mouseenter(function() { $(".overviewable").addClass("overview-mode"); })
      $(".toggle-overview").mouseleave(function() { $(".overviewable").removeClass("overview-mode"); })
      
      $('blockquote').editable({
                                   "type"      : 'textarea',
                                   "cancel"    : "Cancel",
                                   "submit"    : "Save",
                                   "replace"   : null,
                                   "editValue"     : function() {
                                       return this.data("op-annotate.text") || this.text();  
                                   },
                                   "onEdit"    : function(vals) {

                                   },
                                   "onSubmit"    : function(vals) {
                                       var txt = this.data("editable.current");
                                       var html = txt.replace(/\n+/g, "<br/><br/>");
                                       this.data("op-annotate.text", txt);
                                       this.html(html);
                                       ARTICLE.setNeedsSync();
                                   },
                                   "onCancel"    : function(vals) {
                                       var txt = this.data("editable.current");
                                       var html = txt.replace(/\n+/g, "<br/><br/>");
                                       this.html(html);
                                   }
                               });

      $("#article-form").submit(function (ev) { ev.preventDefault(); });

      var ARTICLE_ANNOTATIONS_SUMMARY = ARTICLE_ANNOTATIONS_SUMMARY || null;
      if (ARTICLE_ANNOTATIONS_SUMMARY)
      {
          ARTICLE.loadSummary(ARTICLE_ANNOTATIONS_SUMMARY);
      }

      // admin
      $(".fetched-op-ed a").click(
          function(event)
          {
              event.preventDefault();
              $("#scrape-url")[0].value = event.target.href;
          });
      console.log("fetched a's: %o", $(".fetched-op-ed a"));
  });

function Tag(text, bgColor) {
    this.color = bgColor;
    this.text = text;
}

var TAGS = [new Tag("inane", "#64992C"),
            new Tag("regurgitation", "#009051"),
            new Tag("straw man", "#7800ff"),
            new Tag("inaccurate", "#CC0000"),
            new Tag("exaggeration", "#ff4800"),
            new Tag("double standard", "#ffb400"),
            new Tag("vague", "#444444")
            
            ];

function tagByName(name) {
    for (var i=0; i < TAGS.length; i++)
    {
        if (TAGS[i].text === name)
            return TAGS[i];
    }
};

function Annotation(tag) {
    this.tag = tag;    
}

Tag.prototype.createElem = function () {
    var elem = $("<span>");
    elem.addClass("tag");
    elem.addClass("tag-light");
    elem.css("background-color", this.color);
    elem.text(this.text);
    var rem = $("<span>").addClass("remove").text("X");
    elem.append(rem);
    return elem;
};

function TagButton(tag) {
    this.tag = tag;

    var elem = $("<a>");
    elem.attr("href", "#tags/" + encodeURIComponent(this.tag.text));
    var tagElem = tag.createElem();
    elem.append(tagElem);
    $(".remove", tagElem).hide();
    
    this.elem = elem;

    $(this.elem).click(
        function (event) {
            event.stopPropagation();
            event.preventDefault();
            ARTICLE.selectedParagraphs().map(
                function(p) {
                    var annots = p.annotations();
                    var indexOfTag = annots.map(propFn("tag")).indexOf(tag);
                    if (indexOfTag == -1)
                    {
                        p.addAnnotation(new Annotation(tag));         
                    }
                });
            ARTICLE.setNeedsSync();
        });

};

function Article(elem) 
{
    var article = this;

    this.elem = elem;
    this._paragraphs = $("p.article-para", this.elem).toArray().map(function (p) {
                                                           return new Paragraph(p);
                                                       });
    this.lastCheckedElem = null;

    var checkboxesJQ = $(this.checkboxes());
    checkboxesJQ.click(
        function(event) {
            var elem = event.currentTarget;
            var checkp = elem.checked;
            if (event.shiftKey)
            {
                var elems = checkboxesJQ.toArray();
                var orig = elems.indexOf(elem);
                var other = elems.indexOf(article.lastCheckedElem);
                if (orig !== -1 && other !== -1)
                {
                    var min = Math.min(orig, other);
                    var max = Math.max(orig, other);
                    //console.log("Checking elements %i - %i (orig: %i, other: %i)", min, max, orig, other);
                    for (var i=min; i <= max; i++)
                    {
                        elems[i].checked = checkp;
                    }
                }
            }

            article.lastCheckedElem = elem;
            article.highlightParas();
        });

    checkboxesJQ.change(
        function(event) {
            var elem = event.currentTarget;
            //article.lastCheckedElem = elem;
            article.highlightParas();
        });
};

Article.prototype.oid = function () {
    return $(".article-oid", this.elem).text();
};

Article.prototype.paragraphs = function () {
    return this._paragraphs;    
};

Article.prototype.selectedParagraphs = function () {
  return this.paragraphs().filter(function (p) {return p.checkbox().checked; });
};

Article.prototype.checkboxes = function ()
{
    if (!this._checkboxes)
    {
        this._checkboxes = this.paragraphs().map(function(x) { return x.checkbox(); });    
    }
    return this._checkboxes;
};

Article.prototype.highlightParas = function () {
    var i=0;
    var rangeString = "";
    var prevChecked = null;
    var rangestr = new RangeString();
    var checked = this.checkboxes().map(
        function (e) {
            var checkedp = !!e.checked;
            var p = e.parentNode;
            if (checkedp)
            {
                $(p).addClass("checked");
                rangestr.addInt(i+1);
            }
            else
            {
                $(p).removeClass("checked");                
            }
            i++;
        });

    // set the status message
    if (rangestr.ranges.length == 0)
    {
        $("#status").hide();
    }
    else
    {
        $("#status").show();
        var plural = rangestr.plural();
        var txt = "Selected Paragraph" + (plural ? "s " : " ") + rangestr.toString();
        $("#status").text(txt);
    }
};

Article.prototype.setNeedsSync = function ()
{
    console.log("we need to sync!");
    this.needsSync = true;
    var article = this;
    function update() {
        if (article.needsSync)
        {
            article.sendAnnotations();
            article.needsSync = false;
        }
    }

    setTimeout(update, 200);
};

Article.prototype.sendAnnotations = function ()
{
    var obj = this.annotationSummary();

    var json = JSON.stringify(obj);

    jQuery.getJSON("/user-submit-annotations",
                   { "annotations-obj" : json,
                     "article-oid" : this.oid() },
                   function(data, textStatus, xhr) {
                       console.log(data);
                   });
};

Article.prototype.annotationSummary = function ()
{
    return this.paragraphs().map (
        function(p) {
            return p.annotationSummary();
        });
};

Article.prototype.loadSummary = function (summary)
{
    var paras = this.paragraphs();
    for (var i=0; i < paras.length; i++)
    {
        var p = paras[i];
        var psum = summary[i];
        if (psum && psum.tags)
        {
            psum.tags.map(function (tagName) {
                              var tag = tagByName(tagName);
                              p.addAnnotation(new Annotation(tag));
                          });
        }

        if (psum && psum.comments) {
            var comment = psum.comments[0];
            // TODO insert comment annotation
        }
    }
};

Article.prototype.loadAnnotations = function ()
{
    var article = this;
    jQuery.getJSON("/user-get-annotations",
                   { "article-oid" : this.oid() },
                   function(data, textStatus, xhr)
                   {
                       if (data)
                       {
                           article.loadSummary(data);
                           article.loaded = true;
                       }
                   });
};

function Paragraph(elem)
{
    this.elem = elem;
    this._checkbox = $(".para-check", this.elem)[0];
    this._annotations = [];
};

function identity(x) {
     return x;
};

Paragraph.prototype.annotationSummary = function()
{
  var tags = this.annotations().map(
      function(annot) {
          return annot.tag.text;
      }).filter(identity);

    var comments = this.annotations().map(propFn("comment")).filter(identity);
    return {
        "tags" : tags,
        "comments" : comments
    };
};

Paragraph.prototype.checkbox = function() {
     return this._checkbox;
};

Paragraph.prototype.addAnnotation = function(annotation)
{
    this._annotations.push(annotation);
    var cont = $(".tag-container", this.elem);
    var annotationElem = annotation.tag.createElem();
    cont.append(annotationElem);
    cont.append($("<span>").text("  "));
    var p = this;
    annotation.elem = annotationElem;
    $(".remove", annotationElem).click(
        function(event) {
            p.removeAnnotation(annotation);
            ARTICLE.setNeedsSync();
        });
};

Paragraph.prototype.removeAnnotation = function(annotation)
{
    this._annotations = this._annotations.filter(function (x) {
                                                      return x !== annotation;
                                                 });
    $(annotation.elem).detach();
};

Paragraph.prototype.annotations = function() {
     return this._annotations;
};

function opAnnotateFBInit()
{
    
}

