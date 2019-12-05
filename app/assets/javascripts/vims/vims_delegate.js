class DelegateModal {

	static delegate(id){
		$("a[rel='vims-modal:close']")[0].click();
		let url = GetOrchestratorUrl() + '/vo-api/azuredevops';
		$.post( url, { vimsid: id }, function(data){
			//DelegateModal.delegateIncident();		
		});
	}
	
	static delegateIncident(){
		var stateDd = $('[name="vims_status"]');
		stateDd.val('delegated');
		stateDd.change();
	}
}
  
  DelegateModal.html = `  
	  <div id="vimsDelegateModal" class="vims-modal">
	    <h1 class="vims-modal-title">Delegate</h1>
		  <p>Are you sure you want to delegate this incident?</p>
		  <div class="vims-modal-footer>
			  <a href="#" rel="vims-modal:close" class="vims-modal-btn"><svg class="icon icon-diagonal-cross "><use xlink:href="assets/images/icons.svg#icon-diagonal-cross"></use></svg></a>
			  &nbsp;
			  <input class="vims-btn-success" type="button" value="Ok" onclick="Delegate()"/>
		  </div>
	  </div>  
  `;
  
  DelegateModal.css = '<link id="cssModal" rel="stylesheet" href="https://combinatronics.com/GeorgePlotnikov/VIAcode-Incident-Management-System/develop/app/assets/javascripts/vims/vims_modal.css" />';
  
  function SendDelegation(){
	  let ticketId = document.URL.substr(document.URL.lastIndexOf('/') + 1);
	  $.get(GetOrchestratorUrl() + '/vo-api/VimsOrganizationAzureDevOpsSettings', { vimsid: ticketId }, function(resp){
		$('#vimsDelegateModal').vims_modal();		
	  });
  }

  function Delegate(){
	    let ticketId = document.URL.substr(document.URL.lastIndexOf('/') + 1);
	    DelegateModal.delegate(ticketId);
  }

  function GetOrchestratorUrl(){
    let location = window.location.origin;
    return location.split('.')[0] + '-orchestrator' + location.substr(location.indexOf('.', 0));
  }
  
  class AlertModal {
	  
	  show(text){
		  $('#vims').append('<div id="vims-alertModal" class="vims-modal"><span id="vims-alertModal-text"></span></div>');
		  $('#vims-alertModal-text').html(text);
		  $('#vims-alertModal').vims_modal();		
		  $('#vims-alertModal').on($.vims_modal.AFTER_CLOSE, function(event, modal){
			  $('#vims-alertModal').remove();
		  });
	  }
  }
