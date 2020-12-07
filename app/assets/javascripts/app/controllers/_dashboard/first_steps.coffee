class App.DashboardFirstSteps extends App.Controller
  events:
    'click a': 'scrollIntoView'
    'click .js-testTicket': 'testTicket'
    'click .js-inviteAgent': 'inviteAgent'
    'click .js-inviteCustomer': 'inviteCustomer'

  constructor: ->
    super
    @interval(@load, 20000)

  load: =>
    return if @lastData && !@el.is(':visible')
    @ajax(
      type: 'GET'
      url:  @apiPath + '/first_steps'
      success: (data) =>
        return if _.isEqual(@lastData, data)
        @lastData = data
        @render(data)
    )

  render: (data) ->
    @html App.view('dashboard/first_steps')(
      data: data
    )

  scrollIntoView: (e) =>
    href = $(e.currentTarget).attr('href')
    return if !href
    return if href is '#'
    delay = =>
      element = $("[href='#{href}']")
      @scrollToIfNeeded(element)
    @delay(delay, 40)

  inviteAgent: (e) ->
    e.preventDefault()
    new App.InviteUser(
      #container: @el.closest('.content')
      head: 'Invite Colleagues'
      screen: 'invite_agent'
    )

  inviteCustomer: (e) ->
    e.preventDefault()
    new App.InviteUser(
      #container: @el.closest('.content')
      head: 'Invite Customer'
      screen: 'invite_customer'
      signup: true
    )

  testTicketLoading: =>
    template = App.view('dashboard/first_steps_test_ticket_loading')()
    create = =>
      @ajax(
        id:   'test_ticket'
        type: 'POST'
        url:  @apiPath + '/first_steps/test_ticket'
        processData: true
        success: (data) =>
          App.Collection.loadAssets(data.assets)
          ticket = App.Ticket.fullLocal(data.ticket_id)
          overview = App.Overview.fullLocal(data.overview_id)

          finish = @testTicketFinish(
            overviewName: App.i18n.translatePlain(overview.name)
            overviewUrl: overview.uiUrl()
            ticketUrl: ticket.uiUrl()
            ticketNumber: ticket.number
          )
          $('.modal .modal-body').html(finish)
      )
    @delay(create, 2800)
    template

  testTicketFinish: (data) ->
    App.view('dashboard/first_steps_test_ticket_finish')(data)

  testTicket: (e) =>
    e.preventDefault()

    modal = new App.ControllerModal(
      head: 'Test Ticket'
      #container: @el.parents('.content')
      content: @testTicketLoading
      shown: true
      buttonSubmit: false
      buttonCancel: false
      small: true
      closeOnAnyClick: true
      onSubmit: ->
        modal.close()
    )
