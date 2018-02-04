class SidebarTemplate extends App.Controller
  sidebarItem: =>
    return if !@permissionCheck('ticket.agent')
    @item = {
      name: 'template'
      badgeIcon: 'templates'
      badgeCallback: @badgeRender
      sidebarHead: 'Templates'
      sidebarActions: []
      sidebarCallback: @showTemplates
    }
    @item

  showTemplates: (el) =>
    @el = el

    # show template UI
    new App.WidgetTemplate(
      el:          el
      #template_id: template['id']
    )

App.Config.set('100-Template', SidebarTemplate, 'TicketCreateSidebar')
