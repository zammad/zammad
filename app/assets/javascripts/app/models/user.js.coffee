class App.User extends App.Model
  @configure 'User', 'login', 'firstname', 'lastname', 'email', 'web', 'password', 'phone', 'fax', 'mobile', 'street', 'zip', 'city', 'country', 'organization_id', 'department', 'note', 'role_ids', 'group_ids', 'active', 'invite', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/users'

#  @hasMany 'roles', 'App.Role'
  @configure_attributes = [
    { name: 'login',            display: 'Login',         tag: 'input',    type: 'text',     limit: 100, null: false, class: 'span4', autocapitalize: false, signup: false, quick: false },
    { name: 'firstname',        display: 'Firstname',     tag: 'input',    type: 'text',     limit: 100, null: false, class: 'span4', signup: true, quick: true, info: true, invite_agent: true },
    { name: 'lastname',         display: 'Lastname',      tag: 'input',    type: 'text',     limit: 100, null: false, class: 'span4', signup: true, quick: true, info: true, invite_agent: true },
    { name: 'email',            display: 'Email',         tag: 'input',    type: 'email',    limit: 100, null: false, class: 'span4', signup: true, quick: true, info: true, invite_agent: true },
    { name: 'web',              display: 'Web',           tag: 'input',    type: 'url',      limit: 100, null: true,  class: 'span4', signup: false, quick: true, info: true },
    { name: 'phone',            display: 'Phone',         tag: 'input',    type: 'phone',    limit: 100, null: true,  class: 'span4', signup: false, quick: true, info: true },
    { name: 'mobile',           display: 'Mobile',        tag: 'input',    type: 'phone',    limit: 100, null: true,  class: 'span4', signup: false, quick: true, info: true },
    { name: 'fax',              display: 'Fax',           tag: 'input',    type: 'phone',    limit: 100, null: true,  class: 'span4', signup: false, quick: true, info: true },
    { name: 'organization_id',  display: 'Organization',  tag: 'select',   multiple: false, nulloption: true, null: true, relation: 'Organization', class: 'span4', signup: false, quick: true, info: true },
    { name: 'department',       display: 'Department',    tag: 'input',    type: 'text',    limit: 200, null: true,  class: 'span4', signup: false, quick: true, info: true },
    { name: 'street',           display: 'Street',        tag: 'input',    type: 'text',    limit: 100, null: true,  class: 'span4', signup: false, quick: true, info: true },
    { name: 'zip',              display: 'Zip',           tag: 'input',    type: 'text',    limit: 100, null: true,  class: 'span4', signup: false, quick: true, info: true },
    { name: 'city',             display: 'City',          tag: 'input',    type: 'text',    limit: 100, null: true,  class: 'span4', signup: false, quick: true, info: true },
    { name: 'password',         display: 'Password',      tag: 'input',    type: 'password', limit: 50,  null: true, autocomplete: 'off', class: 'span4', signup: true,  quick: false },
    { name: 'note',             display: 'Note',          tag: 'textarea', note: 'Notes are visible to agents only, never to customers.', limit: 250, null: true, class: 'span4', quick: true, info: true },
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
    '#user/zoom/' + @id

  icon: (user) ->
    "user icon"

  @_fillUp: (data) ->

    # set socal media links
    if data['accounts']
      for account of data['accounts']
        if account == 'twitter'
          data['accounts'][account]['link'] = 'http://twitter.com/' + data['accounts'][account]['username']
        if account == 'facebook'
          data['accounts'][account]['link'] = 'https://www.facebook.com/profile.php?id=' + data['accounts'][account]['uid']

    # set image url
    data.image = @apiPath + '/users/image/' + data.image

    if data.organization_id
      data.organization = App.Organization.find(data.organization_id)

    data

