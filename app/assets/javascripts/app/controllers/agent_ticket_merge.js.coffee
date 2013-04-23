class App.TicketMerge extends App.ControllerModal
  constructor: ->
    super
    @fetch()

  fetch: ->

    # merge tickets
    App.Com.ajax(
      id:    'ticket_merge_list',
      type:  'GET',
      url:   'api/ticket_merge_list/' + @ticket_id,
      data:  {
#        view: @view
      }
      processData: true,
      success: (data, status, xhr) =>

        if data.customer
          App.Collection.load( type: 'Ticket', data: data.customer.tickets )
          App.Collection.load( type: 'User', data: data.customer.users )

        if data.recent
          App.Collection.load( type: 'Ticket', data: data.recent.tickets )
          App.Collection.load( type: 'User', data: data.recent.users )

        @render( data )
    )

  render: (data) ->

    @html App.view('agent_ticket_merge')()

    list = []
    for t in data.customer.tickets
      if t.id isnt @ticket_id
        ticketItem = App.Collection.find( 'Ticket', t.id )
        list.push ticketItem
    new App.ControllerTable(
      el:                @el.find('#ticket-merge-customer-tickets'),
      overview_extended: [
        { name: 'number',                 link: true },
        { name: 'title',                  link: true },
#        { name: 'customer',               class: 'user-data', data: { id: true } },
        { name: 'ticket_state',           translate: true },
#        { name: 'ticket_priority',        translate: true },
        { name: 'group' },
#        { name: 'owner',                  class: 'user-data', data: { id: true } },
        { name: 'created_at',             callback: @humanTime },
#        { name: 'last_contact',           callback: @frontendTime },
#        { name: 'last_contact_agent',     callback: @frontendTime },
#        { name: 'last_contact_customer',  callback: @frontendTime },
#        { name: 'first_response',         callback: @frontendTime },
#        { name: 'close_time',             callback: @frontendTime },
      ],
      model:    App.Ticket,
      objects:  list,
      radio:    true,
    )

    list = []
    for t in data.recent.tickets
      if t.id isnt @ticket_id
        ticketItem = App.Collection.find( 'Ticket', t.id )
        list.push ticketItem
    new App.ControllerTable(
      el:                @el.find('#ticket-merge-recent-tickets'),
      overview_extended: [
        { name: 'number',                 link: true },
        { name: 'title',                  link: true },
#        { name: 'customer',               class: 'user-data', data: { id: true } },
        { name: 'ticket_state',           translate: true },
#        { name: 'ticket_priority',        translate: true },
        { name: 'group' },
#        { name: 'owner',                  class: 'user-data', data: { id: true } },
        { name: 'created_at',             callback: @humanTime },
#        { name: 'last_contact',           callback: @frontendTime },
#        { name: 'last_contact_agent',     callback: @frontendTime },
#        { name: 'last_contact_customer',  callback: @frontendTime },
#        { name: 'first_response',         callback: @frontendTime },
#        { name: 'close_time',             callback: @frontendTime },
      ],
      model:    App.Ticket,
      objects:  list,
      radio:    true,
    )

    @el.delegate('[name="master_ticket_number"]', 'focus', (e) ->
      $(e.target).parents().find('[name="radio"]').attr( 'checked', false )
    )

    @el.delegate('[name="radio"]', 'click', (e) ->
        if $(e.target).attr('checked')
          ticket_id = $(e.target).val()
          ticket    = App.Collection.find( 'Ticket', ticket_id )
          $(e.target).parents().find('[name="master_ticket_number"]').val( ticket.number )
      )

    @modalShow()

  submit: (e) =>
    e.preventDefault()

    params = @formParam(e.target)

    # merge tickets
    App.Com.ajax(
      id:    'ticket_merge',
      type:  'GET',
      url:   'api/ticket_merge/' + @ticket_id + '/' + params['master_ticket_number'],
      data:  {
#        view: @view
      }
      processData: true,
      success: (data, status, xhr) =>

        if data['result'] is 'success'

          # update collection
          App.Collection.load( type: 'Ticket', data: [data.master_ticket] )
          App.Collection.load( type: 'Ticket', data: [data.slave_ticket] )

          # hide dialog
          @modalHide()

          # view ticket
          @log 'nav...', App.Collection.find( 'Ticket', data.master_ticket['id'] )
          @navigate '#ticket/zoom/' + data.master_ticket['id']

          # notify UI
          @notify
            type:    'success',
            msg:     App.i18n.translateContent( 'Ticket %s merged!', data.slave_ticket['number'] ),
            timeout: 4000,

          App.TaskManager.remove( @task_key )

        else

          # notify UI
          @notify
            type:    'error',
            msg:     App.i18n.translateContent( data['message'] ),
            timeout: 6000,
#      error: =>
    )
    
