class App.UserProfileUser extends App.ControllerObserver
  model: 'User'
  observe:
    firstname: true
    lastname: true
    organization_id: true
    image: true

  render: (user) =>
    if user.organization_id
      new App.UserProfileOrganization(
        object_id: user.organization_id
        el: @el.siblings('.js-organization')
      )

    @html App.view('user_profile/name')(
      user: user
    )
