class App.User extends App.Model
  @configure 'User', 'login', 'firstname', 'lastname', 'email', 'web', 'password', 'phone', 'fax', 'mobile', 'street', 'zip', 'city', 'country', 'organization_id', 'department', 'note', 'role_ids', 'group_ids', 'active', 'invite', 'signup', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/users'

#  @hasMany 'roles', 'App.Role'
  @configure_attributes = [
    { name: 'login',            display: 'Login',         tag: 'input',    type: 'text',     limit: 100, null: false, autocapitalize: false, signup: false, quick: false },
    { name: 'firstname',        display: 'Firstname',     tag: 'input',    type: 'text',     limit: 100, null: false, signup: true, info: true, invite_agent: true, invite_customer: true },
    { name: 'lastname',         display: 'Lastname',      tag: 'input',    type: 'text',     limit: 100, null: false, signup: true, info: true, invite_agent: true, invite_customer: true },
    { name: 'email',            display: 'Email',         tag: 'input',    type: 'email',    limit: 100, null: false, signup: true, info: true, invite_agent: true, invite_customer: true },
    { name: 'organization_id',  display: 'Organization',  tag: 'select',   multiple: false, nulloption: true, null: true, relation: 'Organization', signup: false, info: true, invite_customer: true },
    { name: 'password',         display: 'Password',      tag: 'input',    type: 'password', limit: 50,  null: true, autocomplete: 'new-password', signup: true, },
    { name: 'note',             display: 'Note',          tag: 'textarea', note: 'Notes are visible to agents only, never to customers.', limit: 250, null: true, info: true, invite_customer: true },
    { name: 'role_ids',         display: 'Permissions',   tag: 'user_permission', null: false, invite_agent: true, invite_customer: true, item_class: 'checkbox' },
    { name: 'active',           display: 'Active',        tag: 'active',   default: true },
    { name: 'created_by_id',    display: 'Created by',    relation: 'User', readonly: 1 },
    { name: 'created_at',       display: 'Created at',    tag: 'datetime',  readonly: 1 },
    { name: 'updated_by_id',    display: 'Updated by',    relation: 'User', readonly: 1 },
    { name: 'updated_at',       display: 'Updated at',    tag: 'datetime',  readonly: 1 },
  ]
  @configure_overview = [
#    'login', 'firstname', 'lastname', 'email', 'updated_at',
    'login', 'firstname', 'lastname', 'organization'
  ]

  uiUrl: ->
    '#user/profile/' + @id

  icon: ->
    'user'

  initials: ->
    if @firstname && @lastname && @firstname[0] && @lastname[0]
      return @firstname[0] + @lastname[0]
    else if @firstname && @firstname[0] && !@lastname
      if @firstname[1]
        return @firstname[0] + @firstname[1]
      return @firstname[0]
    else if !@firstname && @lastname && @lastname[0]
      if @lastname[1]
        return @lastname[0] + @lastname[1]
      return @lastname[0]
    else if @email
      return @email[0] + @email[1]
    else
      return '??'

  avatar: (size = 40, placement = '', cssClass = '', unique = false, avatar, type = undefined) ->
    baseSize = 40
    size   = parseInt(size, 10)

    cssClass += ' ' if cssClass
    cssClass += "size-#{ size }"

    if @active is false
      cssClass += ' avatar--inactive'

    if @isOutOfOffice()
      cssClass += ' avatar--vacation'

    if placement
      placement = " data-placement='#{placement}'"

    if !avatar
      if type is 'personal'
        vip = false
        data = " data-id=\"#{@id}\""
      else
        cssClass += ' user-popover'
        data      = " data-id=\"#{@id}\""
    else
      vip = false
      data = " data-avatar-id=\"#{avatar.id}\""

    # set vip flag, ignore if personal avatar is request
    vip = @vip
    if type is 'personal'
      vip = false
    else
      cssClass += ' user-popover'

    # use system avatar for system actions
    if @id is 1
      return App.view('avatar_system')()

    # generate uniq avatar
    if !@image || @image is 'none' || unique
      width  = 300
      height = 226

      rng = new Math.seedrandom(@id)
      x   = rng() * (width - size)
      y   = rng() * (height - size)

      return App.view('avatar_unique')
        data: data
        cssClass: cssClass
        placement: placement
        vip: vip
        x: x * size/baseSize
        y: y * size/baseSize
        initials: @initials()

    # generate image based avatar
    return App.view('avatar')
      data: data
      cssClass: cssClass
      placement: placement
      vip: vip
      url: @imageUrl()

  isOutOfOffice: ->
    return false if @out_of_office isnt true
    start_time = @out_of_office_start_at
    return false if !start_time
    end_time = @out_of_office_end_at
    return false if !end_time
    start_time = new Date(Date.parse(start_time))
    end_time = new Date(Date.parse(end_time))
    now = new Date((new Date).toDateString())
    if start_time <= now && end_time >= now
      return true
    false

  imageUrl: ->
    return if !@image
    # set image url
    @constructor.apiPath + '/users/image/' + @image

  @_fillUp: (data) ->

    # set socal media links
    if data['accounts']
      for account of data['accounts']
        if account == 'twitter'
          data['accounts'][account]['link'] = 'https://twitter.com/' + data['accounts'][account]['username']
        if account == 'facebook'
          data['accounts'][account]['link'] = 'https://www.facebook.com/profile.php?id=' + data['accounts'][account]['uid']

    if data.organization_id
      data.organization = App.Organization.findNative(data.organization_id)

    if data['role_ids']
      data['roles'] = []
      for role_id in data['role_ids']
        if App.Role.exists(role_id)
          role = App.Role.findNative(role_id)
          data['roles'].push role

    if data['group_ids']
      data['groups'] = []
      for group_id in data['group_ids']
        if App.Group.exists(group_id)
          group = App.Group.findNative(group_id)
          data['groups'].push group

    data

  searchResultAttributes: ->
    display: "#{@displayName()}"
    id:      @id
    class:   'user user-popover'
    url:     @uiUrl()
    icon:    'user'

  activityMessage: (item) ->
    if item.type is 'create'
      return App.i18n.translateContent('%s created User |%s|', item.created_by.displayName(), item.title)
    else if item.type is 'update'
      return App.i18n.translateContent('%s updated User |%s|', item.created_by.displayName(), item.title)
    else if item.type is 'session started'
      return App.i18n.translateContent('%s started a new session', item.created_by.displayName())
    else if item.type is 'switch to'
      to = item.title
      if item.objectNative
        to = item.objectNative.displayName()
      return App.i18n.translateContent('%s switched to |%s|!', item.created_by.displayName(), to)
    else if item.type is 'ended switch to'
      to = item.title
      if item.objectNative
        to = item.objectNative.displayName()
      return App.i18n.translateContent('%s ended switch to |%s|!', item.created_by.displayName(), to)
    return "Unknow action for (#{@objectDisplayName()}/#{item.type}), extend activityMessage() of model."

  ###

    user = App.User.find(3)
    result = user.permission('ticket.agent') # access to certain permission key
    result = user.permission(['ticket.agent', 'ticket.customer']) # access to one of permission keys

    result = user.permission('user_preferences.calendar+ticket.agent') # access must have two permission keys

    result = user.permission('admin.*') # access if one sub key access exists

  returns

    true|false

  ###

  permission: (key) ->
    keys = key
    if !_.isArray(key)
      keys = [key]

    # if any permission exists
    return true if _.contains(keys, '*')

    # verify direct permissions
    for key in keys
      permission = App.Permission.findByAttribute('name', key)
      return false if permission && permission.active is false

    # get all permissions of user
    permissions = {}
    for role_id in @role_ids
      role = App.Role.findNative(role_id)
      if role.active is true
        for permission_id in role.permission_ids
          permission = App.Permission.findNative(permission_id)
          if !permission
            throw "No such permission for id #{permission_id}"
          if permission.active is true
            permissions[permission.name] = true

    for localKey in keys
      requiredPermissions = localKey.split('+')
      access = false
      for requiredPermission in requiredPermissions
        localAccess = false
        partString = ''
        parts = requiredPermission.split('.')

        # verify name.* permissions
        if parts[parts.length - 1] is '*'
          for permission_key, permission_value of permissions
            if permission_value is true
              length = requiredPermission.length - 1
              if permission_key.substr(0, length) is requiredPermission.substr(0, length)
                localAccess = true

        # verify name.explicite permissions
        if !localAccess
          for part in parts
            if partString isnt ''
              partString += '.'
            partString += part
            if permissions[partString]
              localAccess = true

        if localAccess
          access = true
        else
          access = false
          break
      return access if access
    false

  @outOfOfficeTextPlaceholder: ->
    today = new Date()
    outOfOfficeText = 'Christmas holiday'
    if today.getMonth() < 3
      outOfOfficeText = 'Easter holiday'
    else if today.getMonth() < 9
      outOfOfficeText = 'Summer holiday'
    outOfOfficeText

  outOfOfficeText: ->
    return @preferences.out_of_office_text if !_.isEmpty(@preferences.out_of_office_text)
    App.User.outOfOfficeTextPlaceholder()
