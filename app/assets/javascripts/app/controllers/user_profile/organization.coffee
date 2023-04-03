class App.UserProfileOrganization extends App.ControllerObserver
  model: 'Organization'
  observe:
    name: true

  render: (organization) =>
    @html App.view('user_profile/organization')(
      organization: organization
    )
