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

  # built-in Spine's function doesn't work when object has no ID set and includes "undefined" in URL
  urlFor: (object) ->
    if object.id
      object.generateURL()
    else
      object.url()

  saveChanges: (object, data, formController, action) ->
    App.ControllerForm.disable(formController.form)

    url = @urlFor(object) + '?full=true'

    if action
      url += "&additional_action=#{action}"

    App.Ajax.request(
      type: object.writeMethod()
      data: JSON.stringify(data)
      url: url
      success: (data) ->
        App.Collection.loadAssets(data.assets)
        formController.didSaveCallback(data)
      error: (xhr) ->
        data = JSON.parse(xhr.responseText)
        App.ControllerForm.enable(formController.form)
        formController.showAlert(data.error || 'Unable to save changes.')
    )
