class App.SidebarCustomerDefault extends App.Controller
  constructor: (params) ->
    super
    return if @permissionCheck('ticket.agent')
    return if !@permissionCheck('ticket.customer')
    @render()

  sidebarItem: =>
    return if @permissionCheck('ticket.agent')
    return if !@permissionCheck('ticket.customer')

    @item = {
      name: 'sidebar_customer_default'
      badgeIcon: 'info'
      sidebarHead: __('What can you do here?')
      sidebarCallback: @renderSidebar
    }
    @item

  renderSidebar: (el) =>
    if el
      @el = el

    @render()

  render: ->
    @html new App.ControllerDrox(
      data:
        html:   App.i18n.translateInline('The way to communicate with us is this thing called "ticket".') + ' ' + App.i18n.translateInline('Here you can create one.')
    )

App.Config.set('1000-SidebarCustomerDefault', App.SidebarCustomerDefault, 'TicketCreateSidebar')
