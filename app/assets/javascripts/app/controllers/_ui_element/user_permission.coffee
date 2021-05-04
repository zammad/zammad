# coffeelint: disable=camel_case_classes
class App.UiElement.user_permission
  @render: (attribute, params = {}) ->
    attribute.options = {}

    # take defaults users selected, select all groups
    if _.isEmpty(params.group_ids) && _.isEmpty(params.role_ids) && !_.isEmpty(attribute.value)
      params.role_ids = attribute.value
      selectAllGroups = false
      for localRoleId in params.role_ids
        role = App.Role.find(localRoleId)
        if role
          for permission_id in role.permission_ids
            localPermission = App.Permission.find(permission_id)
            if localPermission
              if localPermission.name is 'ticket.agent'
                selectAllGroups = true
                break
      if selectAllGroups
        params.group_ids = []
        groupsRaw = App.Group.search(sortBy: 'name')
        for group in groupsRaw
          params.group_ids.push group.id

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

    # get roles with group plugin
    rolesWithGroupPlugin = {}
    for role in rolesRaw
      if role.active
        for permission_id in role.permission_ids
          localPermission = App.Permission.find(permission_id)
          if localPermission && localPermission.preferences && _.contains(localPermission.preferences.plugin, 'groups')
            rolesWithGroupPlugin[role.id] = 'group'

    # uniq and sort roles
    roles = _.indexBy(roles, 'name')
    roles = _.sortBy(roles, (i) -> return i.name)

    item = $( App.view('generic/user_permission')(
      attribute: attribute
      roles: roles
      params: params
      rolesSelected: rolesSelected
    ) )

    item.find('.js-groups').html(App.view('generic/user_permission_group')(
      attribute: attribute
      groups: groups
      params: params
      groupsSelected: groupsSelected
      hideGroups: hideGroups
      groupAccesses: App.Group.accesses()
    ) )

    throttled = _.throttle( (e) ->
      input = $(@).find('input')
      upcoming_state = !input.prop('checked')
      value = input.val()

      if value is 'full' and upcoming_state is true
        $(@).closest('tr').find('input:not([value=full])').prop('checked', false)
      else if value isnt 'full' and upcoming_state is true
        $(@).closest('tr').find('input[value=full]').prop('checked', false)
    , 300, { trailing: false })

    item.on('click', '.checkbox-replacement', throttled)

    # if customer, remove admin and agent
    item.find('[name=role_ids]').bind('change', (e) =>
      @checkUncheck($(e.currentTarget), rolesWithGroupPlugin, item, hideGroups)
    )
    item.find('[name=role_ids]').trigger('change')
    item

  @checkUncheck: (element, rolesWithGroupPlugin, item, hideGroups) ->
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

    # if role with groups plugin is deselected, hide group selection
    if !checked
      selectedRoleIds = []
      item.find('input[name=role_ids]:checked').each( ->
        selectedRoleIds.push($(@).val())
      )

      show = false
      for role_id, group of rolesWithGroupPlugin
        if _.contains(selectedRoleIds, role_id.toString())
          show = true
          break
      if !show
        item.find('.js-groupList').addClass('hidden')

        # select groups if only one is available
        if hideGroups
          item.find('.js-groupList .js-groupListItem[value=full]').prop('checked', false)
      return

    # if role with groups plugin is selected, show group selection
    if rolesWithGroupPlugin[role_id] is 'group'
      item.find('.js-groupList:not(.js-groupListHide)').removeClass('hidden')

      # select groups if only one is available
      if hideGroups
        item.find('.js-groupList .js-groupListItem[value=full]').prop('checked', true)

    for trigger in triggers
      trigger.trigger('change')
