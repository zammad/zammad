class SidebarOrganization extends App.Controller
  sidebarItem: =>
    return if !@ticket.organization_id

    actions = []
    if @permissionCheck('ticket.agent')
      actions = [
        {
          title:    __('Edit Organization')
          name:     'organization-edit'
          callback: @editOrganization
        },
      ]

    @item = {
      name: 'organization'
      badgeIcon: 'group'
      sidebarHead: __('Organization')
      sidebarCallback: @showOrganization
      sidebarActions: actions
    }
    @item

  showOrganization: (el) =>
    @elSidebar = el
    new App.WidgetOrganization(
      el:              @elSidebar
      organization_id: @ticket.organization_id
    )

  editOrganization: =>
    new App.ControllerGenericEdit(
      id: @ticket.organization_id,
      genericObject: 'Organization'
      pageData:
        title:   __('Organizations')
        object:  __('Organization')
        objects: __('Organizations')
      container: @elSidebar.closest('.content')
    )

App.Config.set('300-Organization', SidebarOrganization, 'TicketZoomSidebar')
