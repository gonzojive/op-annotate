$(function() {
      highlightParas();
  });

var LAST_CHECKED_ELEM = null;

function observeCheckboxes()
{
    $(".para-check").click(
        function(event) {
            var elem = event.currentTarget;
            var checkp = elem.checked;
            if (event.shiftKey)
            {
                var elems = $(".para-check").toArray();
                var orig = elems.indexOf(elem);
                var other = elems.indexOf(LAST_CHECKED_ELEM);
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

            LAST_CHECKED_ELEM = elem;
            highlightParas();
        });

    $(".para-check").change(
        function(event) {
            var elem = event.currentTarget;
            //LAST_CHECKED_ELEM = elem;
            highlightParas();
        });
}

function iter(array) {
    var i = 0;
    return function() { return array[i++]; };
}

function RangeString() {
    this.ranges = [];
    return this;
}

RangeString.prototype.plural = function() {
    return !(this.ranges.length == 1  && this.ranges[0].start == this.ranges[0].end);
}

RangeString.prototype.toString = function() {
    var result = "";
    var strings = this.ranges.map(
        function(range) {
            if (range.end - range.start > .001)
            {
                return "" + range.start + "-" + range.end;
            }
            else
            {
                var start = range.start;
                return "" + start;
            }
        });

    return strings.join(", ");
};

RangeString.prototype.addInt = function(num) {
    if (this.ranges.length === 0)
    {
        this.ranges = [{"start": num, "end":num}];
        return;
    }

    for (var i=0; i < this.ranges.length; i++)
    {
        var range = this.ranges[i];
        var nextRange = this.ranges[i+1];
        //console.log("%o %o", range, nextRange);
        if (range.start <= num && num <= range.end)
        {
            // do nothing, already in range
            break;
        }
        else if (range.start === num + 1)
        {
            range.start = num;
            //console.log("Expanded range %o at start with %o", range, num);
        }
        else if (range.end === num - 1)
        {
            range.end = num;
            //console.log("Expanded range %o at end with %o", range, num);
        }
        else if (num < range.start)
        {
            this.ranges.splice(i, 0, {"start": num, "end":num});
            //console.log("Added new range at index %o for %o", i, num);;
            break;
        }
        else if (!nextRange && num > range.end) {
            this.ranges.splice(i+1, 0, {"start": num, "end":num});
            //console.log("Added new range at index %o (i+1) for %o", i+1, num);;
            break;
        }

        if (nextRange && nextRange.start == range.end) {
            range.end = nextRange.end;
            this.ranges.splice(i+1, 1);
            break;
        }
    }
};


function highlightParas() {
    var i=0;
    var rangeString = "";
    var prevChecked = null;
    var rangestr = new RangeString();
    var checked = $(".para-check").toArray().map(
        function (e) {
            var checkedp = !!e.checked;
            var p = e.parentNode;
            if (checkedp )
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
}