var moduletabs;
(function (moduletabs) {

    function openTab() {
        var tabToOpen = 0;
        var tabLabelButtons = document.getElementsByClassName("HTMLModuleTabsLabelButton");
          for (var i = 0; i < tabLabelButtons.length; i++) {
            if (event.currentTarget.innerHTML == tabLabelButtons[i].innerHTML) {
                if (!tabLabelButtons[i].className.endsWith(" active")) {
                    tabLabelButtons[i].className += " active";
                }
                tabToOpen = i;
            } else {
                tabLabelButtons[i].className = tabLabelButtons[i].className.replace(" active", "");
            }
          }

          var tabcontent = document.getElementsByClassName("HTMLModuleTabsContentPane");
          for (var j = 0; j < tabcontent.length; j++) {
            if (j == tabToOpen) {
                tabcontent[j].style.display = "block";
            } else {
                tabcontent[j].style.display = "none";
            }
          }
    }
    moduletabs.openTab = openTab;

    function clickFirstTab() {
        var tabLabelButtons = document.getElementsByClassName("HTMLModuleTabsLabelButton");
        if (tabLabelButtons.length != 0) {
            tabLabelButtons[0].click();
        }
    }
    moduletabs.clickFirstTab = clickFirstTab;

    function closeTabs() {
        // close the current content pane
        event.currentTarget.parentElement.style.display='none';

        // Make all tabs to be inactive
        var tabLabelButtons = document.getElementsByClassName("HTMLModuleTabsLabelButton");
        for (var i = 0; i < tabLabelButtons.length; i++) {
            tabLabelButtons[i].className = tabLabelButtons[i].className.replace(" active", "");
        }
    }
    moduletabs.closeTabs = closeTabs;

})(moduletabs || (moduletabs = {}));