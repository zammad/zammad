(function() {	
	let modalJQueryScript = document.createElement("SCRIPT");
	modalJQueryScript.type = 'text/javascript';
	modalJQueryScript.src = "assets/vims/vims_modal.js";
	modalJQueryScript.defer = "defer";
	$('body').append(modalJQueryScript);	

	let vimsDelegateScript = document.createElement("SCRIPT");
	vimsDelegateScript.src = "assets/vims/vims_delegate.js";
	vimsDelegateScript.type = 'text/javascript';
	vimsDelegateScript.defer = "defer";
	$('body').append(vimsDelegateScript);		
	$('body').append('<div id="vims"></div>');
	$('head').append('<link id="cssModal" rel="stylesheet" href="assets/vims/vims_modal.css" />');

	let observer = new MutationObserver(mutationRecords => {
		InsertDelegateMenu();
	});		

	observer.observe((document.documentElement || document.body), {
		childList: true,
    subtree: true,
		characterDataOldValue: false // pass old data to callback
	});

	function InsertDelegateMenu(){
        let currTicket = $('#navigation > div.tasks.tasks-navigation.ui-sortable').find('.is-active');
        if(currTicket == undefined || currTicket.length == 0){
            return;
        }

        let currTickerDomSelector = currTicket[0];
        let ticketData = currTickerDomSelector.dataset.key;
        if(!ticketData.startsWith('Ticket-')){
            return;
        }
        let ticketId = ticketData.substr(ticketData.indexOf('-') + 1);
        let selector = "#content_permanent_Ticket-" + ticketId;
        let menu = $(selector + ' > div > div.tabsSidebar.tabsSidebar--attributeBarSpacer.vertical > div:nth-child(1) > div.sidebar-header > div.sidebar-header-actions.js-actions > div > ul');
        if(menu == undefined || menu.length == 0 || $("#vimsDelegateLi").length > 0){
            console.log("menu not found");
            return;
        }
        console.log("menu found");
        menu.append('<li onclick="SendDelegation()"><a id="vimsDelegateLi" role="menuitem" tabindex="-1">Delegate</a></li>');

		try {
			if(DelegateModal){
			  if($('#vimsDelegateModal').length == 0){
				  $('#vims').append(DelegateModal.html);
			  }	
			}
		} catch (e) {
			if (e instanceof ReferenceError) {
				console.log("Looking for DelegateModal");
			}
		}
	}	
})();
