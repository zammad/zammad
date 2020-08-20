class SidebarOrganization extends App.Controller
  sidebarItem: =>
    return if @ticket.currentView() isnt 'agent'
    return if !@ticket.organization_id
    @item = {
      name: 'organization'
      badgeIcon: 'group'
      sidebarHead: 'Organization'
      sidebarCallback: @showOrganization
      sidebarActions: [
        {
          title:    'Edit Organization'
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
      organization_id: @ticket.organization_id
    )

  editOrganization: =>
    new App.ControllerGenericEdit(
      id: @ticket.organization_id,
      genericObject: 'Organization'
      pageData:
        title:   'Organizations'
        object:  'Organization'
        objects: 'Organizations'
      container: @elSidebar.closest('.content')
    )

App.Config.set('300-Organization', SidebarOrganization, 'TicketZoomSidebar')
