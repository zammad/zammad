class DelegateModal {

	static delegate(id){
		  let url = 'https://vimsorchestrator.azurewebsites.net/api/azuredevops';
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
  <div id="vims">
	  <div id="vimsDelegateModal" class="vims-modal">
		  <p>Are you sure you want to delegate this incident?</p>
		  <p>
			  <a href="#" rel="vims-modal:close">Close</a>
			  &nbsp;
			  <input type="button" value="Ok" onclick="SendDelegation()"/>
		  </p>
	  </div>
  </div>
  `;
  
  DelegateModal.css = '<link id="cssModal" rel="stylesheet" href="https://combinatronics.com/viacode/VIAcode-Incident-Management-System/develop/app/assets/javascripts/vims/vims_modal.css" />';
  
  function SendDelegation(){
	  $.get('', function(resp){
		$.vims_modal.show();
		DelegateModal.delegate(document.URL.substr(document.URL.lastIndexOf('/') + 1));
		$.vims_modal.close();
	  });
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
