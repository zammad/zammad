class App.TicketStats extends App.Controller
  elements:
    '.js-userTab': 'userTabButton'
    '.js-orgTab': 'orgTabButton'
    '.js-user': 'userTab'
    '.js-org': 'orgTab'

  events:
    'click .js-userTab': 'showUserTab'
    'click .js-orgTab':  'showOrgTab'

  constructor: ->
    super

    # subscribe and reload data / fetch new data if triggered
    if @user
      @subscribeIdUser = App.User.full(@user.id, @load, false, true)
    else if @organization
      @subscribeIdOrganization = App.Organization.full(@organization.id, @load, false, true)

    # rerender view, e.g. on language change
    @controllerBind('ui:rerender', =>
      return if !@authenticateCheck()
      @render()
    )

  release: =>
    if @subscribeIdUser
      App.User.unsubscribe(@subscribeIdUser)
    if @subscribeIdOrganization
      App.Organization.unsubscribe(@subscribeIdOrganization)

  load: (object, type) =>

    # ignore rerender on local record changes
    return if type is 'change'

    if @organization
      ajaxKey = "org_#{@organization.id}"
      data =
        organization_id: @organization.id
    else
      ajaxKey = "user_#{@user.id}"
      data =
        user_id:         @user.id
        organization_id: @user.organization_id
    @ajax(
      id:          "ticket_stats_#{ajaxKey}"
      type:        'GET'
      url:         "#{@apiPath}/ticket_stats"
      data:        data
      processData: true
      success:     (data) =>
        App.Collection.loadAssets(data.assets)
        @data = data
        @render(data)
      )

  showOrgTab: =>
    @userTabButton.removeClass('active')
    @orgTabButton.addClass('active')
    @userTab.addClass('hide')
    @orgTab.removeClass('hide')

  showUserTab: =>
    @userTabButton.addClass('active')
    @orgTabButton.removeClass('active')
    @userTab.removeClass('hide')
    @orgTab.addClass('hide')

  render: (data) =>
    if !data
      data = @data
    return if !data

    user_total = 0
    if data.user.open_ids && data.user.closed_ids
      user_total = data.user.open_ids.length + data.user.closed_ids.length
    organization_total = 0
    if data.organization.open_ids && data.organization.closed_ids
      organization_total = data.organization.open_ids.length + data.organization.closed_ids.length

    @html App.view('widget/ticket_stats')(
      user:               @user
      user_total:         user_total
      organization:       @organization
      organization_total: organization_total
    )

    limit = 5
    if !_.isEmpty(data.user)
      iconClass = ''
      if data.user.open_ids.length is 0 && data.user.closed_ids.length > 0
        iconClass = 'mood icon supergood-color'
      new App.TicketStatsList(
        el:         @$('.js-user-open-tickets')
        user:       @user
        head:       'Open Tickets'
        iconClass:  iconClass
        ticket_ids: data.user.open_ids
        limit:      limit
      )
      new App.TicketStatsList(
        el:         @$('.js-user-closed-tickets')
        user:       @user
        head:       'Closed Tickets'
        ticket_ids: data.user.closed_ids
        limit:      limit
      )
      new App.TicketStatsFrequency(
        el:                    @$('.js-user-frequency')
        user:                  @user
        ticket_volume_by_year: data.user.volume_by_year
      )

    if !_.isEmpty(data.organization)
      iconClass = ''
      if data.organization.open_ids.length is 0 && data.organization.closed_ids.length > 0
        iconClass = 'mood icon supergood-color'
      new App.TicketStatsList(
        el:         @$('.js-org-open-tickets')
        user:       @user
        head:       'Open Tickets'
        iconClass:  iconClass
        ticket_ids: data.organization.open_ids
        limit:      limit
      )
      new App.TicketStatsList(
        el:         @$('.js-org-closed-tickets')
        user:       @user
        head:       'Closed Tickets'
        ticket_ids: data.organization.closed_ids
        limit:      limit
      )
      new App.TicketStatsFrequency(
        el:                    @$('.js-org-frequency')
        user:                  @user
        ticket_volume_by_year: data.organization.volume_by_year
      )

class App.TicketStatsList extends App.Controller
  @extend App.PopoverProvidable
  @registerPopovers 'Ticket'

  events:
    'click .js-showAll': 'showAll'

  constructor: ->
    super
    @render()

  render: =>

    ticket_ids_show = []
    if !@all
      count = 0
      for ticket_id in @ticket_ids
        count += 1
        if count <= @limit
          ticket_ids_show.push ticket_id
    else
      ticket_ids_show = @ticket_ids

    tickets = (App.Ticket.fullLocal(id) for id in ticket_ids_show)

    @html App.view('widget/ticket_stats_list')(
      user:            @user
      head:            @head
      iconClass:       @iconClass
      ticketList:      App.view('generic/ticket_list')(
        tickets: tickets
      )
      ticket_ids:      @ticket_ids
      ticket_ids_show: ticket_ids_show
      limit:           @limit
    )

    @renderPopovers()

  showAll: (e) =>
    e.preventDefault()
    @all = true
    @render()

class App.TicketStatsFrequency extends App.Controller
  constructor: ->
    super
    @render()

  render: (data) =>

    # find 100%
    max = 0
    for item in @ticket_volume_by_year
      if item.closed > max
        max = item.closed
      if item.created > max
        max = item.created

    for item in @ticket_volume_by_year
      item.created_in_percent = 100 / max * item.created
      item.closed_in_percent  = 100 / max * item.closed

    @html App.view('widget/ticket_stats_frequency')(
      ticket_volume_by_year: @ticket_volume_by_year.reverse()
    )
