class SidebarCustomer extends App.Controller
  sidebarItem: =>
    return if !@permissionCheck('ticket.agent')
    return if _.isEmpty(@params.customer_id)
    counter = ''
    if App.User.exists(@params.customer_id)
      user = App.User.find(@params.customer_id)
      counter = @sidebarItemCounter(user)
    {
      head:    'Customer'
      name:    'customer'
      icon:    'person'
      counter: counter
      counterPossible: true
      actions: [
        {
          title:    'Edit Customer'
          name:     'customer-edit'
          callback: @editCustomer
        },
      ]
      callback: @showCustomer
    }

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
    return if _.isEmpty(@params.customer_id)
    new App.WidgetUser(
      el:       @el
      user_id:  @params.customer_id
      callback: @sidebarItemUpdate
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
