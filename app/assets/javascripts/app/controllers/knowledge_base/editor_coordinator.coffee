class App.KnowledgeBaseEditorCoordinator
  constructor: (params) ->
    for key, value of params
      @[key] = value

  clickedCanBePublished: (object) ->
    new App.KnowledgeBaseContentCanBePublishedDialog(
      object:    object
      container: @parentController.el
    )

  clickedDelete: (object) ->
    new App.KnowledgeBaseDeleteAction(
      object:           object
      parentController: @parentController
    )

  clickedPermissions: (object) ->
    new App.KnowledgeBasePermissionsDialog(
      object:    object
      container: @parentController.el
    )

  # built-in Spine's function doesn't work when object has no ID set and includes "undefined" in URL
  urlFor: (object) ->
    if object.id
      object.generateURL()
    else
      object.url()

  submitDisable: (e) =>
    if e
      App.ControllerForm.disable(e)
      return
    App.ControllerForm.disable(@$('.js-submitContainer'), 'button')

  submitEnable: (e) =>
    if e
      App.ControllerForm.enable(e)
      return
    App.ControllerForm.enable(@$('.js-submitContainer'), 'button')

  saveChanges: (object, data, formController, e, action) ->
    @submitDisable(e)

    url = @urlFor(object) + '?full=true'

    if action
      url += "&additional_action=#{action}"

    App.Ajax.request(
      type: object.writeMethod()
      data: JSON.stringify(data)
      url: url
      success: (data) =>
        App.Collection.loadAssets(data.assets)
        formController.didSaveCallback(data)
        @submitEnable(e)
      error: (xhr) =>
        data = JSON.parse(xhr.responseText)
        formController.showAlert(data.error || __('The changes could not be saved.'))
        @submitEnable(e)
    )
