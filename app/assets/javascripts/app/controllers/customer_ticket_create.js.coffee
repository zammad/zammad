class Index extends App.ControllerContent
  events:
    'submit form':         'submit',
    'click .submit':       'submit',
    'click .cancel':       'cancel',

  constructor: (params) ->
    super

    # check authentication
    return if !@authenticate()

    # set title
    @title 'New Ticket'
    @form_id = App.ControllerForm.formId()
    @fetch(params)
    @navupdate '#customer_ticket_new'

  # get data / in case also ticket data for split
  fetch: (params) ->

    # use cache
    cache = App.Store.get( 'ticket_create_attributes' )

    if cache

      # load assets
      App.Collection.loadAssets( cache.assets )

      @render()
    else
      @ajax(
        id:    'ticket_create',
        type:  'GET',
        url:   @apiPath + '/ticket_create',
        processData: true,
        success: (data, status, xhr) =>

          # cache request
          App.Store.write( 'ticket_create_attributes', data )

          # load assets
          App.Collection.loadAssets( data.assets )

          @render()
      )

  render: (template = {}) ->

    # set defaults
    defaults = template['options'] || {}

    filter = {}
    groupFilter = App.Config.get('customer_ticket_create_group_ids')
    if groupFilter
      if !_.isArray(groupFilter)
        groupFilter = [groupFilter]
      filter.group_id = groupFilter

    @html App.view('customer_ticket_create')( head: 'New Ticket' )

    new App.ControllerForm(
      el:       @el.find('.ticket-form')
      form_id:  @form_id
      model:    App.Ticket
      screen:   'create_web'
      autofocus: true
      filter:   filter
      params:    defaults
    )

    new App.ControllerForm(
      el:       @el.find('.article-form')
      form_id:  @form_id
      model:    App.TicketArticle
      screen:   'create_web'
      params:   defaults
    )

    new App.ControllerDrox(
      el:   @el.find('.sidebar')
      data:
        header: App.i18n.translateInline('What can you do here?')
        html:   App.i18n.translateInline('The way to communicate with us is this thing called "Ticket".') + ' ' + App.i18n.translateInline('Here you can create one.')
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
      priority = App.TicketPriority.findByAttribute( 'name', '2 normal' )
      params.priority_id = priority.id

    # set state
    if !params.state_id
      state = App.TicketState.findByAttribute( 'name', 'new' )
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
      from:       "#{ @Session.get('firstname') } #{ @Session.get('lastname') }"
      to:         (group && group.name) || ''
      subject:    params.subject
      body:       params.body
      type_id:    type.id
      sender_id:  sender.id
      form_id:    @form_id
    }

    ticket.load(params)

    # validate form
    ticketErrors = ticket.validate(
      screen: 'create_web'
    )
    article = new App.TicketArticle
    article.load(params['article'])
    articleErrors = article.validate(
      screen: 'create_web'
    )
    for key, value of articleErrors
      if !ticketErrors
        ticketErrors = {}
      ticketErrors[key] = value

    # show errors in form
    if ticketErrors
      @log 'CustomerTicketCreate', 'error', 'can not create', ticketErrors

      @formValidate( form: e.target, errors: ticketErrors )

    # save ticket, create article
    else

      # disable form
      @formDisable(e)
      ui = @
      ticket.save(
        done: ->

          # redirect to zoom
          ui.navigate '#ticket/zoom/' + this.id

        fail: ->
          ui.log 'CustomerTicketCreate', 'error', 'can not create'
          ui.formEnable(e)
      )

App.Config.set( 'customer_ticket_new', Index, 'Routes' )
App.Config.set( 'CustomerTicketNew', { prio: 8000, parent: '', name: 'New', target: '#customer_ticket_new', role: ['Customer'] }, 'NavBarRight' )
