var $x = undefined;

(function() {
    var script = document.createElement("SCRIPT");
    script.src = 'https://code.jquery.com/jquery-3.4.1.min.js';
    script.type = 'text/javascript';
    script.onload = function() {
      $x = jQuery.noConflict();			
			let observer = new MutationObserver(mutationRecords => {
				InsertDelegateMenu();
			});

			observer.observe(app, {
				childList: true, // observe direct children
				subtree: false, // and lower descendants too
				characterDataOldValue: false // pass old data to callback
			});	
			
    };
    document.getElementsByTagName("head")[0].appendChild(script);
})();

function InsertDelegateMenu(){
	var menu = $x('#content_permanent_Ticket-1 > div > div.tabsSidebar.tabsSidebar--attributeBarSpacer.vertical > div:nth-child(1) > div.sidebar-header > div.sidebar-header-actions.js-actions > div > ul');
	if(menu == undefined || menu.length == 0 || $x("#vimsDelegateLi").length > 0){
		console.log("menu not found");
		return;
	}
	console.log("menu found");
	menu.append('<li><a id="vimsDelegateLi" role="menuitem" tabindex="-1" href="#">Delegate</a></li>')
	 $('#vimsDelegateLi').click(function(e) { 		 
         e.preventDefault();
				 DelegateIncident();
      });
}

function DelegateIncident(){
	var stateDd = $('[name="vims_status"]');
	stateDd.val('delegated');
	stateDd.change();
}
