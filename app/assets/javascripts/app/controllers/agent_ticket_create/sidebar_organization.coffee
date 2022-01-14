class SidebarOrganization extends App.Controller
  sidebarItem: =>
    return if !@permissionCheck('ticket.agent')
    return if !@params.customer_id
    return if !App.User.exists(@params.customer_id)
    customer = App.User.find(@params.customer_id)
    @organization_id = customer.organization_id
    return if !@organization_id
    @item = {
      name: 'organization'
      badgeIcon: 'group'
      sidebarHead: __('Organization')
      sidebarCallback: @showOrganization
      sidebarActions: [
        {
          title:    __('Edit Organization')
          name:     'organization-edit'
          callback: @editOrganization
        },
      ]
    }
    @item

  showOrganization: (el) =>
    @elSidebar = el
    new App.WidgetOrganization(
      el:              @elSidebar
      organization_id: @organization_id
    )

  editOrganization: =>
    new App.ControllerGenericEdit(
      id: @organization_id,
      genericObject: 'Organization'
      pageData:
        title:   __('Organizations')
        object:  __('Organization')
        objects: __('Organizations')
      container: @elSidebar.closest('.content')
    )

App.Config.set('300-Organization', SidebarOrganization, 'TicketCreateSidebar')
