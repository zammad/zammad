class App.TicketCreate extends App.Controller
  events:
    'click .customer_new': 'userNew'
    'submit form':         'submit'
    'click .submit':       'submit'
    'click .cancel':       'cancel'

  constructor: (params) ->
    super

    # check authentication
    return if !@authenticate()

    # set title
    @form_id = App.ControllerForm.formId()

    @form_meta = undefined

    # set article attributes
    default_type = 'call_inbound'
    if !@type
      @type = default_type
    article_sender_type_map =
      call_inbound:
        sender:  'Customer'
        article: 'phone'
        title:   'Call Inbound'
        screen:  'create_phone_in'
      call_outbound:
        sender:  'Agent'
        article: 'phone'
        title:   'Call Outbound'
        screen:  'create_phone_out'
      email:
        sender:  'Agent'
        article: 'email'
        title:   'Email'
        screen:  'create_email_out'
    @article_attributes = article_sender_type_map[@type]

    # remember split info if exists
    split = ''
    if @ticket_id && @article_id
      split = "/#{@ticket_id}/#{@article_id}"

    # if no map entry exists, route to default
    if !@article_attributes
      @navigate '#ticket/create/' + default_type + split
      return

    # update navbar highlighting
    @navupdate '#ticket/create/' + @type + '/id/' + @id + split

    @fetch(params)

    # lisen if view need to be rerendert
    @bind 'ticket_create_rerender', (defaults) =>
      @log 'notice', 'error', defaults
      @render(defaults)

  meta: =>
    text = App.i18n.translateInline( @article_attributes['title'] )
    title = @el.find('[name=title]').val()
    if title
      text = "#{text}: #{title}"
    meta =
      url:   @url()
      head:  text
      title: text
      id:    @type

  url: =>
    '#ticket/create/' + @type + '/id/' + @id

  activate: =>
    @navupdate '#'

  changed: =>
    formCurrent = @formParam( @el.find('.ticket-create') )
    diff = difference( @formDefault, formCurrent )
    return false if !diff || _.isEmpty( diff )
    return true

  release: =>
    # nothing

  autosave: =>
    update = =>
      data = @formParam( @el.find('.ticket-create') )
      diff = difference( @autosaveLast, data )
      if !@autosaveLast || ( diff && !_.isEmpty( diff ) )
        @autosaveLast = data
        @log 'notice', 'form hash changed', diff, data
        App.TaskManager.update( @task_key, { 'state': data })
    @interval( update, 3000, @id )

  # get data / in case also ticket data for split
  fetch: (params) ->

    # use cache
    cache = App.Store.get( 'ticket_create_attributes' )

    if cache && !params.ticket_id && !params.article_id

      # get edit form attributes
      @form_meta = cache.form_meta

      # load assets
      App.Collection.loadAssets( cache.assets )

      @render()
    else
      @ajax(
        id:    'ticket_create' + @task_key
        type:  'GET'
        url:   @apiPath + '/ticket_create'
        data:
          ticket_id: params.ticket_id
          article_id: params.article_id
        processData: true
        success: (data, status, xhr) =>

          # cache request
          App.Store.write( 'ticket_create_attributes', data )

          # get edit form attributes
          @form_meta = data.form_meta

          # load assets
          App.Collection.loadAssets( data.assets )

          # split ticket
          if data.split && data.split.ticket_id && data.split.article_id
            t = App.Ticket.find( params.ticket_id ).attributes()
            a = App.TicketArticle.find( params.article_id )

            # reset owner
            t.owner_id = 0
            t.customer_id_autocompletion = a.from
            t.subject = a.subject || t.title
            t.body = a.body

          # render page
          @render( options: t )
      )

  render: (template = {}) ->

    @html App.view('agent_ticket_create')(
      head:  'New Ticket'
      title: @article_attributes['title']
      agent: @isRole('Agent')
      admin: @isRole('Admin')
    )

    params = undefined
    if template && !_.isEmpty( template.options )
      params = template.options
    else if App.TaskManager.get(@task_key) && !_.isEmpty( App.TaskManager.get(@task_key).state )
      params = App.TaskManager.get(@task_key).state

    formChanges = (params, attribute, attributes, classname, form, ui) =>
      if @form_meta.dependencies && @form_meta.dependencies[attribute.name]
        dependency = @form_meta.dependencies[attribute.name][ parseInt(params[attribute.name]) ]
        if dependency

          for fieldNameToChange of dependency
            filter = []
            if dependency[fieldNameToChange]
              filter = dependency[fieldNameToChange]

            # find element to replace
            for item in attributes
              if item.name is fieldNameToChange
                item.display = false
                item['filter'] = {}
                item['filter'][ fieldNameToChange ] = filter
                item.default = params[item.name]
                #if !item.default
                #  delete item['default']
                newElement = ui.formGenItem( item, classname, form )

            # replace new option list
            form.find('[name="' + fieldNameToChange + '"]').replaceWith( newElement )

    new App.ControllerForm(
      el:       @el.find('.ticket-form')
      form_id:  @form_id
      model:    App.Ticket
      screen:   @article_attributes['screen']
      events:
        'change [name=customer_id]': @localUserInfo
      handlers: [
        formChanges
      ]
      filter:     @form_meta.filter
      autofocus: true
      params:    params
    )

    new App.ControllerForm(
      el:       @el.find('.article-form')
      form_id:  @form_id
      model:    App.TicketArticle
      screen:   @article_attributes['screen']
      params:    params
    )

    # show template UI
    new App.WidgetTemplate(
      el:          @el.find('.ticket_template')
      template_id: template['id']
    )

    @formDefault = @formParam( @el.find('.ticket-create') )

    # show text module UI
    @textModule = new App.WidgetTextModule(
      el: @el.find('form').find('textarea')
    )

    # start auto save
    @autosave()

  localUserInfo: (e) =>

    params = App.ControllerForm.params( $(e.target).closest('form') )

    # update text module UI
    callback = (user) =>
      if @textModule
        @textModule.reload(
          ticket:
            customer: user
        )

    @userInfo(
      user_id:  params.customer_id
      el:       @el.find('.customer_info')
      callback: callback
    )

  userNew: (e) =>
    e.preventDefault()
    new UserNew(
      create_screen: @
    )

  cancel: ->
    @navigate '#'

  submit: (e) ->
    e.preventDefault()

    # get params
    params = @formParam(e.target)

    # fillup params
    if !params.title
      params.title = params.subject

    # create ticket
    ticket = new App.Ticket

    # find sender_id
    sender = App.TicketArticleSender.findByAttribute( 'name', @article_attributes['sender'] )
    type   = App.TicketArticleType.findByAttribute( 'name', @article_attributes['article'] )

    if params.group_id
      group  = App.Group.find( params.group_id )

    # create article
    if sender.name is 'Customer'
      params['article'] = {
        to:         (group && group.name) || ''
        from:       params.customer_id_autocompletion
        cc:         params.cc
        subject:    params.subject
        body:       params.body
        type_id:    type.id
        sender_id:  sender.id
        form_id:    @form_id
      }
    else
      params['article'] = {
        from:       (group && group.name) || ''
        to:         params.customer_id_autocompletion
        cc:         params.cc
        subject:    params.subject
        body:       params.body
        type_id:    type.id
        sender_id:  sender.id
        form_id:    @form_id
      }

    ticket.load(params)

    # validate form
    ticketErrors = ticket.validate(
      screen: @article_attributes['screen']
    )
    article = new App.TicketArticle
    article.load(params['article'])
    articleErrors = article.validate(
      screen: @article_attributes['screen']
    )
    for key, value of articleErrors
      if !ticketErrors
        ticketErrors = {}
      ticketErrors[key] = value

    # show errors in form
    if ticketErrors
      @log 'error', ticketErrors
      @formValidate(
        form: e.target
        errors: ticketErrors
        screen: @article_attributes['screen']
      )

    # save ticket, create article
    else

      # disable form
      @formDisable(e)
      ui = @
      ticket.save(
        done: ->

          # notify UI
          ui.notify
            type:    'success',
            msg:     App.i18n.translateInline( 'Ticket %s created!', @number ),
            link:    "#ticket/zoom/#{@id}"
            timeout: 12000,

          # close ticket create task
          App.TaskManager.remove( ui.task_key )

          # scroll to top
          ui.scrollTo()

          # access to group
          session = App.Session.all()
          if session && session['group_ids'] && _.contains(session['group_ids'], @group_id)
            ui.navigate "#ticket/zoom/#{@id}"
            return

          # if not, show start screen
          ui.navigate "#"

        fail: ->
          ui.log 'save failed!'
          ui.formEnable(e)
      )


class UserNew extends App.ControllerModal
  constructor: ->
    super
    @render()

  render: ->

    @html App.view('agent_user_create')( head: 'New User' )

    new App.ControllerForm(
      el:         @el.find('#form-user')
      model:      App.User
      screen:     'edit'
      autofocus:  true
    )

    @modalShow()

  submit: (e) ->

    e.preventDefault()
    params = @formParam(e.target)

    # if no login is given, use emails as fallback
    if !params.login && params.email
      params.login = params.email

    user = new App.User

    # find role_id
    role = App.Role.findByAttribute( 'name', 'Customer' )
    params.role_ids = role.id
    @log 'notice', 'updateAttributes', params
    user.load(params)

    errors = user.validate()
    if errors
      @log 'error', errors
      @formValidate( form: e.target, errors: errors )
      return

    # save user
    ui = @
    user.save(
      done: ->

        # force to reload object
        callbackReload = (user) ->
          realname = user.displayName()
          if user.email
            realname = "#{ realname } <#{ user.email }>"
          ui.create_screen.el.find('[name=customer_id]').val( user.id )
          ui.create_screen.el.find('[name=customer_id_autocompletion]').val( realname )

          # start customer info controller
          ui.userInfo( user_id: user.id )
          ui.modalHide()
        App.User.full( @id, callbackReload , true )

      fail: ->
        ui.modalHide()
    )

class Router extends App.ControllerPermanent
  constructor: (params) ->
    super

    # create new uniq form id
    if !params['id']
      # remember split info if exists
      split = ''
      if params['ticket_id'] && params['article_id']
        split = "/#{params['ticket_id']}/#{params['article_id']}"

      id = Math.floor( Math.random() * 99999 )
      @navigate "#ticket/create/#{params['type']}/id/#{id}#{split}" 
      return

    # cleanup params
    clean_params =
      ticket_id:  params.ticket_id
      article_id: params.article_id
      type:       params.type
      id:         params.id

    App.TaskManager.add( 'TicketCreateScreen-' + params['type'] + '-' + params['id'], 'TicketCreate', clean_params )

# create new ticket routes/controller
App.Config.set( 'ticket/create', Router, 'Routes' )
App.Config.set( 'ticket/create/:type', Router, 'Routes' )
App.Config.set( 'ticket/create/:type/id/:id', Router, 'Routes' )


# split ticket
App.Config.set( 'ticket/create/:type/:ticket_id/:article_id', Router, 'Routes' )
App.Config.set( 'ticket/create/:type/id/:id/:ticket_id/:article_id', Router, 'Routes' )

# set new task actions
App.Config.set( 'TicketNewCallOutbound', { prio: 8001, name: 'Call Outbound', target: '#ticket/create/call_outbound', role: ['Agent'] }, 'TaskActions' )
App.Config.set( 'TicketNewCallInbound', { prio: 8002, name: 'Call Inbound', target: '#ticket/create/call_inbound', role: ['Agent'] }, 'TaskActions' )
App.Config.set( 'TicketNewEmail', { prio: 8003, name: 'Email', target: '#ticket/create/email', role: ['Agent'] }, 'TaskActions' )

