class SidebarTemplate extends App.Controller
  sidebarItem: =>
    return if !@permissionCheck('ticket.agent')
    {
      head:    'Templates'
      name:    'template'
      icon:    'templates'
      actions: []
      callback: @showTemplates
    }

  showTemplates: (el) =>
    @el = el

    # show template UI
    new App.WidgetTemplate(
      el:          el
      #template_id: template['id']
    )

App.Config.set('100-Template', SidebarTemplate, 'TicketCreateSidebar')
