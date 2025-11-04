class AIAgent extends App.ControllerAIFeatureBase
  @extend App.PopoverProvidable
  @registerPopovers 'ReferenceList'

  @requiredPermission: 'admin.ai_agent'
  header: __('AI Agents')

  constructor: ->
    super

    App.AIAgentType.fetchFull(=>

      callbackAgentTypeAttribute = (value, object, attribute, attributes) ->
        return App.AIAgentType.findByAttribute('custom', true)?.displayName() or '-' if not object.agent_type

        App.AIAgentType.find(object.agent_type)?.displayName() or '-'

      callbackReferenceAttribute = (object, attribute, key, title, translationMultiple) ->
        return '-' if _.isEmpty(object.references?[key])

        attribute.class = 'reference-list-popover'
        attribute.data =
          type: key
          title: title
          ids: _.map(object.references[key] || [], (obj) -> obj.id)

        return App.i18n.translateInline(translationMultiple, object.references[key].length) if object.references[key].length > 1

        object.references[key][0].name

      callbackTriggersAttribute = (value, object, attribute, attributes) ->
        callbackReferenceAttribute object, attribute, 'Trigger', __('AI agent used in triggers'), __('%s triggers')

      callbackJobsAttribute = (value, object, attribute, attributes) ->
        callbackReferenceAttribute object, attribute, 'Job', __('AI agent used in schedulers'), __('%s schedulers')

      @genericController = new AIAgentIndex(
        el: @el
        id: @id
        genericObject: 'AIAgent'
        defaultSortBy: 'name'
        searchBar: true
        searchQuery: @search_query
        pageData:
          home: 'ai_agents'
          object: __('AI Agent')
          objects: __('AI Agents')
          searchPlaceholder: __('Search for AI agents')
          pagerAjax: true
          pagerBaseUrl: '#ai/ai_agents/'
          pagerSelected: ( @page || 1 )
          pagerPerPage: 50
          navupdate: '#ai/ai_agents'
          buttons: [
            { name: __('New AI Agent'), 'data-type': 'new', class: 'btn--success' }
          ]
          tableExtend:
            callbackAttributes:
              agent_type: [ callbackAgentTypeAttribute ]
              triggers: [ callbackTriggersAttribute ]
              jobs: [ callbackJobsAttribute ]
        container: @el.closest('.content')
        large: true
        handlers: [
          App.FormHandlerAIAgentTypeHelp.run
          App.FormHandlerAIAgentUnusedWarning.run
        ]
        renderCallback: =>
          @renderPopovers()
          @renderAlert()
        validateOnSubmit: (params) ->
          @maybeHandleJSONParams('parse', params)
      )
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController?.paginate(@page || 1, params)

class AIAgentIndex extends App.ControllerGenericIndex
  editControllerClass: -> EditAIAgent
  newControllerClass: -> NewAIAgent

AIAgentModalMixin =
  step: 'initial'
  stepFields: []
  buttonSubmit: __('Next')
  buttonClass: 'btn--primary'
  headIcon: 'ai-agent'
  headIconClass: 'ai-modal-head-icon'

  placeholderObjectAttributes: {}

  events:
    'click .js-back': 'handleBack'

  # Set field values from params into target, but only for fields in our field list
  setCurrentSetupFormFields: (target, params) ->

    # Early return if no form fields to process
    return target if @stepFields.length is 0 || !params

    result = $.extend(true, {}, target)

    # Explicitly set values from params into target, but only for our defined fields
    for fieldName in @stepFields
      # Handle nested field paths (e.g., "definition::instruction_context::object_attributes::group_id")
      if fieldName.indexOf('::') > -1
        # Split the field path once
        pathParts = fieldName.split('::')

        # Navigate through params to get the value
        paramsValue = params
        for part in pathParts
          if paramsValue?[part] isnt undefined
            paramsValue = paramsValue[part]
          else
            paramsValue = undefined
            break

        # Navigate/create the nested structure in result
        currentObj = result
        for i in [0...pathParts.length - 1]
          part = pathParts[i]
          if !currentObj[part] or !_.isObject(currentObj[part])
            currentObj[part] = {}
          currentObj = currentObj[part]

        # Set the final value
        finalPart = pathParts[pathParts.length - 1]
        currentObj[finalPart] = paramsValue
      else
        # Simple field, set value from params directly
        result[fieldName] = params[fieldName]

    result

  maybeSetAgentType: ->
    return if @agentType?.id is @params?.agent_type

    if @params?.agent_type
      @agentType = App.AIAgentType.find(@params.agent_type)
    else if @item?.agent_type
      @agentType = App.AIAgentType.find(@item.agent_type)

  maybeSetPlaceholderObjectAttributes: ->
    return if not @agentType or @agentType?.placeholder_field_names.length is 0 or not @params.type_enrichment_data

    for fieldName in @agentType.placeholder_field_names
      continue if not @params.type_enrichment_data[fieldName]

      placeholder_attribute = App.Ticket.configure_attributes.find((elem) => elem.name == @params.type_enrichment_data[fieldName])

      continue if not placeholder_attribute

      @placeholderObjectAttributes[fieldName] = placeholder_attribute

  steps: ->
    _.map(@agentType?.form_schema, (item) -> item.step) or []

  firstStep: ->
    @steps()[0]

  lastStep: ->
    @steps()[@steps().length - 1]

  nextStep: ->
    return 'metadata' if not @steps().length or @step is @lastStep()

    @steps()[_.indexOf(@steps(), @step) + 1]

  stepHelp: ->
    _.find(@agentType?.form_schema, (item) => item.step is @step and item.help)?.help or ''

  stepErrors: ->
    _.find(@agentType?.form_schema, (item) => item.step is @step and item.errors)?.errors or ''

  previousStep: ->
    return 'initial' if not @steps().length or @step is @firstStep()

    @steps()[_.indexOf(@steps(), @step) - 1]

  setStepFields: (attrs) ->
    @stepFields = _.map(attrs, (attr) -> attr.name)

  contentFormParams: ->
    @params = $.extend(true, {}, @item) if _.isEmpty(@params) # init params
    @params.agent_type = App.AIAgentType.findByAttribute('custom', true).id if @params and not @params.agent_type
    @maybeHandleJSONParams('stringify')
    @params

  contentFormModel: ->
    @maybeSetAgentType()
    @maybeSetPlaceholderObjectAttributes()

    attrs = $.extend(true, [], App.AIAgent.configure_attributes)

    if @step is 'initial'
      attrs = _.filter(attrs, (attr) -> attr.name is 'name' or attr.name is 'agent_type')

      agent_type_attribute = attrs.find((attr) -> attr.name is 'agent_type')

      # Disable `agent_type` field if the item is already persisted.
      if @item?.id
        agent_type_attribute.disabled = true
        agent_type_attribute.null = true

      # Filter out custom agent type if the item is not persisted.
      else
        agent_type_attribute.filter = (types) -> _.filter(types, (type) -> not type.custom)

      @setStepFields(attrs)
    else if @step is 'metadata'
      attrs = _.filter(attrs, (attr) -> attr.name is 'note' or attr.name is 'active')

      @setStepFields(attrs)
    else
      attrs = _.find(@agentType.form_schema, (item) => item.step is @step)?.fields or []

      # We need to set the fields before the filtering, because also fields which are not shown are interesting.
      # E.g. when a field was existing before we need to reset the value again.
      @setStepFields(attrs)

      # Filter attrs based on conditions
      attrs = _.filter(attrs, (attr) =>
        # If no condition is specified, include the attribute.
        return true if not attr.condition

        # Parse the condition (format: "key.property").
        conditionParts = attr.condition.split('.')
        return true if conditionParts.length isnt 2

        [placeholderKey, propertyName] = conditionParts

        # Check if the placeholder attribute exists and has the specified property.
        placeholderAttr = @placeholderObjectAttributes?[placeholderKey]
        return false if not placeholderAttr

        # Check if the property exists and is truthy
        return placeholderAttr[propertyName] is true
      )

    { configure_attributes: attrs }

  validateParams: (e) ->
    params = @formParam(e.target)
    newParams = @setCurrentSetupFormFields(@params, params)

    @item.load newParams

    # Validate form using HTML5 validity check.
    element = $(e.target).closest('form').get(0)
    if element && element.reportValidity && !element.reportValidity()
      return false

    # Validate object against the form.
    errors = @item.validate(
      controllerForm: @controller
    )

    if @validateOnSubmit
      errors = _.extend({}, errors, @validateOnSubmit(params))

    if !_.isEmpty(errors)
      @log 'error', errors
      @formValidate( form: e.target, errors: errors )
      return false

    @params = newParams

    @maybeSetAgentType()
    @maybeSetPlaceholderObjectAttributes()

    true

  renderStep: (e) ->
    @update()

    return if @step is 'initial' or @step is 'metadata'

    if helpText = @stepHelp()
      $('<p />').addClass('text-muted')
        .html(App.i18n.translateContent(helpText))
        .prependTo(@controller.form)

    return if not errorTexts = @stepErrors()

    alert = $('<div />').addClass('alert alert--danger')

    if _.isArray(errorTexts)
      alert.html(App.i18n.translateContent(errorTexts...))
    else
      alert.html(App.i18n.translateContent(errorTexts))

    alert.prependTo(@controller.form)

    App.ControllerForm.disable(@controller.form)

  handleBack: (e) ->
    return false if @step is 'initial'

    e.stopPropagation()
    e.preventDefault()

    return if not @validateParams(e)

    if @step is 'metadata' and @steps().length
      @step = @lastStep()
      @buttonSubmit = __('Next')
      @buttonClass = 'btn--primary'

    else
      @step = @previousStep()

      if @step is 'initial'
        @buttonSubmit = __('Next')
        @buttonClass = 'btn--primary'
        @buttonCancel = __('Cancel & Go Back')
        @leftButtons = []

    @renderStep(e)

    true

  handleNext: (e) ->
    return false if @step is 'metadata'

    return false if not @validateParams(e)

    if @step is 'initial' and @steps().length
      @step = @firstStep()
      @buttonCancel = false
      @leftButtons = [
        {
          text: __('Back')
          className: 'js-back'
        }
      ]

    else
      @step = @nextStep()

      if @step is 'metadata'
        @buttonSubmit = __('Submit')
        @buttonClass = 'btn--success'
        @buttonCancel = false
        @leftButtons = [
          {
            text: __('Back')
            className: 'js-back'
          }
        ]

    @renderStep(e)

    true

  maybeHandleJSONParams: (action, params = @params) ->
    return {} if not @agentType?.form_schema

    jsonFields = ['code_editor']

    # Get all supported fields from the form schema.
    codeEditorFields = []
    for schemaItem in @agentType.form_schema
      for field in schemaItem.fields or []
        if _.includes(jsonFields, field.tag)
          codeEditorFields.push(field.name)

    # Process each field.
    for fieldName in codeEditorFields

      # Split the field path by '::' delimiter.
      pathParts = fieldName.split('::')

      # Navigate through params to get the value
      paramsValue = params
      for part in pathParts
        if paramsValue?[part] isnt undefined
          paramsValue = paramsValue[part]
        else
          paramsValue = undefined
          break

      # Only proceed if we found a value.
      if paramsValue isnt undefined

        # Check if transformation is needed.
        if (action is 'stringify' and _.isObject(paramsValue)) or (action is 'parse' and _.isString(paramsValue))

          # Navigate/create the nested structure in params.
          currentObj = params
          for i in [0...pathParts.length - 1]
            part = pathParts[i]
            if not currentObj[part] or not _.isObject(currentObj[part])
              currentObj[part] = {}
            currentObj = currentObj[part]

          # Set the final value
          finalPart = pathParts[pathParts.length - 1]

          try
            currentObj[finalPart] = JSON[action](paramsValue, null, 2)
          catch
            return {
              "#{fieldName}": __('Please enter a valid JSON string.')
            }

    {}

class EditAIAgent extends App.ControllerGenericEdit
  @include AIAgentModalMixin

  onSubmit: (e) =>
    return if @handleNext(e)

    @maybeHandleJSONParams('parse')

    # Load the current params into the item.
    #   Super method will only know about the current step params.
    @item.load(@params)

    # Step is `metadata`, call the super method to save the item.
    super

class NewAIAgent extends App.ControllerGenericNew
  @include AIAgentModalMixin

  constructor: (params) ->
    # Clear ID passed by the clone action.
    params.item.id = null if params.item?.id

    super

    @item = params.item or new App[ @genericObject ]

  onSubmit: (e) =>
    return if @handleNext(e)

    @maybeHandleJSONParams('parse')

    params = @formParam(e.target)
    newParams = @setCurrentSetupFormFields(@params, params)

    @item.load(newParams)

    # Validate form using HTML5 validity check.
    element = $(e.target).closest('form').get(0)
    if element && element.reportValidity && !element.reportValidity()
      return false

    # Validate object against the form.
    errors = @item.validate(
      controllerForm: @controller
    )

    if @validateOnSubmit
      errors = _.extend({}, errors, @validateOnSubmit(params))

    if !_.isEmpty(errors)
      @log 'error', errors
      @formValidate( form: e.target, errors: errors )
      return false

    # Disable form.
    @formDisable(e)

    # Save object.
    ui = @
    @item.save(
      done: ->
        if ui.callback
          item = App[ ui.genericObject ].fullLocal(@id)
          ui.callback(item)
        ui.close()

      fail: (settings, details) =>
        ui.log 'errors', details
        ui.formEnable(e)

        if details && details.invalid_attribute
          @formValidate( form: e.target, errors: details.invalid_attribute )
        else
          ui.controller.showAlert(details.error_human || details.error || __('The object could not be created.'))
    )

App.Config.set('AIAgents', { prio: 1300, name: __('AI Agents'), parent: '#ai', target: '#ai/ai_agents', controller: AIAgent, permission: ['admin.ai_agent'] }, 'NavBarAdmin')
