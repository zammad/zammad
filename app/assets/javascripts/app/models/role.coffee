class App.Role extends App.Model
  @configure 'Role', 'name', 'permission_ids', 'group_ids', 'default_at_signup', 'note', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/roles'
  @configure_attributes = [
    { name: 'name',               display: 'Name',              tag: 'input',   type: 'text', limit: 100, null: false },
    { name: 'permission_ids',     display: 'Permissions',       tag: 'permission', item_class: 'checkbox' },
    { name: 'default_at_signup',  display: 'Default at Signup', tag: 'boolean', default: false, translate: true },
    { name: 'note',               display: 'Note',              tag: 'textarea', note: 'Notes are visible to agents only, never to customers.', limit: 250, null: true },
    { name: 'active',             display: 'Active',            tag: 'active',  default: true },
    { name: 'created_by_id',      display: 'Created by',        relation: 'User', readonly: 1 },
    { name: 'created_at',         display: 'Created',           tag: 'datetime', readonly: 1 },
    { name: 'updated_by_id',      display: 'Updated by',        relation: 'User', readonly: 1 },
    { name: 'updated_at',         display: 'Updated',           tag: 'datetime', readonly: 1 },
  ]
  @configure_clone = true
  @configure_overview = [
    'name', 'default_at_signup',
  ]

  activityMessage: (item) ->
    return if !item
    return if !item.created_by

    if item.type is 'create'
      return App.i18n.translateContent('%s created Role |%s|', item.created_by.displayName(), item.title)
    else if item.type is 'update'
      return App.i18n.translateContent('%s updated Role |%s|', item.created_by.displayName(), item.title)
    return "Unknow action for (#{@objectDisplayName()}/#{item.type}), extend activityMessage() of model."

  @_fillUp: (data) ->

    if data['permission_ids']
      data['permissions'] = []
      for permission_id in data['permission_ids']
        if App.Permission.exists(permission_id)
          permission = App.Permission.findNative(permission_id)
          data['permissions'].push permission

    data

  @withPermissions: (permissions) ->
    if !_.isArray(permissions)
      permissions = [permissions]

    roles = []
    for role in App.Role.all()
      found = false
      for permission in permissions
        id = App.Permission.findByAttribute('name', permission)?.id
        continue if !id
        continue if !_.contains(role.permission_ids, id)
        found = true
        break
      continue if !found
      roles.push(role)
    roles

