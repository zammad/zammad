class App.UserProfileOrganization extends App.ControllerObserver
  @extend App.PopoverProvidable
  @registerPopovers 'Organization'

  model: 'Organization'
  observe:
    name: true

  render: (organization) =>
    @html App.view('user_profile/organization')(
      organization: organization
    )

    @renderPopovers()
