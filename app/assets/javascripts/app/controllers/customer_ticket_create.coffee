class CustomerTicketCreate extends App.ControllerAppContent
  requiredPermission: 'ticket.customer'
  events:
    'submit form':         'submit',
    'click .submit':       'submit',
    'click .cancel':       'cancel',

  constructor: (params) ->
    super

    # set title
    @title __('New Ticket')
    @form_id = App.ControllerForm.formId()

    @navupdate '#customer_ticket_new'
    @render()

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

    @controllerFormCreateMiddle = new App.ControllerForm(
      el:                      @el.find('.ticket-form-middle')
      form_id:                 @form_id
      model:                   App.Ticket
      screen:                  'create_middle'
      params:                  defaults
      noFieldset:              true
      handlersConfig:          handlers
      rejectNonExistentValues: true
    )

    # tunnel events to make sure core workflow does know
    # about every change of all attributes (like subject)
    tunnelController = @controllerFormCreateMiddle
    class TicketCreateFormHandlerControllerFormCreateMiddle
      @run: (params, attribute, attributes, classname, form, ui) ->
        return if !ui.lastChangedAttribute
        tunnelController.lastChangedAttribute = ui.lastChangedAttribute
        params = App.ControllerForm.params(tunnelController.form)
        App.FormHandlerCoreWorkflow.run(params, tunnelController.attributes[0], tunnelController.attributes, tunnelController.idPrefix, tunnelController.form, tunnelController)

    handlersTunnel = _.clone(handlers)
    handlersTunnel['000-TicketCreateFormHandlerControllerFormCreateMiddle'] = TicketCreateFormHandlerControllerFormCreateMiddle

    @controllerFormCreateTop = new App.ControllerForm(
      el:             @el.find('.ticket-form-top')
      form_id:        @form_id
      model:          App.Ticket
      screen:         'create_top'
      handlersConfig: handlersTunnel
      autofocus:      true
      params:         defaults
    )
    @controllerFormCreateTopArticle = new App.ControllerForm(
      el:             @el.find('.article-form-top')
      form_id:        @form_id
      model:          App.TicketArticle
      screen:         'create_top'
      events:
        'fileUploadStart .richtext': => @submitDisable()
        'fileUploadStop .richtext': => @submitEnable()
      params:         defaults
      handlersConfig: handlersTunnel
    )
    if !_.isEmpty(App.Ticket.attributesGet('create_bottom', false, true))
      @controllerFormCreateBottom = new App.ControllerForm(
        el:             @el.find('.ticket-form-bottom')
        form_id:        @form_id
        model:          App.Ticket
        screen:         'create_bottom'
        handlersConfig: handlersTunnel
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
      controllerForm: @controllerFormCreateTop
      target: e.target
    )
    ticketErrorsMiddle = ticket.validate(
      controllerForm: @controllerFormCreateMiddle
      target: e.target
    )
    article = new App.TicketArticle
    article.load(params['article'])
    articleErrors = article.validate(
      controllerForm: @controllerFormCreateTop
      target: e.target
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
