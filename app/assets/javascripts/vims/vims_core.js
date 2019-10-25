(function() {	
	let modalJQueryScript = document.createElement("SCRIPT");
	modalJQueryScript.type = 'text/javascript';
	modalJQueryScript.src = "/assets/vims/vims_modal.js";
	modalJQueryScript.defer = "defer";
	$('body').append(modalJQueryScript);	

	let vimsDelegateScript = document.createElement("SCRIPT");
	vimsDelegateScript.src = "/assets/vims/vims_delegate.js";
	vimsDelegateScript.type = 'text/javascript';
	vimsDelegateScript.defer = "defer";
	$('body').append(vimsDelegateScript);		

	let observer = new MutationObserver(mutationRecords => {
		InsertDelegateMenu();
	});		

	observer.observe((document.documentElement || document.body), {
		childList: true,
		subtree: false, // and lower descendants too
		characterDataOldValue: false // pass old data to callback
	});

	function InsertDelegateMenu(){
		let nav = $('#navigation > div.tasks.tasks-navigation.ui-sortable');
		let ticketsCount = nav.children().length;
		for(let i = 0; i < ticketsCount; i++){
			let selector = "#content_permanent_Ticket-" + (i + 1);
			let menu = $(selector + ' > div > div.tabsSidebar.tabsSidebar--attributeBarSpacer.vertical > div:nth-child(1) > div.sidebar-header > div.sidebar-header-actions.js-actions > div > ul');
			if(menu == undefined || menu.length == 0 || $("#vimsDelegateLi").length > 0){
				console.log("menu not found");
				continue;
			}
			console.log("menu found");
			menu.append('<li><a id="vimsDelegateLi" role="menuitem" tabindex="-1" href="#delegateModal" rel="modal:open">Delegate</a></li>');
		}	
		if(DelegateModal){
			if($('#cssModal').length == 0){
				$('head').append(DelegateModal.css);
			}
			if($('#delegateModal').length == 0){
				$('body').append(DelegateModal.html);
			}	
		}
		$('#vimsDelegateLi').click(function(e) { 		 
			e.preventDefault();		
			//DelegateIncident();
		});
	}

	function DelegateIncident(){
		var stateDd = $('[name="vims_status"]');
		stateDd.val('delegated');
		stateDd.change();
	}
})();