class App.OrganizationProfileOrganizationAvatar extends App.ControllerObserver
  model: 'Organization'
  observe:
    active: true
    vip: true

  render: (organization) =>
    @html organization.avatar('80')
