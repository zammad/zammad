class App.KnowledgeBaseAddForm extends App.ControllerModal
  constructor: (params) ->
    for key, value of params
      @[key] = value

    @head = @object.objectActionName()
    super(params)

  buttonSubmit: 'Create'

  content: ->
    kb_locale = @parentController.kb_locale()
    @formController = new App.KnowledgeBaseFormController(@object, kb_locale, 'agent_create', $('<div>'))
    @form = @formController.form # used for disabling inputs during saving
    @formController.el

  submit: (e) ->
    @preventDefaultAndStopPropagation(e)

    if !@formController.validateAndShowErrors()
      return

    params = @formController.paramsForSaving()
    params.translations_attributes[0].content_attributes = { body: '' }

    @parentController.coordinator.saveChanges(@object, params, @)

  showAlert: (text) ->
    @formController?.showAlert(text)

  didSaveCallback: (data) ->
    url = @object.constructor.find(data.id).uiUrl(@parentController.kb_locale(), 'edit')
    @parentController.navigate(url)
