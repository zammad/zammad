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

    @edit_form = undefined

  # get data / in case also ticket data for split
  fetch: (params) ->

    # use cache
    cache = App.Store.get( 'ticket_create_attributes' )

    if cache && !params.ticket_id && !params.article_id

      # get edit form attributes
      @edit_form = cache.edit_form

      # load user collection
      App.Collection.load( type: 'User', data: cache.users )

      @render()
    else
      App.Com.ajax(
        id:    'ticket_create',
        type:  'GET',
        url:   @apiPath + '/ticket_create',
        data:  {
          ticket_id: params.ticket_id,
          article_id: params.article_id,
        },
        processData: true,
        success: (data, status, xhr) =>

          # cache request
          App.Store.write( 'ticket_create_attributes', data )

          # get edit form attributes
          @edit_form = data.edit_form

          # load user collection
          App.Collection.load( type: 'User', data: data.users )

          # load ticket collection
          if data.ticket && data.articles
            App.Collection.load( type: 'Ticket', data: [data.ticket] )

            # load article collections
            App.Collection.load( type: 'TicketArticle', data: data.articles || [] )

            # render page
            t = App.Ticket.find( params.ticket_id ).attributes()
            a = App.TicketArticle.find( params.article_id )

            # reset owner
            t.owner_id = 0
            t.customer_id_autocompletion = a.from
            t.subject = a.subject || t.title
            t.body = a.body
            @log 'CustomerTicketCreate', 'notice', 'created', t
          @render( options: t )
      )

  render: (template = {}) ->

    # set defaults
    defaults = template['options'] || {}
    if !( 'ticket_state_id' of defaults )
      defaults['ticket_state_id'] = App.TicketState.findByAttribute( 'name', 'new' )
    if !( 'ticket_priority_id' of defaults )
      defaults['ticket_priority_id'] = App.TicketPriority.findByAttribute( 'name', '2 normal' )

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

    # generate form    
    configure_attributes = [
      { name: 'group_id',           display: 'Group',    tag: 'select',   multiple: false, null: false, filter: groupFilter, nulloption: true, relation: 'Group', default: defaults['group_id'], class: 'span7',  },
#      { name: 'owner_id',           display: 'Owner',    tag: 'select',   multiple: false, null: true,  filter: @edit_form, nulloption: true, relation: 'User',  default: defaults['owner_id'], class: 'span7',  },
      { name: 'subject',            display: 'Subject',  tag: 'input',    type: 'text', limit: 100, null: false, default: defaults['subject'], class: 'span7', },
      { name: 'body',               display: 'Text',     tag: 'textarea', rows: 10,                  null: false, default: defaults['body'],    class: 'span7', upload: true },
#      { name: 'ticket_state_id',    display: 'State',    tag: 'select',   multiple: false, null: false, filter: @edit_form, relation: 'TicketState',    default: defaults['ticket_state_id'],    translate: true, class: 'medium' },
#      { name: 'ticket_priority_id', display: 'Priority', tag: 'select',   multiple: false, null: false, filter: @edit_form, relation: 'TicketPriority', default: defaults['ticket_priority_id'], translate: true, class: 'medium' },
    ]
    @html App.view('customer_ticket_create')( head: 'New Ticket' )

    new App.ControllerForm(
      el:      @el.find('#form_create')
      form_id: @form_id
      model:
        configure_attributes: configure_attributes
        className:            'create'
      autofocus: true
      form_data: @edit_form
    )

    # add elastic to textarea
    @el.find('textarea').elastic()

    # update textarea size
    @el.find('textarea').trigger('change')

  cancel: ->
    @navigate '#'

  submit: (e) ->
    e.preventDefault()

    # get params
    params = @formParam(e.target)

    # set customer id
    params.customer_id = @Session.get('id')

    # set prio
    priority = App.TicketPriority.findByAttribute( 'name', '2 normal' )
    params.ticket_priority_id = priority.id

    # set state
    state = App.TicketState.findByAttribute( 'name', 'new' )
    params.ticket_state_id = state.id

    # fillup params
    if !params.title
      params.title = params.subject

    # create ticket
    object = new App.Ticket
    @log 'CustomerTicketCreate', 'notice', 'updateAttributes', params

    # find sender_id
    sender = App.TicketArticleSender.findByAttribute( 'name', 'Customer' )
    type   = App.TicketArticleType.findByAttribute( 'name', 'web' )
    if params.group_id
      group  = App.Group.find( params.group_id )

    # create article
    params['article'] = {
      from:                     "#{ @Session.get('firstname') } #{ @Session.get('lastname') }"
      to:                       (group && group.name) || ''
      subject:                  params.subject
      body:                     params.body
      ticket_article_type_id:   type.id
      ticket_article_sender_id: sender.id
      form_id:                  @form_id
    }

    object.load(params)

    # validate form
    errors = object.validate()

    # show errors in form
    if errors
      @log 'CustomerTicketCreate', 'error', 'can not create', errors

      @formValidate( form: e.target, errors: errors )

    # save ticket, create article
    else 

      # disable form
      @formDisable(e)
      ui = @
      object.save(
        success: ->

          # redirect to zoom
          ui.navigate '#ticket/zoom/' + this.id

        error: ->
          ui.log 'CustomerTicketCreate', 'error', 'can not create'
          ui.formEnable(e)
      )

App.Config.set( 'customer_ticket_new', Index, 'Routes' )

#App.Config.set( 'CustomerTicketNew', { prio: 1600, parent: '', name: 'New Ticket', target: '#customer_ticket_new', role: ['Customer'] }, 'NavBar' )
App.Config.set( 'CustomerTicketNew', { prio: 8000, parent: '', name: 'New', target: '#customer_ticket_new', role: ['Customer'] }, 'NavBarRight' )

