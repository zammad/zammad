class SidebarCustomer extends App.Controller
  sidebarItem: =>
    return if !@permissionCheck('ticket.agent')
    counter = ''
    if App.User.exists(@ticket.customer_id)
      user = App.User.find(@ticket.customer_id)
      counter = @sidebarItemCounter(user)
    items = {
      head:    'Customer'
      name:    'customer'
      icon:    'person'
      counter: counter
      counterPossible: true
      actions: [
        {
          title:    'Change Customer'
          name:     'customer-change'
          callback: @changeCustomer
        },
      ]
      callback: @showCustomer
    }
    return items if @ticket && @ticket.customer_id == 1
    items.actions.push {
      title:    'Edit Customer'
      name:     'customer-edit'
      callback: @editCustomer
    }
    items

  sidebarItemCounter: (user) ->
    counter = ''
    if user && user.preferences && user.preferences.tickets_open
      counter = user.preferences.tickets_open
    counter

  sidebarItemUpdate: (user) =>
    counter = @sidebarItemCounter(user)
    element = @el.closest('.tabsSidebar-holder').find('.tabsSidebar .tabsSidebar-tabs .tabsSidebar-tab[data-tab=customer] .js-tabCounter')
    if !counter || counter is 0
      element.addClass('hide')
    else
      element.removeClass('hide')
    element.text(counter)

  showCustomer: (el) =>
    @el = el
    new App.WidgetUser(
      el:       @el
      user_id:  @ticket.customer_id
      callback: @sidebarItemUpdate
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
      container: @el.closest('.content')
    )

  changeCustomer: =>
    new App.TicketCustomer(
      ticket_id: @ticket.id
      container: @el.closest('.content')
    )

App.Config.set('200-Customer', SidebarCustomer, 'TicketZoomSidebar')
