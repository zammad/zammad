class App.KnowledgeBaseFormController extends App.ControllerForm
  # set screen to agent_edit or agent_create
  constructor: (object, kb_locale, screen, dom) ->
    @object    = object
    @kb_locale = kb_locale

    objectParams = @currentParams()
    objectParams['form_id'] = App.ControllerForm.formId()

    super(
      params:    objectParams
      autofocus: dom isnt null
      grid:      true
      el:        dom || $('<form>')
      screen:    screen
      model:     { configure_attributes: @getAttrs() }
    )

  getAjaxAttributes: (field, attributes) ->
    @apiPath = App.Config.get('api_path')

    attributes.type = 'POST'
    attributes.url  =  "#{@apiPath}/knowledge_bases/search"

    attributes.data.flavor            = 'agent'
    attributes.data.knowledge_base_id = @object.knowledge_base().id
    attributes.data.exclude_ids       = [@object.translation(@kb_locale.id)?.id]
    attributes.data.index             = 'KnowledgeBase::Answer::Translation'
    attributes.data.locale            = @kb_locale.systemLocale().locale
    attributes.data.highlight_enabled = false

    attributes.data = JSON.stringify(attributes.data)

    attributes

  currentParams: ->
    @object.attributesIncludingTranslation(@kb_locale.id)

  rawParams: ->
    App.ControllerForm.params(@el)

  paramsForSaving: ->
    @object.prepareNestedParams(@rawParams(), @kb_locale.id)

  validateAndShowErrors: ->
    errors = @validate(@rawParams())

    @constructor.validate(
      errors: errors
      form:   @.el
    )

    !errors

  getAttrs: ->
    attrs = @object.configure_attributes?(@kb_locale) || @object.constructor.configure_attributes

    attrs.push {
      name: 'form_id'
      tag:  'input'
      type: 'hidden'
    }

    attrs

  @compareParams: (a, b) ->
    for params in [a, b]
      delete params.form_id
    _.isEqual(a, b)
