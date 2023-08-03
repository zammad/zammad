class App.WidgetOrganizationAvatar extends App.ControllerObserver
  @extend App.PopoverProvidable
  @registerPopovers 'Organization'

  model: 'Organization'
  observe:
    name: true
    vip: true
    active: true

  globalRerender: false

  render: (organization) =>
    @html(organization.avatar(@size, @cssClass, true))
    @renderPopovers()
