class App.User extends App.Model
  @configure 'User', 'login', 'firstname', 'lastname', 'email', 'web', 'password', 'phone', 'fax', 'mobile', 'street', 'zip', 'city', 'country', 'organization_id', 'department', 'note', 'role_ids', 'group_ids', 'active', 'invite', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/users'

#  @hasMany 'roles', 'App.Role'
  @configure_attributes = [
    { name: 'login',            display: 'Login',         tag: 'input',    type: 'text',     limit: 100, null: false, class: 'span4', autocapitalize: false, signup: false, quick: false },
    { name: 'firstname',        display: 'Firstname',     tag: 'input',    type: 'text',     limit: 100, null: false, class: 'span4', signup: true, info: true, invite_agent: true },
    { name: 'lastname',         display: 'Lastname',      tag: 'input',    type: 'text',     limit: 100, null: false, class: 'span4', signup: true, info: true, invite_agent: true },
    { name: 'email',            display: 'Email',         tag: 'input',    type: 'email',    limit: 100, null: false, class: 'span4', signup: true, info: true, invite_agent: true },
    { name: 'web',              display: 'Web',           tag: 'input',    type: 'url',      limit: 100, null: true,  class: 'span4', signup: false, info: true },
    { name: 'phone',            display: 'Phone',         tag: 'input',    type: 'phone',    limit: 100, null: true,  class: 'span4', signup: false, info: true },
    { name: 'mobile',           display: 'Mobile',        tag: 'input',    type: 'phone',    limit: 100, null: true,  class: 'span4', signup: false, info: true },
    { name: 'fax',              display: 'Fax',           tag: 'input',    type: 'phone',    limit: 100, null: true,  class: 'span4', signup: false, info: true },
    { name: 'organization_id',  display: 'Organization',  tag: 'select',   multiple: false, nulloption: true, null: true, relation: 'Organization', class: 'span4', signup: false, info: true },
    { name: 'department',       display: 'Department',    tag: 'input',    type: 'text',    limit: 200, null: true,  class: 'span4', signup: false, info: true },
    { name: 'street',           display: 'Street',        tag: 'input',    type: 'text',    limit: 100, null: true,  class: 'span4', signup: false, info: true },
    { name: 'zip',              display: 'Zip',           tag: 'input',    type: 'text',    limit: 100, null: true,  class: 'span4', signup: false, info: true },
    { name: 'city',             display: 'City',          tag: 'input',    type: 'text',    limit: 100, null: true,  class: 'span4', signup: false, info: true },
    { name: 'password',         display: 'Password',      tag: 'input',    type: 'password', limit: 50,  null: true, autocomplete: 'off', class: 'span4', signup: true, },
    { name: 'note',             display: 'Note',          tag: 'textarea', note: 'Notes are visible to agents only, never to customers.', limit: 250, null: true, class: 'span4', info: true },
    { name: 'role_ids',         display: 'Roles',         tag: 'checkbox', multiple: true, null: false, relation: 'Role', class: 'span4' },
    { name: 'group_ids',        display: 'Groups',        tag: 'checkbox', multiple: true, null: true, relation: 'Group', class: 'span4', invite_agent: true },
    { name: 'active',           display: 'Active',        tag: 'boolean',  default: true, null: true, class: 'span4' },
    { name: 'updated_at',       display: 'Updated',       type: 'time',    readonly: 1 },
  ]
  @configure_overview = [
#    'login', 'firstname', 'lastname', 'email', 'updated_at',
    'login', 'firstname', 'lastname',
  ]

  uiUrl: ->
    '#user/profile/' + @id

  icon: (user) ->
    "user icon"

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

  avatar: (size = 40, placement = '', cssClass = '') ->
    cssClass += " size-#{ size }"

    if placement
      placement = "data-placement=\"#{placement}\""

    if !@image || @image is 'none'
      return @uniqueAvatar(size, placement, cssClass)
    else
      if @vip
        cssClass += "#{cssClass} vip"
      "<span class=\"avatar user-popover #{cssClass}\" data-id=\"#{@id}\" style=\"background-image: url(#{ @imageUrl })\" #{placement}></span>"

  uniqueAvatar: (size = 40, placement = '', cssClass = '', avatar) ->
    if size
      cssClass += " size-#{ size }"

    width  = 300
    height = 226
    size   = parseInt(size, 10)

    rng = new Math.seedrandom(@id)
    x   = rng() * (width - size)
    y   = rng() * (height - size)

    if !avatar
      cssClass += "#{cssClass} user-popover"
      data      = "data-id=\"#{@id}\""
    else
      data      = "data-avatar-id=\"#{avatar.id}\""

    if @vip
      cssClass += "#{cssClass} vip"
    "<span class=\"avatar unique #{cssClass}\" #{data} style=\"background-position: -#{ x }px -#{ y }px;\" #{placement}>#{ @initials() }</span>"

  @_fillUp: (data) ->

    # set socal media links
    if data['accounts']
      for account of data['accounts']
        if account == 'twitter'
          data['accounts'][account]['link'] = 'http://twitter.com/' + data['accounts'][account]['username']
        if account == 'facebook'
          data['accounts'][account]['link'] = 'https://www.facebook.com/profile.php?id=' + data['accounts'][account]['uid']

    # set image url
    data.imageUrl = @apiPath + '/users/image/' + data.image

    if data.organization_id
      data.organization = App.Organization.find(data.organization_id)

    if data['role_ids']
      data['roles'] = []
      for role_id in data['role_ids']
        if App.Role.exists( role_id )
          role = App.Role.find( role_id )
          data['roles'].push role

    if data['group_ids']
      data['groups'] = []
      for group_id in data['group_ids']
        if App.Group.exists( group_id )
          group = App.Group.find( group_id )
          data['groups'].push group

    data
