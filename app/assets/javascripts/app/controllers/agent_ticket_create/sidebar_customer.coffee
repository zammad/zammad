class SidebarCustomer extends App.Controller
  sidebarItem: =>
    return if !@permissionCheck('ticket.agent')
    return if _.isEmpty(@params.customer_id)
    @item = {
      name: 'customer'
      badgeCallback: @badgeRender
      sidebarHead: 'Customer'
      sidebarCallback: @showCustomer
      sidebarActions: []
    }
    if App.User.exists(@params.customer_id)
      customer = App.User.find(@params.customer_id)
      if customer.isAccessibleBy(App.User.current(), 'change')
        @item.sidebarActions.push {
          title:    'Edit Customer'
          name:     'customer-edit'
          callback: @editCustomer
        }
    @item

  metaBadge: (user) =>
    counter = ''
    cssClass = ''
    counter = @sidebarItemCounter(user)

    if @Config.get('ui_sidebar_open_ticket_indicator_colored') is true
      if counter == 1
        cssClass = 'tabsSidebar-tab-count--warning'
      if counter > 1
        cssClass = 'tabsSidebar-tab-count--danger'

    {
      name: 'customer'
      icon: 'person'
      counterPossible: true
      counter: counter
      cssClass: cssClass
    }

  badgeRender: (el) =>
    @badgeEl = el
    if App.User.exists(@params.customer_id)
      user = App.User.find(@params.customer_id)
      @badgeRenderLocal(user)

  badgeRenderLocal: (user) =>
    @badgeEl.html(App.view('generic/sidebar_tabs_item')(@metaBadge(user)))

  sidebarItemCounter: (user) ->
    counter = ''
    if user && user.preferences && user.preferences.tickets_open
      counter = user.preferences.tickets_open
    counter

  showCustomer: (el) =>
    @elSidebar = el
    return if _.isEmpty(@params.customer_id)
    new App.WidgetUser(
      el:       @elSidebar
      user_id:  @params.customer_id
      callback: @badgeRenderLocal
    )

  editCustomer: =>
    new App.ControllerGenericEdit(
      id: @params.customer_id
      genericObject: 'User'
      screen: 'edit'
      pageData:
        title:   'Users'
        object:  'User'
        objects: 'Users'
      container: @elSidebar.closest('.content')
    )

App.Config.set('200-Customer', SidebarCustomer, 'TicketCreateSidebar')
