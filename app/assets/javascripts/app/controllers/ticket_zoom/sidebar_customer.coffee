class SidebarCustomer extends App.Controller
  sidebarItem: =>
    return if !@permissionCheck('ticket.agent')
    {
      head:    'Customer'
      name:    'customer'
      icon:    'person'
      actions: [
        {
          title:    'Change Customer'
          name:     'customer-change'
          callback: @changeCustomer
        },
        {
          title:    'Edit Customer'
          name:     'customer-edit'
          callback: @editCustomer
        },
      ]
      callback: @showCustomer
    }

  showCustomer: (el) =>
    @el = el
    new App.WidgetUser(
      el:       @el
      user_id:  @ticket.customer_id
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
