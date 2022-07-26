class App.WidgetUser extends App.Controller
  @extend App.PopoverProvidable
  @registerPopovers 'UserTicket'

  organizationLimit: 3

  events:
    'click .js-showMoreOrganizations a': 'showMoreOrganizations'
    'focusout [contenteditable]': 'update'

  constructor: ->
    super

    # subscribe and reload data / fetch new data if triggered
    @subscribeId = App.User.full(@user_id, @render, false, true)

  release: =>
    App.User.unsubscribe(@subscribeId)

  getAdvancedSearchUrl: (customer_id, states) ->
    states_string = ''
    if states.length > 1
      states_string = ' AND state.name:("' + states.join('" OR "') + '")'
    else
      states_string = " AND state.name:\"#{states[0]}\""

    return "/#search/customer_id:#{customer_id}#{states_string}"

  render: (user) =>
    if user
      @user = user

    # execute callback on render/rerender
    if @callback
      @callback(user)

    # get display data
    userData = []
    for attributeName, attributeConfig of App.User.attributesGet('view')

      # check if value for _id exists
      name    = attributeName
      nameNew = name.substr( 0, name.length - 3 )
      if nameNew of user
        name = nameNew

      # do not show firstname and lastname since they are already shown via diplayName()
      continue if name is 'firstname' || name is 'lastname' || name is 'organization'

      # do not show if configured to be not shown
      continue if !attributeConfig.shown

      # Fix for issue #2277 - note is not shown for customer/organisations if it's empty
      # Always show for these two conditions:
      # 1. the attribute exists and is not empty
      # 2. it is a richtext note field
      continue if ( !user[name]? || user[name] is '' ) && attributeConfig.tag isnt 'richtext'

      # add to show if all checks passed
      userData.push attributeConfig

    if user.preferences
      items = []
      if user.preferences.tickets_open > 0
        states_open = App.TicketState.byCategory('open').map((state) -> state.name)
        item =
          url: @getAdvancedSearchUrl(@user_id, states_open)
          name: 'open'
          count: user.preferences.tickets_open
          title: __('Open Tickets')
          class: 'user-tickets'
          data:  'open'
        items.push item
      if user.preferences.tickets_closed > 0
        states_closed = App.TicketState.byCategory('closed').map((state) -> state.name)
        item =
          url: @getAdvancedSearchUrl(@user_id, states_closed)
          name: 'closed'
          count: user.preferences.tickets_closed
          title: __('Closed Tickets')
          class: 'user-tickets'
          data:  'closed'
        items.push item

      if items[0]
        topic =
          title: __('Tickets')
          items: items
        user['links'] = []
        user['links'].push topic

    # insert userData
    @html App.view('widget/user')(
      header:   __('Customer')
      edit:     true
      user:     user
      userData: userData
    )
    @renderOrganizations()

    @$('[contenteditable]').ce(
      mode:      'textonly'
      multiline: true
      maxlength: 250
    )

    @renderPopovers(
      selector: '.user-tickets',
      user_id:  user.id
    )

  showMoreOrganizations: (e) ->
    @preventDefaultAndStopPropagation(e)
    @organizationLimit = (parseInt(@organizationLimit / 100) + 1) * 100
    @renderOrganizations()

  renderOrganizations: ->
    elLocal = @el
    @user.secondaryOrganizations(0, @organizationLimit, (secondaryOrganizations) ->
      organizations = []
      for organization in secondaryOrganizations
        el = $('<li></li>')
        new Organization(
          object_id: organization.id
          el: el
        )
        organizations.push el

      elLocal.find('.js-organizationList li').not('.js-showMoreOrganizations').remove()
      elLocal.find('.js-organizationList').prepend(organizations)
    )

    if @user.organization_ids && @user.organization_ids.length < @organizationLimit
      @el.find('.js-showMoreOrganizations').addClass('hidden')
    else
      @el.find('.js-showMoreOrganizations').removeClass('hidden')

  update: (e) =>
    name  = $(e.target).attr('data-name')
    value = $(e.target).html()
    user  = App.User.find(@user_id)
    if user[name] isnt value
      data = {}
      data[name] = value
      user.updateAttributes(data)
      @log 'notice', 'update', name, value, user

class Organization extends App.ControllerObserver
  model: 'Organization'
  observe:
    name: true

  render: (organization) =>
    @html App.view('user_profile/organization')(
      organization: organization
    )
