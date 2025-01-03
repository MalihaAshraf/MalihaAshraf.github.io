var sidebar;
(function (sidebar) {

    function createSidebar() {
        // Get all the body content now, this will exclude TOC/LOX. Wrap them in container div
        var contentWrapper = document.createElement('div');
        contentWrapper.className = 'container';

        // Move the body's children into this wrapper and then append wrapper to the body
        while (document.body.firstChild) {
            contentWrapper.appendChild(document.body.firstChild);
        }
        document.body.appendChild(contentWrapper);

        // Add button to open side bar
        var sidebarButton = document.createElement('button');
        sidebarButton.innerHTML = '&#9776';
        sidebarButton.className = 'sidebar-button';

        // Add mouse events to open and close sidebar
        sidebarButton.addEventListener("mouseover", function () {
            openSidebar();

            highlightSelectedEntry();

            var sideBar = document.getElementById("Sidebar");
            sideBar.addEventListener("mouseleave", closeSidebar);
        });

        // Add touch events to open and close Sidebar
        sidebarButton.addEventListener("touchstart", function () {
            openSidebar();

            highlightSelectedEntry();

            var overlay = document.getElementById("SidebarOverlay");
            overlay.addEventListener("touchstart", closeSidebar);
        });

        contentWrapper.parentNode.insertBefore(sidebarButton, contentWrapper);

        // Add div for overlay
        var overlayDiv = document.createElement('div');
        overlayDiv.id = 'SidebarOverlay';
        overlayDiv.className = 'overlay animate-opacity';
        sidebarButton.parentNode.insertBefore(overlayDiv, sidebarButton);

        var sidebarWrapper = document.createElement('div');
        sidebarWrapper.id = 'Sidebar';
        sidebarWrapper.className = 'sidebar-wrapper sidebar-animate-left';
        overlayDiv.parentNode.insertBefore(sidebarWrapper, overlayDiv);

        // Function to open sidebar
        function openSidebar() {
            document.getElementById("Sidebar").style.display = "block";
            document.getElementById("SidebarOverlay").style.display = "block";
        }

        // Function to close sidebar
        function closeSidebar() {
            document.getElementById("Sidebar").style.display = "none";
            document.getElementById("SidebarOverlay").style.display = "none";
        }

        // Function to highlight the selected entry in the TOC
        function highlightSelectedEntry() {
            var sidebarItemList = document.getElementsByClassName('SidebarItemTitle');
            for (var i = 0; i < sidebarItemList.length; i++) {
                sidebarItemList[i].addEventListener('click', function (event) {
                    for (var j = 0; j < sidebarItemList.length; j++) {
                        sidebarItemList[j].classList.remove('current-sidebar-item');
                    }
                    event.target.classList.add('current-sidebar-item');
                });
            }
        }
    }
    sidebar.createSidebar = createSidebar;

    function appendData(data) {
        var sidebarWrapper = document.getElementById("Sidebar");
        sidebarWrapper.appendChild(data);
    }
    sidebar.appendData = appendData;

})(sidebar || (sidebar = {}));