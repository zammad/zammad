class App.ControllerFormOrganization extends App.ControllerForm
  constructor: (params) ->
    @user = App.User.find(App.Session.get('id'))
    @organizations = []
    if @user.organization_id
      @organizations.push @user.organization_id
    if @user.organization_ids
      @organizations = @organizations.concat @user.organization_ids
    params['filter']['organization_id'] = @organizations
    super