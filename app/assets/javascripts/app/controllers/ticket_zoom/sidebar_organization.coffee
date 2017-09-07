class SidebarOrganization extends App.Controller
  sidebarItem: =>
    return if !@permissionCheck('ticket.agent')
    return if !@ticket.organization_id
    {
      head: 'Organization'
      name: 'organization'
      icon: 'group'
      actions: [
        {
          title:    'Edit Organization'
          name:     'organization-edit'
          callback: @editOrganization
        },
      ]
      callback: @showOrganization
    }

  showOrganization: (el) =>
    @el = el
    new App.WidgetOrganization(
      el:              @el
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
      container: @el.closest('.content')
    )

App.Config.set('300-Organization', SidebarOrganization, 'TicketZoomSidebar')
