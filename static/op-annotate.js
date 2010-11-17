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
                                       console.log("current: %o", vals.current);
                                   },
                                   "onSubmit"    : function(vals) {
                                       console.log("current: %o", vals.current);
                                       var txt = this.data("editable.current");
                                       lines = txt;
                                       var html = txt.replace(/\n+/g, "<br/><br/>");
                                       this.data("op-annotate.text", txt);
                                       this.html(html);
                                   }
                               });

      $("#article-form").submit(function (ev) { ev.preventDefault(); });
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

function Annotation(tag) {
    this.tag = tag;    
}

Tag.prototype.createElem = function () {
    var elem = $("<span>");
    elem.addClass("tag");
    elem.addClass("tag-light");
    elem.css("background-color", this.color);
    elem.text(this.text);
    return elem;
};

function TagButton(tag) {
    this.tag = tag;

    var elem = $("<a>");
    elem.attr("href", "#tags/" + encodeURIComponent(this.tag.text));
    elem.append(tag.createElem());
    
    this.elem = elem;

    $(this.elem).click(
        function (event) {
            event.stopPropagation();
            event.preventDefault();
            ARTICLE.selectedParagraphs().map(
                function(p) {
                    p.addAnnotation(new Annotation(tag));
                });
        });
};

function Article(elem) 
{
    var article = this;

    this.elem = elem;
    this._paragraphs = $("p", this.elem).toArray().map(function (p) {
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

function Paragraph(elem)
{
    this.elem = elem;
    this._checkbox = $(".para-check", this.elem)[0];
    this._annotations = [];
};

Paragraph.prototype.checkbox = function() {
     return this._checkbox;
};

Paragraph.prototype.addAnnotation = function(annotation)
{
    this._annotations.push(annotation);
    var cont = $(".tag-container", this.elem);
    cont.append(annotation.tag.createElem());
    cont.append($("<span>").text("  "));
};

Paragraph.prototype.removeAnnotation = function(annotation)
{
    this._annotations.push(annotation);
};

Paragraph.prototype.annotations = function() {
     return this._annotations;
};