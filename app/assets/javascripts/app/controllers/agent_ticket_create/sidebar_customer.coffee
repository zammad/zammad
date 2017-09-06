class SidebarCustomer extends App.Controller
  sidebarItem: =>
    return if !@permissionCheck('ticket.agent')
    return if !@params.customer_id
    {
      head:    'Customer'
      name:    'customer'
      icon:    'person'
      actions: [
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
      user_id:  @params.customer_id
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
      container: @el.closest('.content')
    )

App.Config.set('200-Customer', SidebarCustomer, 'TicketCreateSidebar')
