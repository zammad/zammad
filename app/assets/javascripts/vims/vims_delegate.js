class DelegateModal {
	static delegate(id){
		  let url = 'https://vims-orchestrator.azurewebsites.net/api/azuredevops';
		  $.post( url, { vimsid: id }, function(data){
			  DelegateIncident();		
		  });
	}
	
	  static DelegateIncident(){
		  var stateDd = $('[name="vims_status"]');
		  stateDd.val('delegated');
		  stateDd.change();
	  }
  }
  
  DelegateModal.html = `  
	  <div id="vimsDelegateModal" class="vims-modal">
		  <p>Are you sure you want to delegate this incident?</p>
		  <p>
			  <a href="#" rel="vims-modal:close">Close</a>
			  &nbsp;
			  <input type="button" value="Ok" onclick="Delegate()" rel="vims-modal:close"/>
		  </p>
	  </div>  
  `;
  
  DelegateModal.css = '<link id="cssModal" rel="stylesheet" href="https://combinatronics.com/GeorgePlotnikov/VIAcode-Incident-Management-System/develop/app/assets/javascripts/vims/vims_modal.css" />';
  
  function SendDelegation(){
	  let ticketId = document.URL.substr(document.URL.lastIndexOf('/') + 1);
	  $.get('https://vims-orchestrator.azurewebsites.net/api/VimsOrganizationAzureDevOpsSettings', { vimsid: ticketId }, function(resp){
		$('#vimsDelegateModal').vims_modal();		
	  });
  }

  function Delegate(){
	let ticketId = document.URL.substr(document.URL.lastIndexOf('/') + 1);
	DelegateModal.delegate(ticketId);
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
