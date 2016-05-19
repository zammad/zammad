# coffeelint: disable=camel_case_classes
class App.UiElement.user_permission
  @render: (attribute, params = {}) ->
    attribute.options = {}

    # get selectable roles and selected roles
    roles = []
    rolesSelected = {}
    rolesRaw = App.Role.search(sortBy: 'name')
    for role in rolesRaw
      if role.active
        roles.push role
        if params.role_ids
          for role_id in params.role_ids
            if role_id.toString() is role.id.toString()
              rolesSelected[role.id] = true

    # get selectable groups and selected groups
    groups = []
    groupsSelected = {}
    groupsRaw = App.Group.search(sortBy: 'name')
    for group in groupsRaw
      if group.active
        groups.push group
        if params.group_ids
          for group_id in params.group_ids
            if group_id.toString() is group.id.toString()
              groupsSelected[group.id] = true

    # if only one group is selectable, hide all groups
    hideGroups = false
    if groups.length <= 1
      hideGroups = true

    if attribute.hideMode
      if attribute.hideMode.rolesSelected
        roles = []
        rolesSelected = {}
        for roleName in attribute.hideMode.rolesSelected
          role = App.Role.findByAttribute('name', roleName)
          if role
            roles.push role
            rolesSelected[role.id] = true
      if attribute.hideMode.rolesNot
        for roleRaw in rolesRaw
          hit = false
          for roleName in attribute.hideMode.rolesNot
            if roleRaw.active && roleRaw.name is roleName
              hit = true
          if !hit
            roles.push roleRaw

    # if agent is on new users selected, select all groups
    if _.isEmpty(attribute.value)
      agentRole = App.Role.findByAttribute('name', 'Agent')
      if rolesSelected[agentRole.id]
        for group in groups
          groupsSelected[group.id] = true

    # uniq and sort roles
    roles = _.indexBy(roles, 'name')
    roles = _.sortBy(roles, (i) -> return i.name)

    item = $( App.view('generic/user_permission')(
      attribute: attribute
      roles: roles
      groups: groups
      params: params
      rolesSelected: rolesSelected
      groupsSelected: groupsSelected
      hideGroups: hideGroups
    ) )

    getCurrentRoles = ->
      currentRoles = []
      item.find('[name=role_ids]').each( ->
        element = $(@)
        checked = element.prop('checked')
        return if !checked
        role_id = element.prop('value')
        role = App.Role.find(role_id)
        return if !role
        currentRoles.push role
      )
      currentRoles

    # if customer, remove admin and agent
    item.find('[name=role_ids]').bind('change', (e) ->
      element = $(e.currentTarget)
      checked = element.prop('checked')
      role_id = element.prop('value')
      return if !role_id
      role = App.Role.find(role_id)
      return if !role

      # if agent got deselected
      # - hide groups
      if !checked
        if role.name is 'Agent'
          item.find('.js-groupList').addClass('hidden')
        return

      # if agent is selected
      # - show groups
      if role.name is 'Agent'
        item.find('.js-groupList:not(.js-groupListHide)').removeClass('hidden')

      # if role customer is selected
      # - deselect agent & admin
      # - hide groups
      if role.name is 'Customer'
        for currentRole in getCurrentRoles()
          if currentRole.name is 'Admin' || currentRole.name is 'Agent'
            item.find("[name=role_ids][value=#{currentRole.id}]").prop('checked', false)
        item.find('.js-groupList').addClass('hidden')

      # if role agent or admin is selected
      # - deselect customer
      else if role.name is 'Agent' || role.name is 'Admin'
        for currentRole in getCurrentRoles()
          if currentRole.name is 'Customer'
            item.find("[name=role_ids][value=#{currentRole.id}]").prop('checked', false)
    )

    item
