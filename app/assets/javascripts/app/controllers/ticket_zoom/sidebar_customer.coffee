class SidebarCustomer extends App.Controller
  sidebarItem: =>
    return if @ticket.currentView() isnt 'agent'
    @item = {
      name: 'customer'
      badgeCallback: @badgeRender
      sidebarHead: 'Customer'
      sidebarCallback: @showCustomer
      sidebarActions: [
        {
          title:    'Change Customer'
          name:     'customer-change'
          callback: @changeCustomer
        },
      ]
    }
    return @item if @ticket && @ticket.customer_id == 1

    # prevent exceptions if customer model is no available
    if @ticket.customer_id && App.User.exists(@ticket.customer_id)
      customer = App.User.find(@ticket.customer_id)
      if customer?.isAccessibleBy(App.User.current(), 'change')
        @item.sidebarActions.push {
          title:    'Edit Customer'
          name:     'customer-edit'
          callback: @editCustomer
        }

    if @permissionCheck('admin.data_privacy')
      @item.sidebarActions.push {
        title:    'Delete Customer'
        name:     'customer-delete'
        callback: =>
          @navigate "#system/data_privacy/#{@ticket.customer_id}"
      }

    @item

  metaBadge: (user) =>
    counter = ''
    cssClass = ''
    counter = @sidebarItemCounter(user)

    if @Config.get('ui_sidebar_open_ticket_indicator_colored') is true
      if counter == 2
        cssClass = 'tabsSidebar-tab-count--warning'
      if counter > 3
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
    if App.User.exists(@ticket.customer_id)
      user = App.User.find(@ticket.customer_id)
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
    new App.WidgetUser(
      el:       @elSidebar
      user_id:  @ticket.customer_id
      callback: @badgeRenderLocal
    )

  editCustomer: =>
    new App.ControllerGenericEdit(
      id: @ticket.customer_id
      genericObject: 'User'
      screen: 'edit'
      pageData:
        title:   'Users'
        object:  'User'
        objects: 'Users'
      container: @elSidebar.closest('.content')
    )

  changeCustomer: =>
    new App.TicketCustomer(
      ticket_id: @ticket.id
      container: @elSidebar.closest('.content')
    )

App.Config.set('200-Customer', SidebarCustomer, 'TicketZoomSidebar')
