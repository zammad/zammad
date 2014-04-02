class App.TicketMerge extends App.ControllerModal
  constructor: ->
    super
    @fetch()

  fetch: ->

    # merge tickets
    @ajax(
      id:    'ticket_merge_list'
      type:  'GET'
      url:   @apiPath + '/ticket_merge_list/' + @ticket_id
      processData: true,
      success: (data, status, xhr) =>

        # load assets
        App.Collection.loadAssets( data.assets )

        @ticket_ids_by_customer    = data.ticket_ids_by_customer
        @ticket_ids_recent_viewed  = data.ticket_ids_recent_viewed

        @render()
    )

  render: ->

    @html App.view('agent_ticket_merge')()

    list = []
    for ticket_id in @ticket_ids_by_customer
      if ticket_id isnt @ticket_id
        ticketItem = App.Ticket.retrieve( ticket_id )
        list.push ticketItem
    new App.ControllerTable(
      el:                @el.find('#ticket-merge-customer-tickets'),
      overview_extended: [
        { name: 'number',                 link: true },
        { name: 'title',                  link: true },
#        { name: 'customer',               class: 'user-popover', data: { id: true } },
        { name: 'ticket_state',           translate: true },
#        { name: 'ticket_priority',        translate: true },
        { name: 'group' },
#        { name: 'owner',                  class: 'user-popover', data: { id: true } },
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
    for ticket_id in @ticket_ids_recent_viewed
      if ticket_id isnt @ticket_id
        ticketItem = App.Ticket.retrieve( ticket_id )
        list.push ticketItem
    new App.ControllerTable(
      el:                @el.find('#ticket-merge-recent-tickets'),
      overview_extended: [
        { name: 'number',                 link: true },
        { name: 'title',                  link: true },
#        { name: 'customer',               class: 'user-popover', data: { id: true } },
        { name: 'ticket_state',           translate: true },
#        { name: 'ticket_priority',        translate: true },
        { name: 'group' },
#        { name: 'owner',                  class: 'user-popover', data: { id: true } },
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
      $(e.target).parents().find('[name="radio"]').prop( 'checked', false )
    )

    @el.delegate('[name="radio"]', 'click', (e) ->
      if $(e.target).prop('checked')
        ticket_id = $(e.target).val()
        ticket    = App.Ticket.retrieve( ticket_id )
        $(e.target).parents().find('[name="master_ticket_number"]').val( ticket.number )
    )

    @modalShow()

  submit: (e) =>
    e.preventDefault()

    # disable form
    @formDisable(e)

    params = @formParam(e.target)

    # merge tickets
    @ajax(
      id:    'ticket_merge',
      type:  'GET',
      url:   @apiPath +  '/ticket_merge/' + @ticket_id + '/' + params['master_ticket_number'],
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
          @log 'notice', 'nav...', App.Ticket.find( data.master_ticket['id'] )
          @navigate '#ticket/zoom/' + data.master_ticket['id']

          # notify UI
          @notify
            type:    'success'
            msg:     App.i18n.translateContent( 'Ticket %s merged!', data.slave_ticket['number'] )
            timeout: 4000

          App.TaskManager.remove( 'Ticket-' + data.slave_ticket['id'] )

        else

          # notify UI
          @notify
            type:    'error'
            msg:     App.i18n.translateContent( data['message'] )
            timeout: 6000

          @formEnable(e)

      error: =>
        @formEnable(e)
    )

