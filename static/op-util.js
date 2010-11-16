function propFn(prop) {
    return function(x) {
         return x[prop];
    };
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
