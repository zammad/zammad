class DelegateModal {

    static delegate(azInfo){
		let url = 'https://vimsorchestrator.azurewebsites.net/api/azuredevops';
		$.post( url, { azproject: azInfo.azProject, azarea: azInfo.azArea, aztoken: azInfo.azToken, vimsid: azInfo.vimsId }, function(data){
			new AlertModal().show(data);
			DelegateModal.DelegateIncident();		
		});
    }

	static DelegateIncident(){
		var stateDd = $('[name="vims_status"]');
		stateDd.val('delegated');
		stateDd.change();
	}
}

DelegateModal.html = `
	<div id="vims-delegateModal" class="vims-modal">
		<p>Azure project: <input type="text" id="vims-az-project"/></p>
		<p>Azure project area: <input type="text" id="vims-az-project-area"/></p>
		<p>Azure access token: <input type="text" id="vims-az-token"/></p>
		<p>Save settings &nbsp;<input type="checkbox" id="vims-save-settings"/></p>
		<p>
			<a href="#" rel="vims-modal:close">Close</a>
			&nbsp;
			<input type="button" value="Ok" onclick="SendDelegation()"/>
		</p>
	</div>
`;

DelegateModal.modalElement = any;

DelegateModal.css = '<link id="cssModal" rel="stylesheet" href="https://combinatronics.com/GeorgePlotnikov/VIAcode-Incident-Management-System/develop/app/assets/javascripts/vims/vims_modal.css" />';

function SendDelegation(){
	let azInfo = new AzDevOpsConnectionInfo();
	azInfo.azToken = $("#vims-az-token").val();
	azInfo.azProject = $("#vims-az-project").val();
	azInfo.azArea = $("#vims-az-project-area").val();
	azInfo.vimsId = document.URL.substr(document.URL.lastIndexOf('/') + 1);

	DelegateModal.delegate(azInfo);
	$.vims_modal.close();
}

class AzDevOpsConnectionInfo {
	azToken = '';
	azProject = '';
	azArea = '';
	vimsId = 0;
}

class AlertModal {
	
	alertModalHtml = `
	<div id="vims-alertModal" class="vims-modal">
		<span id="vims-alertModal-text"></span>
		<p>
			<input type="button" value="Ok" onclick="SendDelegation()"/>
		</p>
	</div>
	`;

	show(text){
		$('#vims').append(alertModalHtml);
		$('#vims-alertModal-text').val(text);
		$('#vims-alertModal').vims_modal();		
		$('#vims-alertModal').on($.vims_modal.AFTER_CLOSE, function(event, modal){
			$('#vims-alertModal').remove();
		});
	}
}
