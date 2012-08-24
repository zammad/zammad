$ = jQuery.sub()

class App.LinkInfo extends App.Controller
  events:
    'click [data-type=add]': 'add',
    'click [data-type=edit]': 'edit',
    'click [data-type=remove]': 'remove',

  constructor: ->
    super
    @fetch()

  fetch: () =>
    # fetch item on demand
    # get data
    App.Com.ajax(
      id:    'links_' + @object.id + '_' + @object_type,
      type:  'GET',
      url:   '/links',
      data:  {
        link_object:       @object_type,
        link_object_value: @object.id,
      }
      processData: true,
      success: (data, status, xhr) =>
        @links = data.links

        # load user collection
        @loadCollection( type: 'User', data: data.users )

        # load ticket collection
        @loadCollection( type: 'Ticket', data: data.tickets )

        @render()
    )

  render: () =>

    list = {}
    for item in @links
      if !list[ item['link_type'] ]
        list[ item['link_type'] ] = []
        
      if item['link_object'] is 'Ticket'
        ticket = App.Ticket.find( item['link_object_value'] )
        if ticket.ticket_state.name is 'merged'
          ticket.css = 'merged'
        list[ item['link_type'] ].push ticket

    # insert data
    @html App.view('link/info')(
      links: list,
    )
    
#    @ticketPopups(
#      selector: '.user-tickets',
#      user_id:  user_id,
#    )

  edit: (e) =>
    e.preventDefault()
    if $(e.target).parent().parent().find('[data-type=remove]').is('.hide')
      $(e.target).parent().parent().find('[data-type=remove]').removeClass('hide')
    else
      $(e.target).parent().parent().find('[data-type=remove]').addClass('hide')

  remove: (e) =>
    e.preventDefault()
    link_type   = $(e.target).data('link-type')
    link_object_source = $(e.target).data('object')
    link_object_source_value = $(e.target).data('object-id')
    link_object_target = @object_type
    link_object_target_value = @object.id

    # get data
    App.Com.ajax(
      id:    'links_remove_' + @object.id + '_' + @object_type,
      type:  'GET',
      url:   '/links/remove',
      data:  {
        link_type:                 link_type,
        link_object_source:        link_object_source,
        link_object_source_value:  link_object_source_value,
        link_object_target:        link_object_target,
        link_object_target_value:  link_object_target_value,
      }
      processData: true,
      success: (data, status, xhr) =>
        @fetch()
    )

  add: (e) =>
    e.preventDefault()
    new App.LinkAdd(
      link_object:    @object_type,
      link_object_id: @object.id,
      object:         @object,
      parent:         @,
    )

class App.LinkAdd extends App.ControllerModal
  constructor: ->
    super
    @render()

  render: =>
    @html App.view('link/add')(
      link_object:    @link_object,
      link_object_id: @link_object_id,
      object:         @object,
    )
    @modalShow()

  submit: (e) =>
    e.preventDefault()
    params = @formParam(e.target)
    @log 'link', params

    # get data
    App.Com.ajax(
      id:    'links_add_' + @object.id + '_' + @object_type,
      type:  'GET',
      url:   '/links/add',
      data:  {
        link_type:                params['link_type'],
        link_object_source:       'Ticket',
        link_object_source_value: @object.id,
        link_object_target:       'Ticket',
        link_object_target_number: params['ticket_number'],
      }
      processData: true,
      success: (data, status, xhr) =>
        @modalHide()
        @parent.fetch()
    )