class App.TicketCreate extends App.Controller
  @include App.SecurityOptions

  elements:
    '.tabsSidebar':               'sidebar'
    '.tabsSidebar-sidebarSpacer': 'sidebarSpacer'

  events:
    'click .type-tabs .tab':           'changeFormType'
    'submit form':                     'submit'
    'click .form-controls .js-cancel': 'cancel'
    'click .js-active-toggle':         'toggleButton'
    'click .js-active-toggle-type':    'toggleTypeButton'

  types: {
    'phone-in': {
      icon: 'received-calls',
      label: __('Received Call')
    },
    'phone-out': {
      icon: 'outbound-calls',
      label: __('Outbound Call')
    },
    'email-out': {
      icon: 'email',
      label: __('Send Email')
    }
  }

  articleSenderTypeMap: {
    'phone-in':
      sender:  'Customer'
      article: 'phone'
      title:   __('Inbound Call')
      screen:  'create_phone_in'
    'phone-out':
      sender:  'Agent'
      article: 'phone'
      title:   __('Outbound Call')
      screen:  'create_phone_out'
    'email-out':
      sender:  'Agent'
      article: 'email'
      title:   __('Email')
      screen:  'create_email_out'
  }

  constructor: (params) ->
    super
    @sidebarState = {}

    # define default type and available types
    @defaultType     = @Config.get('ui_ticket_create_default_type')
    @availableTypes  = @Config.get('ui_ticket_create_available_types') || []

    if !_.isArray(@availableTypes)
      @availableTypes = [@availableTypes]

    if !_.contains(@availableTypes, @defaultType)
      @defaultType = @availableTypes[0]

    @formId            = App.ControllerForm.formId()
    @queueKey          = "TicketCreate#{@taskKey}"
    @articleAttributes = @articleSenderTypeMap[@currentChannel()]

    # remember split info if exists
    @split = ''
    if @ticket_id && @article_id
      @split = "/#{@ticket_id}/#{@article_id}"

    fetchSuccess = (data) =>
      App.Collection.loadAssets(data.assets)
      @formMeta = data.form_meta
      @buildScreen(params)

    initCreate = App.TaskbarInit.ticket_create()
    if params.init && initCreate
      fetchSuccess(initCreate)
    else
      @ajax(
        type: 'GET'
        url:  "#{@apiPath}/ticket_create"
        processData: true
        success: fetchSuccess
      )

    # rerender view, e. g. on langauge change
    @controllerBind('ui:rerender', =>
      return if !@authenticateCheck()
      @renderQueue()
      @tokanice()
    )

    # listen to rerender sidebars
    @controllerBind('ui::ticket::sidebarRerender', (data) =>
      return if data.taskKey isnt @taskKey
      return if !@sidebarWidget
      @sidebarWidget.render(@params())
    )

    # Listen to security setting changes.
    @controllerBind('config_update', (data) =>
      return if not /^(pgp|smime)_integration$/.test(data.name)

      @updateSecurityType()
      @updateSecurityOptions()
    )

  currentChannel: =>
    if !type
      type = @$('.type-tabs .tab.active').data('type')
    if !type
      type = @defaultType
    type

  changeFormType: (e) =>
    type = $(e.currentTarget).data('type')
    @setFormTypeInUi(type)
    @tokanice()

  setFormTypeInUi: (type) =>

    # detect current form type
    if !type
      type = @currentChannel()

    # reset all tabs
    tabs = @$('.type-tabs .tab')
    tabs.removeClass('active')
    tabIcons = @$('.type-tabs .tab .icon')
    tabIcons.addClass('gray')
    tabIcons.removeClass('white')

    # set active tab
    selectedTab = @$(".type-tabs .tab[data-type='#{type}']")
    selectedTab.addClass('active')

    # set form type attributes
    @articleAttributes = @articleSenderTypeMap[type]

    # update form
    @$('[name="formSenderType"]').val(type)

    # force changing signature
    # skip on initialization because it will trigger core workflow
    @$('[name="group_id"]').trigger('change', non_interactive: true)

    # add observer to change options
    @$('[name="cc"], [name="group_id"], [name="customer_id"]').on('change', =>
      @updateSecurityOptions()
    )

    @controllerBind('Group:create Group:update Group:touch Group:destroy', =>
      @sidebarWidget.render(@params())
    )

    @$('[name="group_id"]').bind('change', =>
      @sidebarWidget.render(@params())
    )

    @updateSecurityType(type)
    @updateSecurityOptions()

    # show cc
    if type is 'email-out'
      @$('[name="cc"]').closest('.form-group').removeClass('hide')

      if @securityEnabled()
        @securityOptionsShow()

    else
      @$('[name="cc"]').closest('.form-group').addClass('hide')

      if @securityEnabled()
        @securityOptionsHide()

    # show notice
    @$('.js-note').addClass('hide')
    @$(".js-note[data-type='#{type}']").removeClass('hide')

    App.TaskManager.touch(@taskKey)

  meta: =>
    text = ''
    if @articleAttributes
      text = App.i18n.translateInline(@articleAttributes['title'])
    title = @$('[name=title]').val()
    if title
      text = "#{text}: #{title}"
    meta =
      url:       @url()
      head:      text
      title:     text
      id:        @id
      iconClass: 'pen'

  url: =>
    "#ticket/create/id/#{@id}"

  show: =>
    @navupdate("#ticket/create/id/#{@id}#{@split}", type: 'menu')
    @autosaveStart()
    @dirtyMonitorStart()
    @controllerBind('ticket_create_rerender', (template) => @renderQueue(template))
    @controllerBind('ticket_create_shared_draft_saved',       @sharedDraftSaved)
    @controllerBind('ticket_create_import_draft_attachments', @importDraftAttachments)

    # initially hide sidebar on mobile
    if window.matchMedia('(max-width: 767px)').matches
      @sidebar.addClass('is-closed')
      @sidebarSpacer.addClass('is-closed')

  hide: =>
    @autosaveStop()
    @dirtyMonitorStop()
    @controllerUnbind('ticket_create_rerender')
    @controllerUnbind('ticket_create_shared_draft_saved')
    @controllerUnbind('ticket_create_import_draft_attachments')

  changed: =>
    return true if @hasAttachments()

    formCurrent = @formParam( @$('.ticket-create') )
    diff = difference(@formDefault, formCurrent)

    return false if !diff || _.isEmpty(diff)
    return true

  updateSecurityOptions: (resetSecurityOptions = false) =>
    params = @params()
    if params.customer_id_completion
      params.to = params.customer_id_completion

    @securityOptionsReset() if resetSecurityOptions
    @updateSecurityOptionsRemote(@taskKey, params, params)

  updateSecurityType: (type = @currentChannel()) =>
    return if type isnt 'email-out'

    @updateSecurityTypeToolbar()

  dirtyMonitorStart: =>
    @dirty = {}

    update = (e, args) =>
      { target } = e

      field = target.getAttribute('name') || target.getAttribute('data-name')

      # Skip tracking of fields without name attribute
      if !field
        @log 'debug', 'ticket create dirty monitor', 'unknown field', target
        return

      # Skip tracking of non-interactive fields
      if (_.isObject(args) && args.non_interactive) || field == 'id'
        @log 'debug', 'ticket create dirty monitor', 'non-interactive change', field
        return

      # Get field specific value
      switch field
        when 'body' then value = target.textContent
        else value = target.value

      # Remember non-empty user input by marking fields as "dirty"
      # https://github.com/zammad/zammad/issues/2434
      if value? && value
        @dirty[field] = true
      else
        delete @dirty[field] if @dirty[field]
      @log 'debug', 'ticket create dirty monitor', field, value, @dirty

    @el.on('change.dirty paste.dirty input.dirty', 'form, .js-textarea', update)

  dirtyMonitorStop: =>
    @el.off('change.dirty paste.dirty input.dirty')

  autosaveStop: =>
    @clearDelay('ticket-create-form-update')
    @el.off('change.local blur.local keyup.local paste.local input.local')

  autosaveStart: =>
    if !@autosaveLast
      task = App.TaskManager.get(@taskKey)
      if task && !task.state
        task.state = {}
      @autosaveLast = task.state || {}
    update = =>
      data = @formParam(@$('.ticket-create'))
      return if _.isEmpty(data)
      diff = difference(@autosaveLast, data)
      if _.isEmpty(@autosaveLast) || !_.isEmpty(diff)
        @autosaveLast = data
        @log 'debug', 'form hash changed', diff, data
        App.TaskManager.update(@taskKey, { 'state': data })

        # check it task title in task needs to be updated
        if @latestTitle isnt data.title
          @latestTitle = data.title
          App.TaskManager.touch(@taskKey)

    @el.on('change.local blur.local keyup.local paste.local input.local', 'form, .js-textarea', (e) =>
      @delay(update, 250, 'ticket-create-form-update')
    )
    @delay(update, 800, 'ticket-create-form-update')

  # get data / in case also ticket data for split
  buildScreen: (params) =>

    if _.isEmpty(params.ticket_id) && _.isEmpty(params.article_id)

      # remove not form relevant options
      localOptions = _.omit(params, 'id', 'query', 'shown', 'taskKey', 'ticket_id', 'article_id', 'appEl', 'el', 'type')
      localOptions = _.omit(localOptions, _.isUndefined)

      if !_.isEmpty(localOptions)
        @renderQueue(options: localOptions)
        return

      @renderQueue()
      return

    # fetch split ticket data
    @ajax(
      id:    "ticket_split#{@taskKey}"
      type:  'GET'
      url:   "#{@apiPath}/ticket_split"
      data:
        ticket_id: params.ticket_id
        article_id: params.article_id
        form_id: @formId
      processData: true
      success: (data, status, xhr) =>

        # load assets
        App.Collection.loadAssets(data.assets)

        # prefill with split ticket
        t = App.Ticket.find(params.ticket_id).attributes()
        a = App.TicketArticle.find(params.article_id)

        # reset owner
        t.owner_id               = 0
        t.customer_id_completion = a.from
        t.subject                = a.subject || t.title

        # convert non text/html from text 2 html
        if a.content_type.match(/\/html/)
          t.body = a.body
        else
          t.body  = App.Utils.text2html(a.body)

        # add attachments
        t.attachments = data.attachments

        # render page
        @renderQueue(options: t)
    )

  renderQueue: (template = {}) =>
    localeRender = =>
      @render(template)
    App.QueueManager.add(@queueKey, localeRender)
    return if !@formMeta && !@controllerFormCreateMiddle
    App.QueueManager.run(@queueKey)

  importDraftAttachments: (options = {}) =>
    @ajax
      id: 'import_attachments'
      type: 'POST'
      url: "#{@apiPath}/tickets/shared_drafts/#{options.shared_draft_id}/import_attachments"
      data: JSON.stringify({ form_id: @formId })
      processData: true
      success: (data, status, xhr) ->
        App.Event.trigger(options.callbackName, { success: true, attachments: data.attachments })
      error: ->
        App.Event.trigger(options.callbackName, { success: false })

  sharedDraftSaved: (options) =>
    @el
      .find('.ticket-create input[name=shared_draft_id]')
      .val(options.shared_draft_id)

  updateTaskManagerAttachments: (attribute, attachments) =>
    taskData = App.TaskManager.get(@taskKey)
    return if _.isEmpty(taskData)

    taskData.attachments = attachments
    App.TaskManager.update(@taskKey, taskData)

  render: (template = {}) =>

    # Get initial params
    params = @prefilledParams || {}

    # Get taskbar params
    if App.TaskManager.get(@taskKey) && !_.isEmpty(App.TaskManager.get(@taskKey).state)
      params = App.TaskManager.get(@taskKey).state
      params.attachments = App.TaskManager.get(@taskKey).attachments

      if !_.isEmpty(params['form_id'])
        @formId = params['form_id']

    # Get template (and shared draft) params
    if template && !_.isEmpty(template.options)
      templateTags = null

      # Merge template values with existing params
      _.extend(params, _.pick(
        _.object(
          _.map(
            _.pairs(template.options),

            # Re-map field names and values to a structure ticket form understands
            ([templateField, templateValue]) ->
              fieldArray = templateField.split('.')
              field = fieldArray[1] || fieldArray[0]

              if _.isObject(templateValue) and templateValue['value'] != undefined
                value = templateValue['value']

                # Move the completion value into its own parameter.
                if templateValue['value_completion']
                  params["#{field}_completion"] = templateValue['value_completion']

                # Calculate the target time value from now, in case of relative datetime fields (#4318).
                if templateValue['operator'] is 'relative' and templateValue['range']
                  isDateTime = _.find(App.Ticket.configure_attributes, (attr) -> attr.name is field)?.tag is 'datetime'
                  value = App.ViewHelpers.relative_time(templateValue['value'], templateValue['range'], isDateTime)

                # Remember complete tags configuration for further processing.
                if field is 'tags'
                  value = templateValue

              else
                value = templateValue

              [field, value]
          )
        ),

        # In case of templates, pick only values for "non-dirty" fields.
        #   In case of shared drafts, pick them all, since they are supposed to overwrite the existing form.
        #   Skip tags in case of templates, as these support complex value format that will get processed later.
        # https://github.com/zammad/zammad/issues/2434
        # https://github.com/zammad/zammad/issues/5244
        (value, field) =>
          return true if template.shared_draft_id

          if field is 'tags'
            templateTags = value
            return

          return if @dirty?[field]

          true
        )
      )

      # Handle template tags only, since shared drafts support only the simple value format.
      if not template.shared_draft_id

        # Process template tags, but only if they are "dirty".
        if @dirty?.tags and params.tags
          switch templateTags?['operator']

            # Remove tags included in the template from the existing tags.
            when 'remove'
              params.tags = _.difference(params.tags.split(', '), templateTags?['value']?.split(', ')).join(', ')

            # Add tags included in the template by merging them with existing tags.
            #   Do this also if the operator is missing from the template configuration (default behavior).
            else
              params.tags = _.uniq(_.union(params.tags.split(', '), templateTags?['value']?.split(', '))).join(', ')

        # Otherwise, simply replace the tags with the value from the template.
        #   Do not do this if they are supposed to be removed only.
        #   This allows switching between different templates without accumulating their tags.
        #   Note that template might not contain tags, in which case the field will be reset.
        else if templateTags?['operator'] != 'remove'
          params.tags = templateTags?['value']

    if !_.isEmpty(params)
      # only use form meta once so it will not get used on templates
      @formMeta = undefined

    params.priority_id ||= App.TicketPriority.findByAttribute( 'default_create', true )?.id

    @html(App.view('agent_ticket_create')(
      head:            __('New Ticket')
      agent:           @permissionCheck('ticket.agent')
      admin:           @permissionCheck('admin')
      types:           @types,
      availableTypes:  @availableTypes
      form_id:         @formId
      shared_draft_id: template.shared_draft_id || params.shared_draft_id
    ))

    App.Ticket.configure_attributes.push {
      name: 'cc'
      display: __('CC')
      tag: 'input'
      type: 'text'
      maxlength: 1000
      null: true
      screen: {
        create_top: {
          Agent: {
            null: true
          }
        }
        create_middle: {}
        edit: {}
      }
    }

    handlers = @Config.get('TicketCreateFormHandler')

    pre_top     = { ticket_duplicate_detection: { name: 'ticket_duplicate_detection', display: 'ticket_duplicate_detection', tag: 'ticket_duplicate_detection', label_class: 'hidden', renderTarget: '.ticket-form-top', null: true } }
    top         = App.Ticket.attributesGet('create_top', attributes = false, noDefaultAttributes = false, className = undefined, renderTarget = '.ticket-form-top')
    article_top = App.TicketArticle.attributesGet('create_top', attributes = false, noDefaultAttributes = false, className = undefined, renderTarget = '.article-form-top')
    middle      = App.Ticket.attributesGet('create_middle', attributes = false, noDefaultAttributes = false, className = undefined, renderTarget = '.ticket-form-middle')
    bottom      = App.Ticket.attributesGet('create_bottom', attributes = false, noDefaultAttributes = false, className = undefined, renderTarget = '.ticket-form-bottom')

    @controllerFormCreateMiddle = new App.ControllerForm(
      el:                       @$('.ticket-create')
      form_id:                  @formId
      model:                    App.Ticket
      screen:                   'create_middle'
      mixedAttributes:          Object.assign({}, pre_top, top, article_top, middle, bottom)
      handlersConfig:           handlers
      formMeta:                 @formMeta
      params:                   params
      noFieldset:               true
      taskKey:                  @taskKey
      rejectNonExistentValues:  true
      autofocus:                true
      events:
        'fileUploadStart .richtext': => @submitDisable()
        'fileUploadStop .richtext': => @submitEnable()
        'change [name=customer_id]': @localUserInfo
        'change [data-attribute-name=organization_id] .js-input': @localUserInfo
      richTextUploadRenderCallback: @updateTaskManagerAttachments
      richTextUploadDeleteCallback: @updateTaskManagerAttachments
      articleParamsCallback: @articleParams
    )

    # convert remote images into data urls
    App.Utils.htmlImage2DataUrlAsyncInline(@$('[contenteditable=true]'))

    App.Ticket.configure_attributes.pop()

    # set type selector
    @setFormTypeInUi(params['formSenderType'])

    # remember form params of init load
    @formDefault = @formParam(@$('.ticket-create'))

    # show text module UI
    @textModule = new App.WidgetTextModule(
      el: @$('[data-name="body"]').parent()
      data:
        config: App.Config.all()
        user: App.Session.get()
        ticket: @formDefault
      taskKey: @taskKey
    )

    $('#tags').tokenfield()

    @sidebarWidget = new App.TicketCreateSidebar(
      el:           @sidebar
      params:       @formDefault
      sidebarState: @sidebarState
      taskKey:      @taskKey
      query:        @query
    )

    if @formDefault.customer_id || @formDefault.organization_id
      @localUserInfo(undefined, @formDefault)

    # update taskbar with new meta data
    App.TaskManager.touch(@taskKey)

    @tokanice()

  toggleButton: (event) ->
    @$(event.currentTarget).toggleClass('btn--active')

  toggleTypeButton: (event) =>
    target = @$(event.currentTarget)

    return if target.hasClass('btn--active')

    target.siblings().removeClass('btn--active')
    @toggleButton(event)
    @updateSecurityOptions(true)

  tokanice: ->
    App.Utils.tokanice('.content.active input[name=cc]', 'email')

  localUserInfo: (e, params = {}) =>
    return if !@sidebarWidget

    # get params by event if given
    params = App.ControllerForm.params($(e.target).closest('form')) if e

    return if @localUserInfoCustomerId is params.customer_id && @localUserInfoOrganizationId is params.organization_id
    @localUserInfoCustomerId     = params.customer_id
    @localUserInfoOrganizationId = params.organization_id

    callbackOrganization = =>
      if params.organization_id
        App.Organization.full(params.organization_id, => @localUserInfoCallback(params))
      else
        @localUserInfoCallback(params)

    callbackUser = ->
      if params.customer_id
        App.User.full(params.customer_id, callbackOrganization)
      else
        callbackOrganization()

    callbackUser()

  localUserInfoCallback: (params) =>

    # update params with new customer selection
    # to replace in text modules properly
    params.customer = App.User.find(params.customer_id) || {}

    # if customer is given in params (e. g. from CTI integration) show selected customer
    # display name with email address (if exists) in customer attribute in UI
    fillCompletionIfRequiredCallback = =>
      return if !_.isEmpty(@el.find('input[name=customer_id_completion]').val())
      return if !params.customer
      return if !params.customer.displayName
      completion = params.customer.displayName()
      if params.customer.email
        completion = App.Utils.buildEmailAddress(params.customer.displayName(), params.customer.email)
      return if !completion
      @el.find('input[name=customer_id_completion]').val(completion)
    @delay(fillCompletionIfRequiredCallback, 10)

    @sidebarWidget.render(params)
    @textModule.reload(
      config: App.Config.all()
      user: App.Session.get()
      ticket: params
    )

  cancel: (e) ->
    e.preventDefault()

    worker = App.TaskManager.worker(@taskKey)
    App.Event.trigger('taskClose', [worker.taskKey])

  params: =>
    params = @formParam(@$('.main form'))

  hasAttachments: =>
    @$('.richtext .attachments .attachment').length > 0

  articleParams: =>
    params = @params()

    # find sender_id
    sender = App.TicketArticleSender.findByAttribute('name', @articleAttributes['sender'])
    type   = App.TicketArticleType.findByAttribute('name', @articleAttributes['article'])

    group = undefined
    if params.group_id
      group  = App.Group.find(params.group_id)

    # create article
    article = {}
    if sender.name is 'Customer'
      article = {
        to:           (group && group.name) || ''
        from:         params.customer_id_completion
        cc:           params.cc
        subject:      params.subject
        body:         params.body
        type_id:      type.id
        sender_id:    sender.id
        form_id:      @formId
        content_type: 'text/html'
      }
    else
      article = {
        from:         (group && group.name) || ''
        to:           params.customer_id_completion
        cc:           params.cc
        subject:      params.subject
        body:         params.body
        type_id:      type.id
        sender_id:    sender.id
        form_id:      @formId
        content_type: 'text/html'
      }

    # add security params
    if @securityOptionsShown()
      article.preferences ||= {}
      article.preferences.security = @paramsSecurity()

    # allow cc only on email tickets
    if @currentChannel() isnt 'email-out'
      delete article.cc

    article

  submit: (e) =>
    e.preventDefault()

    # get params
    params = @params()

    # fillup params
    if !params.title
      params.title = params.subject

    # create ticket
    ticket = new App.Ticket

    # add linked objects if ticket got splited
    if @ticket_id
      params['links'] =
        Ticket:
          child: [@ticket_id]

    # create article
    params.article = @articleParams()

    ticket.load(params)

    article = new App.TicketArticle
    article.load(params['article'])

    errors = ticket.validate(
      controllerForm: @controllerFormCreateMiddle
      target: e.target
    )

    # show errors in form
    if !_.isEmpty(errors)
      @log 'error', errors
      @formValidate(
        form:   e.target
        errors: errors
      )
      return

    # save ticket, create article
    # check attachment
    if article['body']
      if !@hasAttachments()
        matchingWord = App.Utils.checkAttachmentReference(article['body'])
        if matchingWord
          if !confirm(App.i18n.translateContent('You used %s in the text but no attachment could be found. Do you want to continue?', matchingWord))
            return

    # add sidebar params
    if @sidebarWidget && @sidebarWidget.postParams
      @sidebarWidget.postParams(ticket: ticket)

    # disable form
    @submitDisable(e)
    ui = @
    ticket.save(
      done: ->

        # Reset article after ticket create, to avoid unwanted sideeffects at other places.
        localTicket = App.Ticket.findNative(@id)
        localTicket.article = undefined

        # notify UI
        ui.notify
          type:    'success'
          msg:     App.i18n.translateInline('Ticket %s created!', @number)
          link:    "#ticket/zoom/#{@id}"
          timeout: 4000

        # close ticket create task
        App.TaskManager.remove(ui.taskKey)

        # scroll to top
        ui.scrollTo()

        # add sidebar params
        if ui.sidebarWidget
          ui.sidebarWidget.commit(ticket_id: @id)

        # access to group
        if @editable('change')
          ui.navigate "#ticket/zoom/#{@id}"
          return

        # if not, show start screen
        ui.navigate '#'

      fail: (settings, details) ->
        ui.log 'errors', details
        ui.submitEnable(e)
        ui.notify(
          type:    'error'
          msg:     details.error_human || details.error || __('The object could not be created.')
          timeout: 6000
        )
    )

  submitDisable: (e) =>
    if e
      @formDisable(e)
      return
    @formDisable(@$('.js-submit'), 'button')

  submitEnable: (e) =>
    if e
      @formEnable(e)
      return
    @formEnable(@$('.js-submit'), 'button')

class Router extends App.ControllerPermanent
  @requiredPermission: 'ticket.agent'
  constructor: (params) ->
    super

    # create new uniq form id
    if !params['id']
      # remember split info if exists
      split = ''
      if params['ticket_id'] && params['article_id']
        split = "/#{params['ticket_id']}/#{params['article_id']}"

      if params.customer_id
        split = "/customer/#{params.customer_id}"

      if params.query
        split = "/query/#{params.query}"

      id = Math.floor( Math.random() * 99999 )
      @navigate "#ticket/create/id/#{id}#{split}"
      return

    # check authentication
    @authenticateCheckRedirect()

    # cleanup params
    clean_params =
      ticket_id:   params.ticket_id
      article_id:  params.article_id
      type:        params.type
      customer_id: params.customer_id
      query:       params.query
      id:          params.id

    App.TaskManager.execute(
      key:        "TicketCreateScreen-#{params['id']}"
      controller: 'TicketCreate'
      params:     clean_params
      show:       true
    )

# create new ticket routes/controller
App.Config.set('ticket/create', Router, 'Routes')
App.Config.set('ticket/create/', Router, 'Routes')
App.Config.set('ticket/create/id/:id', Router, 'Routes')
App.Config.set('ticket/create/customer/:customer_id', Router, 'Routes')
App.Config.set('ticket/create/id/:id/customer/:customer_id', Router, 'Routes')
App.Config.set('ticket/create/id/:id/query/:query', Router, 'Routes')

# split ticket
App.Config.set('ticket/create/:ticket_id/:article_id', Router, 'Routes')
App.Config.set('ticket/create/id/:id/:ticket_id/:article_id', Router, 'Routes')

# set new actions
App.Config.set('TicketCreate', { prio: 8003, parent: '#new', name: __('New Ticket'), translate: true, target: '#ticket/create', permission: ['ticket.agent'], divider: true }, 'NavBarRight')
