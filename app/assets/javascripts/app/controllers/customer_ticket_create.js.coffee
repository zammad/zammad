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
    @form_meta = undefined

    @fetch(params)
    @navupdate '#customer_ticket_new'

  # get data / in case also ticket data for split
  fetch: (params) ->

    # use cache
    cache = App.Store.get( 'ticket_create_attributes' )

    if cache

      # get edit form attributes
      @form_meta = cache.form_meta

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

          # get edit form attributes
          @form_meta = data.form_meta

          # load assets
          App.Collection.loadAssets( data.assets )

          @render()
      )

  render: (template = {}) ->

    # set defaults
    defaults = template['options'] || {}
    if !( 'state_id' of defaults )
      defaults['state_id'] = App.TicketState.findByAttribute( 'name', 'new' )
    if !( 'priority_id' of defaults )
      defaults['priority_id'] = App.TicketPriority.findByAttribute( 'name', '2 normal' )

    groupFilter = (collection, type) =>

      # only filter on collections
      return collection if type isnt 'collection'

      # get configured ids
      group_ids = App.Config.get('customer_ticket_create_group_ids')

      # return all groups if no one is selected
      return collection if !group_ids
      return collection if !_.isArray( group_ids ) && group_ids is ''
      return collection if _.isEmpty( group_ids )

      if !_.isArray( group_ids )
         group_ids = [group_ids]

      # filter selected groups
      if _.isEmpty( group_ids )
        return collection
      _.filter(
        collection
        (item) ->
          return item if item && _.contains( group_ids, item.id.toString() )
      )

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

    @html App.view('customer_ticket_create')( head: 'New Ticket' )


    new App.ControllerForm(
      el:       @el.find('.ticket-form-top')
      form_id:  @form_id
      model:    App.Ticket
      screen:   'create_top'#@article_attributes['screen']
      handlers: [
        formChanges
      ]
      filter:     @form_meta.filter
      autofocus: true
      params:    defaults
    )

    new App.ControllerForm(
      el:       @el.find('.article-form-top')
      form_id:  @form_id
      model:    App.TicketArticle
      screen:   'create_top'#@article_attributes['screen']
      params:   defaults
    )
    new App.ControllerForm(
      el:       @el.find('.ticket-form-middle')
      form_id:  @form_id
      model:    App.Ticket
      screen:   'create_middle'#@article_attributes['screen']
      handlers: [
        formChanges
      ]
      filter:     @form_meta.filter
      params:    defaults
      noFieldset: true
    )
    #new App.ControllerForm(
    #  el:       @el.find('.ticket-form-bottom')
    #  form_id:  @form_id
    #  model:    App.Ticket
    #  screen:   'create_bottom'#@article_attributes['screen']
    #  handlers: [
    #    formChanges
    #  ]
    #  filter:     @form_meta.filter
    #  params:    defaults
    #)

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
      from:       "#{ @Session.get().displayName() }"
      to:         (group && group.name) || ''
      subject:    params.subject
      body:       params.body
      type_id:    type.id
      sender_id:  sender.id
      form_id:    @form_id
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
App.Config.set( 'CustomerTicketNew', { prio: 8003, parent: '#new', name: 'New Ticket', target: '#customer_ticket_new', role: ['Customer'], divider: true }, 'NavBarRight' )
