class SidebarOrganization extends App.Controller
  sidebarItem: =>
    return if !@permissionCheck('ticket.agent')

    # use ticket organization id or customer user organization id as fallback
    @organization_id = @params.organization_id || App.User.find(@params.customer_id)?.organization_id
    return if !@organization_id

    @item = {
      name: 'organization'
      badgeIcon: 'group'
      sidebarHead: __('Organization')
      sidebarCallback: @showOrganization
      sidebarActions: []
    }

    if @organization_id && App.Organization.exists(@organization_id)
      organization = App.Organization.find(@organization_id)
      if organization?.isAccessibleBy(App.User.current(), 'change')
        @item.sidebarActions.push {
          title:    __('Edit Organization')
          name:     'organization-edit'
          callback: @editOrganization
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
