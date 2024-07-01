class CustomerTicketCreate extends App.ControllerAppContent
  @requiredPermission: 'ticket.customer'

  elements:
    '.tabsSidebar': 'sidebar'
    '.tabsSidebar-sidebarSpacer': 'sidebarSpacer'

  events:
    'submit form':         'submit',
    'click .submit':       'submit',
    'click .cancel':       'cancel',

  constructor: (params) ->
    super

    @authenticateCheckRedirect()

    @sidebarState = {}

    # set title
    @title __('New Ticket')
    @form_id = App.ControllerForm.formId()

    @navupdate '#customer_ticket_new'

    @ajax(
      type: 'GET'
      url:  "#{@apiPath}/ticket_create"
      processData: true
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        @formMeta = data.form_meta
        @render()
    )

  show: =>

    # initially hide sidebar on mobile
    if window.matchMedia('(max-width: 767px)').matches
      @sidebar.addClass('is-closed')
      @sidebarSpacer.addClass('is-closed')

  render: (template = {}) ->
    if !@Config.get('customer_ticket_create')
      @renderScreenError(
        detail:     __('Your user role is not allowed to create new tickets. Please contact your administrator.')
        objectName: 'Ticket'
      )
      return

    # set defaults
    defaults = template['options'] || {}
    handlers = @Config.get('TicketCreateFormHandler')

    @html App.view('customer_ticket_create')(
      head: __('New Ticket')
      form_id: @form_id
    )

    pre_top     = { ticket_duplicate_detection: { name: 'ticket_duplicate_detection', display: 'ticket_duplicate_detection', tag: 'ticket_duplicate_detection', label_class: 'hidden', renderTarget: '.ticket-form-top', null: true } }
    top         = App.Ticket.attributesGet('create_top', attributes = false, noDefaultAttributes = true, className = undefined, renderTarget = '.ticket-form-top')
    article_top = App.TicketArticle.attributesGet('create_top', attributes = false, noDefaultAttributes = true, className = undefined, renderTarget = '.article-form-top')
    middle      = App.Ticket.attributesGet('create_middle', attributes = false, noDefaultAttributes = true, className = undefined, renderTarget = '.ticket-form-middle')
    bottom      = App.Ticket.attributesGet('create_bottom', attributes = false, noDefaultAttributes = true, className = undefined, renderTarget = '.ticket-form-bottom')

    @controllerFormCreateMiddle = new App.ControllerForm(
      el:                      @el.find('.ticket-create')
      form_id:                 @form_id
      model:                   App.Ticket
      screen:                  'create_middle'
      mixedAttributes:         Object.assign({}, pre_top, top, article_top, middle, bottom)
      formMeta:                @formMeta
      params:                  defaults
      noFieldset:              true
      handlersConfig:          handlers
      rejectNonExistentValues: true
      autofocus:      true
      events:
        'fileUploadStart .richtext': => @submitDisable()
        'fileUploadStop .richtext': => @submitEnable()
      articleParamsCallback: @articleParams
    )

    @$('[name="group_id"], [name="organization_id"]').bind('change', =>
      @sidebarWidget.render(@params())
    )

    @sidebarWidget = new App.TicketCreateSidebar(
      el:           @sidebar
      params:       defaults
      sidebarState: @sidebarState
    )

  cancel: ->
    @navigate '#'

  params: =>
    params = @formParam(@$('.main form'))

  articleParams: =>
    params = @params()
    if params.group_id
      group = App.Group.find( params.group_id )

    # find sender_id
    sender = App.TicketArticleSender.findByAttribute( 'name', 'Customer' )
    type   = App.TicketArticleType.findByAttribute( 'name', 'web' )

    {
      from:         "#{ @Session.get().displayName() }"
      to:           (group && group.name) || ''
      subject:      params.subject
      body:         params.body
      type_id:      type.id
      sender_id:    sender.id
      form_id:      @form_id
      content_type: 'text/html'
    }

  submit: (e) ->
    e.preventDefault()

    # get params
    params = @formParam(e.target)

    # set customer id
    params.customer_id = @Session.get('id')

    # set state
    if !params.state_id
      state = App.TicketState.findByAttribute( 'default_create', true )
      params.state_id = state.id

    # fillup params
    if !params.title
      params.title = params.subject

    # create ticket
    ticket = new App.Ticket
    @log 'CustomerTicketCreate', 'notice', 'updateAttributes', params

    # create article
    params['article'] = @articleParams()

    ticket.load(params)

    article = new App.TicketArticle
    article.load(params['article'])

    errors = ticket.validate(
      controllerForm: @controllerFormCreateMiddle
      target: e.target
    )

    # show errors in form
    if !_.isEmpty(errors)
      @log 'CustomerTicketCreate', 'error', 'can not create', errors

      @formValidate(
        form:   e.target
        errors: errors
      )

    # save ticket, create article
    else

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

          # add sidebar params
          if ui.sidebarWidget
            ui.sidebarWidget.commit(ticket_id: @id)

          # redirect to zoom
          ui.navigate '#ticket/zoom/' + @id

        fail: (settings, details) ->
          ui.log 'errors', details
          ui.submitEnable(e)
          ui.notify(
            type:    'error'
            msg:     App.i18n.translateContent(details.error_human || details.error || __('The object could not be created.'))
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

App.Config.set('customer_ticket_new', CustomerTicketCreate, 'Routes')
App.Config.set('CustomerTicketNew', {
  prio: 8003,
  parent: '#new',
  name: __('New Ticket'),
  translate: true,
  target: '#customer_ticket_new',
  permission: (navigation) ->
    return false if navigation.permissionCheck('ticket.agent')
    return navigation.permissionCheck('ticket.customer')
  setting: ['customer_ticket_create'],
  divider: true
}, 'NavBarRight')
