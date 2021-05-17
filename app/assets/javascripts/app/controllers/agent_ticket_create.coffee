class App.TicketCreate extends App.Controller
  @include App.SecurityOptions

  elements:
    '.tabsSidebar': 'sidebar'
    '.tabsSidebar-sidebarSpacer': 'sidebarSpacer'

  events:
    'click .type-tabs .tab':   'changeFormType'
    'submit form':             'submit'
    'click .js-cancel':        'cancel'
    'click .js-active-toggle': 'toggleButton'

  types: {
    'phone-in': {
      icon: 'received-calls',
      label: 'Received Call'
    },
    'phone-out': {
      icon: 'outbound-calls',
      label: 'Outbound Call'
    },
    'email-out': {
      icon: 'email',
      label: 'Send Email'
    }
  }

  constructor: (params) ->
    super
    @sidebarState = {}

    # define default type and available types
    @defaultType = @Config.get('ui_ticket_create_default_type')
    @availableTypes = @Config.get('ui_ticket_create_available_types') || []
    if !_.isArray(@availableTypes)
      @availableTypes = [@availableTypes]

    if !_.contains(@availableTypes, @defaultType)
      @defaultType = @availableTypes[0]

    @formId = App.ControllerForm.formId()

    @queueKey = "TicketCreate#{@taskKey}"

    # remember split info if exists
    @split = ''
    if @ticket_id && @article_id
      @split = "/#{@ticket_id}/#{@article_id}"

    load = (data) =>
      App.Collection.loadAssets(data.assets)
      @formMeta = data.form_meta
      @buildScreen(params)
    @bindId = App.TicketCreateCollection.one(load)

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

  release: =>
    App.TicketCreateCollection.unbindById(@bindId)

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
    articleSenderTypeMap =
      'phone-in':
        sender:  'Customer'
        article: 'phone'
        title:   'Call Inbound'
        screen:  'create_phone_in'
      'phone-out':
        sender:  'Agent'
        article: 'phone'
        title:   'Call Outbound'
        screen:  'create_phone_out'
      'email-out':
        sender:  'Agent'
        article: 'email'
        title:   'Email'
        screen:  'create_email_out'
    @articleAttributes = articleSenderTypeMap[type]

    # update form
    @$('[name="formSenderType"]').val(type)

    # force changing signature
    @$('[name="group_id"]').trigger('change')

    # add observer to change options
    @$('[name="cc"], [name="group_id"], [name="customer_id"]').bind('change', =>
      @updateSecurityOptions()
    )
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
    @controllerBind('ticket_create_rerender', (template) => @renderQueue(template))

    # initially hide sidebar on mobile
    if window.matchMedia('(max-width: 767px)').matches
      @sidebar.addClass('is-closed')
      @sidebarSpacer.addClass('is-closed')

  hide: =>
    @autosaveStop()
    @controllerUnbind('ticket_create_rerender', (template) => @renderQueue(template))

  changed: =>
    formCurrent = @formParam( @$('.ticket-create') )
    diff = difference(@formDefault, formCurrent)
    return false if !diff || _.isEmpty(diff)
    return true

  updateSecurityOptions: =>
    params = @params()
    if params.customer_id_completion
      params.to = params.customer_id_completion

    @updateSecurityOptionsRemote(@taskKey, params, params, @paramsSecurity())

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

        # check it task title in task need to be updated
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
      if !_.isEmpty(params.customer_id)
        @renderQueue(options: params)
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
    return if !@formMeta
    App.QueueManager.run(@queueKey)

  render: (template = {}) ->
    return if !@formMeta
    # get params
    params = @prefilledParams || {}
    if template && !_.isEmpty(template.options)
      params = template.options
    else if App.TaskManager.get(@taskKey) && !_.isEmpty(App.TaskManager.get(@taskKey).state)
      params = App.TaskManager.get(@taskKey).state
      params.attachments = App.TaskManager.get(@taskKey).attachments

      if !_.isEmpty(params['form_id'])
        @formId = params['form_id']

    @html(App.view('agent_ticket_create')(
      head:           'New Ticket'
      agent:          @permissionCheck('ticket.agent')
      admin:          @permissionCheck('admin')
      types:          @types,
      availableTypes: @availableTypes
      form_id:        @formId
    ))

    App.Ticket.configure_attributes.push {
      name: 'cc'
      display: 'Cc'
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

    new App.ControllerForm(
      el:             @$('.ticket-form-top')
      form_id:        @formId
      model:          App.Ticket
      screen:         'create_top'
      events:
        'change [name=customer_id]': @localUserInfo
      handlersConfig: handlers
      filter:         @formMeta.filter
      formMeta:       @formMeta
      autofocus:      true
      params:         params
      taskKey:        @taskKey
    )

    new App.ControllerForm(
      el:      @$('.article-form-top')
      form_id: @formId
      model:   App.TicketArticle
      screen:  'create_top'
      events:
        'fileUploadStart .richtext': => @submitDisable()
        'fileUploadStop .richtext': => @submitEnable()
      params:  params
      taskKey: @taskKey
    )
    new App.ControllerForm(
      el:             @$('.ticket-form-middle')
      form_id:        @formId
      model:          App.Ticket
      screen:         'create_middle'
      events:
        'change [name=customer_id]': @localUserInfo
      handlersConfig: handlers
      filter:                  @formMeta.filter
      formMeta:                @formMeta
      params:                  params
      noFieldset:              true
      taskKey:                 @taskKey
      rejectNonExistentValues: true
    )
    new App.ControllerForm(
      el:             @$('.ticket-form-bottom')
      form_id:        @formId
      model:          App.Ticket
      screen:         'create_bottom'
      events:
        'change [name=customer_id]': @localUserInfo
      handlersConfig: handlers
      filter:         @formMeta.filter
      formMeta:       @formMeta
      params:         params
      taskKey:        @taskKey
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

    if @formDefault.customer_id
      callback = (customer) =>
        @localUserInfoCallback(@formDefault, customer)
      App.User.full(@formDefault.customer_id, callback)

    # update taskbar with new meta data
    App.TaskManager.touch(@taskKey)

    @tokanice()

  toggleButton: (event) ->
    @$(event.currentTarget).toggleClass('btn--active')

  tokanice: ->
    App.Utils.tokanice('.content.active input[name=cc]', 'email')

  localUserInfo: (e) =>
    return if !@sidebarWidget
    params = App.ControllerForm.params($(e.target).closest('form'))

    if params.customer_id
      callback = (customer) =>
        @localUserInfoCallback(params, customer)
      App.User.full(params.customer_id, callback)
      return
    @localUserInfoCallback(params)

  localUserInfoCallback: (params, customer = {}) =>
    @sidebarWidget.render(params)
    @textModule.reload(
      config: App.Config.all()
      user: App.Session.get()
      ticket:
        customer: customer
    )

  cancel: (e) ->
    e.preventDefault()

    worker = App.TaskManager.worker(@taskKey)
    App.Event.trigger('taskClose', [worker.taskKey])

  params: =>
    params = @formParam(@$('.main form'))

  submit: (e) =>
    e.preventDefault()

    # get params
    params = @params()

    # fillup params
    if !params.title
      params.title = params.subject

    # create ticket
    ticket = new App.Ticket

    # find sender_id
    sender = App.TicketArticleSender.findByAttribute('name', @articleAttributes['sender'])
    type   = App.TicketArticleType.findByAttribute('name', @articleAttributes['article'])

    if params.group_id
      group  = App.Group.find(params.group_id)

    # add linked objects if ticket got splited
    if @ticket_id
      params['links'] =
        Ticket:
          child: [@ticket_id]

    # allow cc only on email tickets
    if @currentChannel() isnt 'email-out'
      delete params.cc

    # create article
    if sender.name is 'Customer'
      params.article = {
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
      params.article = {
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
        params.article.preferences ||= {}
        params.article.preferences.security = @paramsSecurity()

    ticket.load(params)

    ticketErrorsTop = ticket.validate(
      screen: 'create_top'
    )
    ticketErrorsMiddle = ticket.validate(
      screen: 'create_middle'
    )
    ticketErrorsBottom = ticket.validate(
      screen: 'create_bottom'
    )

    article = new App.TicketArticle
    article.load(params['article'])
    articleErrors = article.validate(
      screen: 'create_top'
    )

    # collect whole validation result
    errors = {}
    errors = _.extend(errors, ticketErrorsTop)
    errors = _.extend(errors, ticketErrorsMiddle)
    errors = _.extend(errors, ticketErrorsBottom)
    errors = _.extend(errors, articleErrors)

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
      if @$('.richtext .attachments .attachment').length < 1
        matchingWord = App.Utils.checkAttachmentReference(article['body'])
        if matchingWord
          if !confirm(App.i18n.translateContent('You use %s in text but no attachment is attached. Do you want to continue?', matchingWord))
            return

    # add sidebar params
    if @sidebarWidget && @sidebarWidget.postParams
      @sidebarWidget.postParams(ticket: ticket)

    # disable form
    @submitDisable(e)
    ui = @
    ticket.save(
      done: ->

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
          msg:     App.i18n.translateContent(details.error_human || details.error || 'Unable to create object!')
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
  requiredPermission: 'ticket.agent'
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
App.Config.set('TicketCreate', { prio: 8003, parent: '#new', name: 'New Ticket', translate: true, target: '#ticket/create', permission: ['ticket.agent'], divider: true }, 'NavBarRight')
