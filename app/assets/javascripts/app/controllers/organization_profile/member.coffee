class App.OrganizationProfileMember extends App.ControllerObserver
  @extend App.PopoverProvidable
  @registerPopovers 'User'

  model: 'User'
  observe:
    firstname: true
    lastname: true
    login: true
    email: true
    active: true
    image: true
  globalRerender: false

  render: (user) =>
    @html App.view('organization_profile/member')(
      user: user
    )

    @renderPopovers()
