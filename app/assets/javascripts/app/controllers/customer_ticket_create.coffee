class CustomerTicketCreate extends App.ControllerAppContent
  requiredPermission: 'ticket.customer'
  events:
    'submit form':         'submit',
    'click .submit':       'submit',
    'click .cancel':       'cancel',

  constructor: (params) ->
    super

    # set title
    @title 'New Ticket'
    @form_id = App.ControllerForm.formId()

    @navupdate '#customer_ticket_new'

    load = (data) =>
      App.Collection.loadAssets(data.assets)
      @formMeta = data.form_meta
      @render()
    @bindId = App.TicketCreateCollection.one(load)

  render: (template = {}) ->
    if !@Config.get('customer_ticket_create')
      @renderScreenError(
        detail:     'Your role cannot create new ticket. Please contact your administrator.'
        objectName: 'Ticket'
      )
      return

    # set defaults
    defaults = template['options'] || {}
    handlers = @Config.get('TicketCreateFormHandler')

    groupFilter = App.Config.get('customer_ticket_create_group_ids')
    if groupFilter
      if !_.isArray(groupFilter)
        groupFilter = [groupFilter]
      @formMeta.filter.group_id = groupFilter

    @html App.view('customer_ticket_create')(
      head: 'New Ticket'
      form_id: @form_id
    )

    new App.ControllerForm(
      el:             @el.find('.ticket-form-top')
      form_id:        @form_id
      model:          App.Ticket
      screen:         'create_top'
      handlersConfig: handlers
      filter:         @formMeta.filter
      formMeta:       @formMeta
      autofocus:      true
      params:         defaults
    )

    new App.ControllerForm(
      el:             @el.find('.article-form-top')
      form_id:        @form_id
      model:          App.TicketArticle
      screen:         'create_top'
      events:
        'fileUploadStart .richtext': => @submitDisable()
        'fileUploadStop .richtext': => @submitEnable()
      filter:         @formMeta.filter
      formMeta:       @formMeta
      params:         defaults
      handlersConfig: handlers
    )
    new App.ControllerForm(
      el:                      @el.find('.ticket-form-middle')
      form_id:                 @form_id
      model:                   App.Ticket
      screen:                  'create_middle'
      filter:                  @formMeta.filter
      formMeta:                @formMeta
      params:                  defaults
      noFieldset:              true
      handlersConfig:          handlers
      rejectNonExistentValues: true
    )
    if !_.isEmpty(App.Ticket.attributesGet('create_bottom', false, true))
      new App.ControllerForm(
        el:             @el.find('.ticket-form-bottom')
        form_id:        @form_id
        model:          App.Ticket
        screen:         'create_bottom'
        handlersConfig: handlers
        filter:         @formMeta.filter
        formMeta:       @formMeta
        params:         defaults
      )

    new App.ControllerDrox(
      el:   @el.find('.sidebar')
      data:
        header: App.i18n.translateInline('What can you do here?')
        html:   App.i18n.translateInline('The way to communicate with us is this thing called "ticket".') + ' ' + App.i18n.translateInline('Here you can create one.')
    )

  cancel: ->
    @navigate '#'

  submit: (e) ->
    e.preventDefault()

    # get params
    params = @formParam(e.target)

    # set customer id
    params.customer_id = @Session.get('id')

    # set prio
    if !params.priority_id
      priority = App.TicketPriority.findByAttribute( 'default_create', true )
      params.priority_id = priority.id

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

    # find sender_id
    sender = App.TicketArticleSender.findByAttribute( 'name', 'Customer' )
    type   = App.TicketArticleType.findByAttribute( 'name', 'web' )
    if params.group_id
      group = App.Group.find( params.group_id )

    # create article
    params['article'] = {
      from:         "#{ @Session.get().displayName() }"
      to:           (group && group.name) || ''
      subject:      params.subject
      body:         params.body
      type_id:      type.id
      sender_id:    sender.id
      form_id:      @form_id
      content_type: 'text/html'
    }

    ticket.load(params)

    # validate form
    ticketErrorsTop = ticket.validate(
      screen: 'create_top'
    )
    ticketErrorsMiddle = ticket.validate(
      screen: 'create_middle'
    )
    article = new App.TicketArticle
    article.load(params['article'])
    articleErrors = article.validate(
      screen: 'create_top'
    )

    # collect whole validation
    errors = {}
    errors = _.extend( errors, ticketErrorsTop )
    errors = _.extend( errors, ticketErrorsMiddle )
    errors = _.extend( errors, articleErrors )

    # show errors in form
    if !_.isEmpty(errors)
      @log 'CustomerTicketCreate', 'error', 'can not create', errors

      @formValidate(
        form:   e.target
        errors: errors
      )

    # save ticket, create article
    else

      # disable form
      @submitDisable(e)
      ui = @
      ticket.save(
        done: ->

          # redirect to zoom
          ui.navigate '#ticket/zoom/' + @id

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

App.Config.set('customer_ticket_new', CustomerTicketCreate, 'Routes')
App.Config.set('CustomerTicketNew', {
  prio: 8003,
  parent: '#new',
  name: 'New Ticket',
  translate: true,
  target: '#customer_ticket_new',
  permission: (navigation) ->
    return false if navigation.permissionCheck('ticket.agent')
    return navigation.permissionCheck('ticket.customer')
  setting: ['customer_ticket_create'],
  divider: true
}, 'NavBarRight')
