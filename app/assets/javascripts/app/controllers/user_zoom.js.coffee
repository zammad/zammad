class App.UserZoom extends App.Controller
  events:
    'focusout [data-type=update]': 'update',

  constructor: (params) ->
    super

    # check authentication
    if !@authenticate()
      App.TaskManager.remove( @task_key )
      return

    @navupdate '#'

    # subscribe and reload data / fetch new data if triggered
    @subscribeId = App.User.full( @user_id, @render, false, true )

  release: =>
    App.User.unsubscribe(@subscribeId)

  meta: =>
    meta =
      url: @url()
      id:  @user_id

    if App.User.exists( @user_id )
      user = App.User.find( @user_id )

      meta.head       = user.displayName()
      meta.title      = user.displayName()
      meta.iconClass  = user.icon()
    meta

  url: =>
    '#user/zoom/' + @user_id

  show: =>
    App.OnlineNotification.seen( 'User', @user_id )
    @navupdate '#'

  changed: =>
    false

  render: (user) =>

    if !@doNotLog
      @doNotLog = 1
      @recentView( 'User', @user_id )

    # get display data
    userData = []
    for item2 in App.User.configure_attributes
      item = _.clone( item2 )

      # check if value for _id exists
      itemNameValue = item.name
      itemNameValueNew = itemNameValue.substr( 0, itemNameValue.length - 3 )
      if itemNameValueNew of user
        item.name = itemNameValueNew

      # add to show if value exists
      if user[item.name] || item.tag is 'textarea'

        # do not show firstname and lastname / already show via diplayName()
        if item.name isnt 'firstname' && item.name isnt 'lastname' && item.name isnt 'organization'
          if item.info
            userData.push item

    @html App.view('user_zoom')(
      user:     user
      userData: userData
    )

    @$('[contenteditable]').ce({
      mode:      'textonly'
      multiline: true
      maxlength: 250
    })

    #new Overviews(
    #  el:   @el
    #  user: user
    #)

    new TicketStats(
      el:   @$('.js-ticket-stats')
      user: user
    )

    new App.UpdateTastbar(
      genericObject: user
    )

    # start action controller
    showHistory = =>
      new App.UserHistory( user_id: user.id )

    editUser = =>
      new App.ControllerGenericEdit(
        id: user.id
        genericObject: 'User'
        screen: 'edit'
        pageData:
          title: 'Users'
          object: 'User'
          objects: 'Users'
      )

    actions = [
      {
        name:     'edit'
        title:    'Edit'
        callback: editUser
      }
      {
        name:     'history'
        title:    'History'
        callback: showHistory
      }
    ]

    new App.ActionRow(
      el:    @el.find('.action')
      items: actions
    )

  update: (e) =>
    console.log('update')
    note = $(e.target).ceg()
    user = App.User.find( @user_id )
    if user.note isnt note
      user.updateAttributes( note: note )
      @log 'notice', 'update', e, note, user


class TicketStats extends App.Controller
  events:
    'click .js-userTab': 'showUserTab'
    'click .js-orgTab':  'showOrgTab'

  constructor: ->
    super

    # subscribe and reload data / fetch new data if triggered
    @subscribeId = App.User.full( @user.id, @load, false, true )

  release: =>
    App.User.unsubscribe(@subscribeId)

  load: (user) =>
    @ajax(
      id:    'ticket_stats_' + user.id,
      type:  'GET',
      url:   @apiPath + '/ticket_stats/' + user.id,
      success: (data) =>
       # load assets
        App.Collection.loadAssets( data.assets )

        @render(data)
      )

  showOrgTab: =>
    @$('.js-userTab').removeClass('active')
    @$('.js-orgTab').addClass('active')
    @$('.js-user').addClass('hide')
    @$('.js-org').removeClass('hide')

  showUserTab: =>
    @$('.js-userTab').addClass('active')
    @$('.js-orgTab').removeClass('active')
    @$('.js-user').removeClass('hide')
    @$('.js-org').addClass('hide')

  render: (data) =>

    @html App.view('user_zoom/ticket_stats')(
      user: @user
    )

    limit = 5
    new TicketStatsList(
      el:         @$('.js-user-open-tickets')
      user:       @user
      head:       'Open Ticket'
      ticket_ids: data.user_tickets_open_ids
      limit:      limit
    )
    new TicketStatsList(
      el:         @$('.js-user-closed-tickets')
      user:       @user
      head:       'Closed Ticket'
      ticket_ids: data.user_tickets_closed_ids
      limit:      limit
    )
    new TicketStatsFrequency(
      el:                    @$('.js-user-frequency')
      user:                  @user
      ticket_volume_by_year: data.user_ticket_volume_by_year
    )

    new TicketStatsList(
      el:         @$('.js-org-open-tickets')
      user:       @user
      head:       'Open Ticket'
      ticket_ids: data.org_tickets_open_ids
      limit:      limit
    )
    new TicketStatsList(
      el:         @$('.js-org-closed-tickets')
      user:       @user
      head:       'Closed Ticket'
      ticket_ids: data.org_tickets_closed_ids
      limit:      limit
    )
    new TicketStatsFrequency(
      el:                    @$('.js-org-frequency')
      user:                  @user
      ticket_volume_by_year: data.org_ticket_volume_by_year
    )

class TicketStatsList extends App.Controller
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

    @html App.view('user_zoom/ticket_stats_list')(
      user:            @user
      head:            @head
      ticket_ids:      @ticket_ids
      ticket_ids_show: ticket_ids_show
      limit:           @limit
    )
    @frontendTimeUpdate()
    @ticketPopups()

  showAll: (e) =>
    e.preventDefault()
    @all = true
    @render()

class TicketStatsFrequency extends App.Controller
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
    console.log('MM', max)
    for item in @ticket_volume_by_year
      item.created_in_percent = 100 / max * item.created
      item.closed_in_percent = 100 / max * item.closed

    @html App.view('user_zoom/ticket_stats_frequency')(
      user: @user
      ticket_volume_by_year: @ticket_volume_by_year.reverse()
    )

class Overviews extends App.Controller
  constructor: ->
    super

    # subscribe and reload data / fetch new data if triggered
    @subscribeId = App.User.full( @user.id, @render, false, true )

  release: =>
    App.User.unsubscribe(@subscribeId)

  render: (user) =>

    plugins = {
      main: {
        my_assigned: {
          controller: App.DashboardTicketSearch,
          params: {
            name: 'Tickets of User'
            condition:
              'tickets.state_id': [ 1,2,3,4,6 ]
              'tickets.customer_id': user.id
            order:
              by:        'created_at'
              direction: 'DESC'
            view:
              d: [ 'number', 'title', 'state', 'priority', 'created_at' ]
              view_mode_default: 'd'
          },
        },
      },
    }
    if user.organization_id
      plugins.main.my_organization = {
        controller: App.DashboardTicketSearch,
        params: {
          name: 'Tickets of Organization'
          condition:
            'tickets.state_id': [ 1,2,3,4,6 ]
            'tickets.organization_id': user.organization_id
          order:
            by:        'created_at'
            direction: 'DESC'
          view:
            d: [ 'number', 'title', 'customer', 'state', 'priority', 'created_at' ]
            view_mode_default: 'd'
        },
      }

    for area, plugins of plugins
      for name, plugin of plugins
        target = area + '_' + name
        @el.find('.' + area + '-overviews').append('<div class="" id="' + target + '"></div>')
        if plugin.controller
          params = plugin.params || {}
          params.el = @el.find( '#' + target )
          new plugin.controller( params )

    dndOptions =
      handle:               'h2.can-move'
      placeholder:          'can-move-plcaeholder'
      tolerance:            'pointer'
      distance:             15
      opacity:              0.6
      forcePlaceholderSize: true

    @el.find( '#sortable' ).sortable( dndOptions )
    @el.find( '#sortable-sidebar' ).sortable( dndOptions )


class Router extends App.ControllerPermanent
  constructor: (params) ->
    super

    # cleanup params
    clean_params =
      user_id:  params.user_id

    App.TaskManager.add( 'User-' + @user_id, 'UserZoom', clean_params )

App.Config.set( 'user/zoom/:user_id', Router, 'Routes' )
