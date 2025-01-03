var util;
(function (util) {
  function toggleTOCVisibility(event, handleId, tocTag) {
    event = event || window.event;
  
    
    var tocContainer = document.querySelector(tocTag);
    var containerHandle = document.getElementById(handleId);
    
    if (event.ctrlKey || event.metaKey) {
    
        if (!containerHandle.hasOwnProperty("AllExpanded")) {
            containerHandle.AllExpanded = false;
        }
        
        var allExpanded = false;
        if (containerHandle.AllExpanded) {
            allExpanded = true;
        }
            
        var handleClassName = "TOCHandle TOCHandleExpanded";
        var displayValue = "block";
        
        if (allExpanded) {
            handleClassName = "TOCHandle TOCHandleCollapsed";
            displayValue = "none";
        } 
            
        var handles = tocContainer.querySelectorAll("span.TOCHandle");
        var i;       
        for (i = 0; i < handles.length; i++) {
            handles[i].className = handleClassName;
        }
        
        
        var lists = tocContainer.querySelectorAll("ul");
        for (i = 0; i < lists.length; i++) {
            lists[i].style.display = displayValue;
        }
        
        if (displayValue == "none") {
            var topList = tocContainer.querySelector("ul.TOCItems");
            topList.style.display = "block";        
        }
        
        containerHandle.AllExpanded = !allExpanded;
        
        tocContainer.style.display = displayValue;
        containerHandle.className = handleClassName;
        
    } else {

        if (tocContainer.style.display == "block") {
            tocContainer.style.display = "none";
            containerHandle.className = "TOCHandle TOCHandleCollapsed";
        } else {
            tocContainer.style.display = "block";
            containerHandle.className = "TOCHandle TOCHandleExpanded";
        }
    }
  }
  
    util.toggleTOCVisibility = toggleTOCVisibility;
  
    function toggleLOFVisibility(event, handleId) {
        event = event || window.event;

        var containerHandle = document.getElementById(handleId);
        var lofContainer = containerHandle.parentElement.nextElementSibling;

        if (lofContainer.nextElementSibling.style.display == "block") {
            lofContainer.nextElementSibling.style.display = "none";
            containerHandle.className = "LOFHandle LOFHandleCollapsed";
        } else {
            lofContainer.nextElementSibling.style.display = "block";
            containerHandle.className = "LOFHandle LOFHandleExpanded";
        }
    }

    util.toggleLOFVisibility = toggleLOFVisibility;

    function toggleLOTVisibility(event, handleId) {
        event = event || window.event;

        var containerHandle = document.getElementById(handleId);
        var lotContainer = containerHandle.parentElement.nextElementSibling;

        if (lotContainer.nextElementSibling.style.display == "block") {
            lotContainer.nextElementSibling.style.display = "none";
            containerHandle.className = "LOTHandle LOTHandleCollapsed";
        } else {
            lotContainer.nextElementSibling.style.display = "block";
            containerHandle.className = "LOTHandle LOTHandleExpanded";
        }
    }

    util.toggleLOTVisibility = toggleLOTVisibility;

    function toggleLOCVisibility(event, handleId) {
        event = event || window.event;

        var containerHandle = document.getElementById(handleId);
        var locContainer = containerHandle.parentElement.nextElementSibling;

        if (locContainer.nextElementSibling.style.display == "block") {
            locContainer.nextElementSibling.style.display = "none";
            containerHandle.className = "LOCHandle LOCHandleCollapsed";
        } else {
            locContainer.nextElementSibling.style.display = "block";
            containerHandle.className = "LOCHandle LOCHandleExpanded";
        }
    }

    util.toggleLOCVisibility = toggleLOCVisibility;

    function autoNumber() {
    
            function alphabetize(n) {
                var ordA = 'A'.charCodeAt(0);
                var ordZ = 'Z'.charCodeAt(0);
                var len = ordZ - ordA + 1;
      
                var s = "";
                while(n >= 0) {
                    s = String.fromCharCode(n % len + ordA-1) + s;
                    n = Math.floor(n / len) - 1;
                }
                return s;
            }
    
            function romanize (num) {
            if (!+num)
            return false;
            var	digits = String(+num).split(""),
            key = ["","C","CC","CCC","CD","D","DC","DCC","DCCC","CM",
		       "","X","XX","XXX","XL","L","LX","LXX","LXXX","XC",
		       "","I","II","III","IV","V","VI","VII","VIII","IX"],
            roman = "",
            i = 3;
            while (i--)
            roman = (key[+digits.pop() + (i * 10)] || "") + roman;
            return Array(+digits.join("") + 1).join("M") + roman;
        }
        
        function formatNumber(number, format) {
            var formattedNumber =  "";
            switch (format) {
                case "n":
                case "N":
                    formattedNumber = number.toString();
                break;
                case "a":
                    formattedNumber = alphabetize(number).toLowerCase();
                    break;
                case "A":
                    formattedNumber = alphabetize(number);
                    break;
                case "i":
                    formattedNumber = romanize(number).toLowerCase();
                break;
                case "I":
                    formattedNumber = romanize(number);
                break;
                default:
                    formattedNumber = number.toString();
            }
            return formattedNumber;
        }
        
    var nodes = document.querySelectorAll("h1, h2, h3, h4, h5, h6, autonumber");
    var h1Counter = 0;
    var h2Counter = 0;
    var h3Counter = 0;
    var h4Counter = 0;
    var h5Counter = 0;
    var h6Counter = 0;
    var dict = {};
    for (var i = 0; i < nodes.length; i++) {
        node = nodes[i];
        switch (node.nodeName.toLowerCase()) {
            case "h1":
                h1Counter = h1Counter + 1;
                h2Counter = 0;
                dict["figure"] = 0;
                dict["table"] = 0;
                break;
            case "h2":
                h2Counter = h2Counter + 1;
                h3Counter = 0;
                break;
            case "h3":
                h3Counter = h3Counter + 1;
                h4Counter = 0;              
                break;
            case "h4":
                h4Counter = h4Counter + 1;
                h5Counter = 0;
                break;
            case "h5":
                h5Counter = h5Counter + 1;
                h6Counter = 0;
                break;
            case "h6":
                h6Counter = h6Counter + 1;
                break;
            case "autonumber":
                var counterName = node.getAttribute("stream-name");
                var number = null;
                switch (counterName.toLowerCase()) {
                    case "h1":
                        number = h1Counter;
                        break;
                    case "h2":
                        number = h2Counter;
                        break;
                    case "h3":
                        number = h3Counter;             
                        break;
                    case "h4":
                        number = h4Counter;
                        break;
                    case "h5":
                        number = h5Counter;
                        break;
                    case "h6":
                        number = h6Counter;
                        break;
                }
                var resets = node.parentElement.style["counter-reset"].split(" ");
                for (var r = 0; r < resets.length - 1; r++) {
                    dict[resets[r]] = 0;
                }
                if (number == null) {
                      if (!dict[counterName])
                          dict[counterName] = 0;

                      var t = node.parentElement.style["counter-increment"].split(" ")[0];
                      if (t == counterName) {
                          dict[counterName] += 1;
                      }
                      number = dict[counterName];
                }
                var format = node.getAttribute("format");
                format = format ? format : "n";
                node.innerHTML = formatNumber(number, format);
                break
            default:
                number = "";
            }
        
        
        } 
    }
  
    util.autoNumber = autoNumber;
  
    function renameSpanToAutonumber() {
        var nodes = document.querySelectorAll("span.an_sect1, span.an_figure, span.an_table, span[stream-name]");
        for (var i = 0; i < nodes.length; i++) {
            var node = nodes[i];
            var streamName = node.getAttribute("stream-name");
            if(!streamName){
                switch(node.className){
                    case "an_sect1":
                        streamName = "h1";
                        break;
                    case "an_table":
                        streamName = "table";
                        break;
                    case "an_figure":
                        streamName = "figure";
                        break;
                }
            }
            node.setAttribute("stream-name", streamName);
            node.outerHTML = node.outerHTML.replace(/span/g,"autonumber"); 
        }
    }
    util.renameSpanToAutonumber = renameSpanToAutonumber;
  
})(util || (util = {}))