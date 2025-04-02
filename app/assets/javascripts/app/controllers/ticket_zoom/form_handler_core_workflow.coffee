class App.FormHandlerCoreWorkflow
  @DEBUG: false

  # contains the current form params state to prevent mass requests
  coreWorkflowParams = {}

  # contains the running requests of each form
  coreWorkflowRequests = {}

  # contains the restriction values for each attribute of each form
  coreWorkflowRestrictions = {}

  # core workflow will run for every attribute
  # we cache the article params per dispatch because they are expensive to get
  articleParamsCache = {}

  # returns the objects for which Core Workflow is active
  @getObjects: ->
    return Object.keys(App.Config.get('core_workflow_config').execution)

  # returns the screens for which Core Workflow is active
  @getScreens: ->
    return _.uniq(_.flatten(Object.values(App.Config.get('core_workflow_config').execution)))

  # returns if the object and screen is controlled by core workflow
  @checkScreen: (checkObject, checkScreen) ->
    for object, screens of App.Config.get('core_workflow_config').execution
      return true if checkObject is object && _.contains(screens, checkScreen)
    return false

  # returns active Core Workflow requests. it is used to stabilize tests
  @getRequests: ->
    return coreWorkflowRequests

  # Based on the model validation result the controller form
  # will delay the submit if a request of the Core Workflow is running
  @delaySubmit: (controllerForm, target) ->
    for key, value of coreWorkflowRequests
      if controllerForm.idPrefix is value.ui.idPrefix
        coreWorkflowRequests[key].triggerSubmit = target
        return true
    App.FormHandlerCoreWorkflow.triggerSubmit(target)

  # the saved submit target will be executed after the request
  @triggerSubmit: (target) ->
    if $(target).get(0).tagName == 'FORM'
      target = $(target).find('button[type=submit], .btn--success').first()

    $(target).trigger('click')

  # checks if the controller has a running Core Workflow request
  @requestsRunning: (controllerForm) ->
    for key, value of coreWorkflowRequests
      if controllerForm.idPrefix is value.ui.idPrefix
        return true
    return false

  # checks if the Core Workflow should get activated for the screen
  @screenValid: (ui) ->
    return false if !ui.model
    return false if !ui.model.className
    return false if !ui.screen

    config_class = App.Config.get('core_workflow_config').execution[ui.model.className]
    return false if config_class is undefined
    return false if !_.contains(config_class, ui.screen)
    return true

  # checks if the ajax or websocket endpoint should be used
  @useWebSockets: ->
    return if !App.WebSocket.channel()
    return !App.Config.get('core_workflow_ajax_mode')

  @restrictValuesAttributeCache: (attribute, values) ->
    result = { values: values }
    return result if !attribute.relation
    result.lastUpdatedAt = App[attribute.relation].lastUpdatedAt()
    return result

  # restricts the dropdown and tree select values of a form
  @restrictValues: (classname, form, ui, attributes, params, data) ->
    return if _.isEmpty(data.restrict_values)

    for field, values of data.restrict_values
      for attribute in attributes
        continue if attribute.name isnt field

        item      = $.extend(true, {}, attribute)
        el        = App.ControllerForm.findFieldByName(field, form)
        shown     = App.ControllerForm.fieldIsShown(el)
        mandatory = App.ControllerForm.fieldIsMandatory(el)

        # get deep value if needed for store attributes
        paramValue = params[item.name]
        if data.select[item.name] isnt undefined
          paramValue = data.select[item.name]
          coreWorkflowParams[classname][item.name] = paramValue
          delete coreWorkflowRestrictions[classname]

        parts      = attribute.name.split '::'
        if parts.length > 1
          deepValue = parts.reduce((memo, elem) ->
            memo?[elem]
          , params)

          if deepValue isnt undefined
            paramValue = deepValue

        # cache state for performance and only run
        # if values or param differ
        if coreWorkflowRestrictions?[classname]?[item.name]
          compare = App.FormHandlerCoreWorkflow.restrictValuesAttributeCache(attribute, values)
          continue if _.isEqual(coreWorkflowRestrictions[classname][item.name], compare)

        coreWorkflowRestrictions[classname] ||= {}
        coreWorkflowRestrictions[classname][item.name] = App.FormHandlerCoreWorkflow.restrictValuesAttributeCache(attribute, values)

        valueFound = false
        if item.multiple
          if _.isArray(paramValue)
            paramValue = _.intersection(paramValue, values)
            if paramValue.length > 0
              valueFound = true
        else
          for value in values

            # false values are valid values e.g. for boolean fields (be careful)
            continue if value is undefined
            continue if value is null
            continue if paramValue is undefined
            continue if paramValue is null
            continue if value.toString() != paramValue.toString()
            valueFound = true
            break

        item.filter   = values
        if valueFound
          item.default  = paramValue
          item.newValue = paramValue
        else if params.id
          obj = App[ui.model.className].find(params.id)
          if obj && obj[item.name]
            item.default  = obj[item.name]
            item.newValue = obj[item.name]
        else
          item.newValue = ''

        if attribute.relation
          item.rejectNonExistentValues = true

        ui.params ||= {}
        newElement = ui.formGenItem(item, classname, form)

        # copy existing events to new rendered element
        form.find('[name="' + field + '"]').closest('.form-group').find("[name!=''][name]").each(->
          target_name = $(@).attr('name')
          $.each($._data(@, 'events'), (eventType, eventArray) ->
            $.each(eventArray, (index, event) ->
              eventToBind = event.type
              if event.namespace.length > 0
                eventToBind = event.type + '.' + event.namespace
              target = newElement.find("[name='" + target_name + "']")
              if target.length > 0
                target.on(eventToBind, event.data, event.handler)
            )
          )
        )

        form.find('[name="' + field + '"]').closest('.form-group').replaceWith(newElement)
        form.find('[name="' + field + '"]').closest('.form-group').find('.js-helpMessage').tooltip()

        if shown
          ui.show(field, form)
        else
          ui.hide(field, form)
        if mandatory
          ui.mandantory(field, form)
        else
          ui.optional(field, form)

        if data.select[item.name] isnt undefined
          form.find('[name="' + field + '"]').trigger('change', skip_core_worfklow: true)

  # fill in data in input fields
  @fillIn: (classname, form, ui, attributes, params, data) ->
    return if _.isEmpty(data)

    for field, values of data
      fieldElement = form.find('[name="' + field + '"], div[data-name="' + field + '"]')
      if fieldElement.hasClass('richtext-content')
        fieldElement.html(data[field])
      else if fieldElement.data('handleValue')
        fieldElement.data('handleValue')(data[field])
      else
        fieldElement.val(data[field])

      coreWorkflowParams[classname][field] = data[field]
      fieldElement.trigger('change', skip_core_worfklow: true)

  # changes the visibility of form elements
  @changeVisibility: (form, ui, data) ->
    return if _.isEmpty(data)

    for field, state of data
      if state is 'show'
        ui.show(field, form)
      else if state is 'hide'
        ui.hide(field, form)
      else if state is 'remove'
        ui.hide(field, form, true)

  # changes the mandatory flag of form elements
  @changeMandatory: (form, ui, visibility, mandatory) ->
    return if _.isEmpty(visibility)

    for field, state of visibility
      if state && !_.contains(['hide', 'remove'], mandatory[field])
        ui.mandantory(field, form)
      else
        ui.optional(field, form)

  # changes the mandatory flag of form elements
  @changeReadonly: (form, ui, data) ->
    return if _.isEmpty(data)

    for field, state of data
      if state
        ui.readonly(field, form)
      else
        ui.changeable(field, form)

  # changes flags
  @changeFlags: (form, ui, data) ->
    return if _.isEmpty(data)

    for key, value of data
      ui.setFlag(key, value)

  # executes individual js commands of the Core Workflow engine
  @executeEval: (form, ui, data) ->
    return if _.isEmpty(data)

    for statement in data
      eval(statement)

  # runs callbacks which are defined for the controller form
  @runCallbacks: (ui) ->
    callbacks = ui?.core_workflow?.callbacks || []
    for callback in callbacks
      callback()

  # runs a complete workflow based on a request result and the form params of the form handler
  @runWorkflow: (data, classname, form, ui, attributes, params) ->
    console.time("runWorkflow/#{classname}/#{ui.model.className}/#{ui.screen}") if @DEBUG
    App.Collection.loadAssets(data.assets)
    App.FormHandlerCoreWorkflow.restrictValues(classname, form, ui, attributes, params, data)
    App.FormHandlerCoreWorkflow.fillIn(classname, form, ui, attributes, params, data.fill_in)
    App.FormHandlerCoreWorkflow.changeVisibility(form, ui, data.visibility)
    App.FormHandlerCoreWorkflow.changeMandatory(form, ui, data.mandatory, data.visibility)
    App.FormHandlerCoreWorkflow.changeReadonly(form, ui, data.readonly)
    App.FormHandlerCoreWorkflow.changeFlags(form, ui, data.flags)
    App.FormHandlerCoreWorkflow.executeEval(form, ui, data.eval)
    App.FormHandlerCoreWorkflow.runCallbacks(ui)
    console.timeEnd("runWorkflow/#{classname}/#{ui.model.className}/#{ui.screen}") if @DEBUG

  # loads the request data and prepares the run of the workflow data
  @runRequest: (data) ->
    return if !coreWorkflowRequests[data.request_id]

    triggerSubmit = coreWorkflowRequests[data.request_id].triggerSubmit
    classname     = coreWorkflowRequests[data.request_id].classname
    form          = coreWorkflowRequests[data.request_id].form
    ui            = coreWorkflowRequests[data.request_id].ui
    attributes    = coreWorkflowRequests[data.request_id].attributes
    params        = coreWorkflowRequests[data.request_id].params

    App.FormHandlerCoreWorkflow.runWorkflow(data, classname, form, ui, attributes, params)

    delete coreWorkflowRequests[data.request_id]

    if triggerSubmit
      App.FormHandlerCoreWorkflow.triggerSubmit(triggerSubmit)

  # this will set the hook for the websocket if activated
  @setHook: =>
    return if @hooked
    return if !App.FormHandlerCoreWorkflow.useWebSockets()
    @hooked = true
    App.Event.bind(
      'core_workflow'
      (data) =>
        @runRequest(data)
      'ws:core_workflow'
    )

  # this will return the needed form element
  @getForm: (form) ->
    return form.closest('form') if form.get(0).tagName != 'FORM'
    return $(form)

  # cleanup of some bad params
  @cleanParams: (params_ref) ->
    params = $.extend(true, {}, params_ref)
    delete params.customer_id_completion
    delete params.body
    delete params.formSenderType
    return params

  # this will use the form handler information to send the data to the backend via ajax/websockets
  @request: (classname, form, ui, attributes, params) ->
    requestID = "CoreWorkflow-#{Math.floor( Math.random() * 999999 ).toString()}"

    for key, value of coreWorkflowRequests
      continue if ui.idPrefix isnt value.ui.idPrefix
      delete coreWorkflowRequests[key]

    coreWorkflowRequests[requestID] = { classname: classname, form: form, ui: ui, attributes: attributes, params: params }

    requestData = {
      event: 'core_workflow',
      request_id: requestID,
      params: params,
      class_name: ui.model.className,
      screen: ui.screen
    }

    # send last changed attribute only once for has changed condition
    if ui.lastChangedAttribute
      requestData.last_changed_attribute = ui.lastChangedAttribute
      ui.lastChangedAttribute            = '-'

    if App.FormHandlerCoreWorkflow.useWebSockets()
      App.WebSocket.send(requestData)
    else
      ui.ajax(
        id:          "core_workflow-#{requestData.request_id}"
        type:        'POST'
        url:         "#{ui.apiPath}/core_workflows/perform"
        data:        JSON.stringify(requestData)
        success:     (data, status, xhr) =>
          @runRequest(data)
        error: (data) ->
          delete coreWorkflowRequests[requestID]
          return
      )

  @article: (ui, dispatchID) ->
    return articleParamsCache[dispatchID] if articleParamsCache[dispatchID]

    article = ui.articleParamsCallback()
    if article?.body
      article.body = App.Utils.html2text(article.body)

    articleParamsCache[dispatchID] = article

  @run: (params_ref, attribute, attributes, classname, form, ui, dispatchID = 'default') ->

    # skip on blacklisted tags
    return if _.contains(['ticket_selector', 'core_workflow_condition', 'core_workflow_perform'], attribute.tag)

    # check if Core Workflow screen
    return if !App.FormHandlerCoreWorkflow.screenValid(ui)

    # get params and add id from ui if needed
    params = App.FormHandlerCoreWorkflow.cleanParams(params_ref)
    if ui.articleParamsCallback
      params.article = App.FormHandlerCoreWorkflow.article(ui, dispatchID)

    # add object id for edit screens
    if ui?.params?.id && ui.screen.match(/edit/)
      params.id = ui.params.id
    else
      delete params.id

    # skip double checks
    return if _.isEqual(coreWorkflowParams[classname], params)
    coreWorkflowParams[classname] = params

    # render intial state provided by screen options if given
    # for more performance and less requests
    if ui.formMeta && ui.formMeta.core_workflow && !ui.lastChangedAttribute
      App.FormHandlerCoreWorkflow.runWorkflow(ui.formMeta.core_workflow, classname, form, ui, attributes, params)
      return

    App.FormHandlerCoreWorkflow.setHook()
    App.FormHandlerCoreWorkflow.request(classname, form, ui, attributes, params)
