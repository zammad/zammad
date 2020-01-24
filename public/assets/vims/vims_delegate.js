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
  

  function SendDelegation(){
	  let ticketId = document.URL.substr(document.URL.lastIndexOf('/') + 1);
	  $.get(GetOrchestratorUrl() + '/vo-api/VimsOrganizationAzureDevOpsSettings', { vimsid: ticketId }, function(resp){
        if ($('#vimsDelegateModal').length == 0) {
            $('#vims').append(`  
                  <div id="vimsDelegateModal" class="vims-hidden modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                          <a href="#" rel="vims-modal:close" class="modal-close"><svg class="icon icon-diagonal-cross "><use xlink:href="assets/images/icons.svg#icon-diagonal-cross"></use></svg></a>
                          <h1 class="modal-title">Delegate</h1>
                        </div>
                          <div class="modal-body">
                            New Backlog Item will be created for this incident at the connected Azure DevOps project.
                            <br />
                            Backlog Item details:
                            <ul>
                                <li>Backlog Item Name: ` + resp.backlogItemName + `</li>
                                <li>Organization: ` + resp.organization + `</li>
                                <li>Project: ` + resp.project + `</li>
                                <li>Area: ` + resp.area + `</li>
                            </ul>
                          </div>
                          <div class="modal-footer">
                              <div class="modal-leftFooter">
                                <a href="#" rel="vims-modal:close" class="btn btn--subtle btn--text align-left">Cancel & Go Back</a>
                              </div>
                              <div class="modal-rightFooter">
                                <input class="btn btn--success align-right" type="button" value="Ok" onclick="Delegate()"/>
                              </div>
                          </div>
                    </div>
                  </div>
              `);
        }
		$('#vimsDelegateModal').vims_modal({
            showClose: false,
            blockerClass: "vims-blocker-light"
          });		
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
    return location.split('.')[0] + '-azdevops' + location.substr(location.indexOf('.', 0));
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
