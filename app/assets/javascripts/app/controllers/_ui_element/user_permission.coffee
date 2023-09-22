# coffeelint: disable=camel_case_classes
class App.UiElement.user_permission
  @render: (attribute, params = {}) ->
    attribute.options = {}

    # get selectable roles and selected roles
    rolesRaw      = App.Role.search(sortBy: 'name')
    roles         = rolesRaw.filter (elem) -> elem.active
    rolesSelected = roles
      .filter (elem) -> _.include(params.role_ids, elem.id)
      .map (elem) -> elem.id

    # uniq and sort roles
    roles = _.indexBy(roles, 'name')
    roles = _.sortBy(roles, (i) -> return i.name)

    item = $( App.view('generic/user_permission')(
      attribute:     attribute
      roles:         roles
      params:        params
      rolesSelected: rolesSelected
    ) )

    # if customer, remove admin and agent
    item.find('[name=role_ids]')
      .on('change', (e) =>
        @checkUncheck($(e.currentTarget), item)
      )
      .trigger('change')

    item

  @checkUncheck: (element, item) ->
    checked = element.prop('checked')
    role_id = element.prop('value')
    return if !role_id
    role = App.Role.find(role_id)
    return if !role
    triggers = []

    # deselect conflicting roles
    if checked
      if role && role.preferences && role.preferences.not
        for notRole in role.preferences.not
          localRole = App.Role.findByAttribute('name', notRole)
          if localRole
            localElement = item.find("[name=role_ids][value=#{localRole.id}]")
            if localElement.prop('checked')
              if !confirm(App.i18n.translateInline('Role %s is conflicting with role %s, do you want to continue?', role.name, localRole.name, localRole.name))
                item.find("[name=role_ids][value=#{role_id}]").prop('checked', false)
                return
              item.localElement.prop('checked', false)
              triggers.push item.localElement

    for trigger in triggers
      trigger.trigger('change')
