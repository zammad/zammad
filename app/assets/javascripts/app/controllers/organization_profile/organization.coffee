class App.OrganizationProfileOrganization extends App.ControllerObserver
  model: 'Organization'
  observe:
    name: true

  render: (organization) =>
    @html App.Utils.htmlEscape(organization.displayName())
