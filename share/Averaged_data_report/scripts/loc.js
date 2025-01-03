var loc;
(function (loc) {

    function getLOCElements(root, streamName) {
        var str_prefix = streamName + "_loc_caption_id";
        count = 1;
       
        var ul = document.createElement("ul");
        if(streamName === "figure")
            ul.className = "LOFItems";
        else if (streamName === "table")
            ul.className = "LOTItems";
        else
            ul.className = "LOCItems";
        ul.style.display = "none";
        
        var captions = document.getElementsByClassName("an_" + streamName);
        for (var i = 0; i < captions.length; i++) {
            var node = captions[i];
            var id = str_prefix + count;
            count = count + 1;
            node.parentElement.id = id;
            var li = document.createElement("li");
            var title = document.createElement("a");

            if (streamName === "figure")
                title.className = "LOFItemTitle SidebarItemTitle";
            else if (streamName === "table")
                title.className = "LOTItemTitle SidebarItemTitle";
            else
                title.className = "LOCItemTitle SidebarItemTitle";
            
            title.textContent = node.parentElement.innerText;
            title.href = "#" + id;

            title.addEventListener("click", function (event) {
                //event.preventDefault();
                node.scrollIntoView();
            }, false);
                
            li.appendChild(title);
            ul.appendChild(li);
        }

        return ul;
    }
    loc.getLOCElements = getLOCElements;

})(loc || (loc = {}));