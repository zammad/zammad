class App.OrganizationProfileActionRow extends App.ControllerObserverActionRow
  model: 'Organization'
  observe:
    member_ids: true

  showHistory: (organization) =>
    new App.OrganizationHistory(
      organization_id: organization.id
      container: @el.closest('.content')
    )

  editOrganization: (organization) =>
    new App.ControllerGenericEdit(
      id: organization.id
      genericObject: 'Organization'
      screen: 'edit'
      pageData:
        title: __('Organizations')
        object: __('Organization')
        objects: __('Organizations')
      container: @el.closest('.content')
    )

  actions: (organization) =>
    actions = [
      {
        name:     'history'
        title:    __('History')
        callback: @showHistory
      }
    ]

    if organization.isAccessibleBy(App.User.current(), 'change')
      actions.unshift {
        name:     'edit'
        title:    __('Edit')
        callback: @editOrganization
      }

    actions
