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
  

  function SendDelegation(){
	  let ticketId = document.URL.substr(document.URL.lastIndexOf('/') + 1);
	  $.get(GetOrchestratorUrl() + '/vo-api/VimsOrganizationAzureDevOpsSettings', { vimsid: ticketId }, function(resp){
		$('#vimsDelegateModal').vims_modal();		
	  }).fail(function(data) {
        if(![400, 403, 404, 408, 500, 502, 503].includes(data.status)){
            return;
        }
		    new AlertModal().show('Azure DevOps Connector API cannot be reached. Please check if Azure DevOps connector is deployed and configured <link to Azure DevOps AMP>');
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
		  $('#vims').append('<div id="vims-alertModal" class="vims-modal vims-alert-modal"><span id="vims-alertModal-text"></span></div>');
		  $('#vims-alertModal-text').html(text);
		  $('#vims-alertModal').vims_modal();		
		  $('#vims-alertModal').on($.vims_modal.AFTER_CLOSE, function(event, modal){
			  $('#vims-alertModal').remove();
		  });
	  }
  }
