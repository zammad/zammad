class App.Organization extends App.Model
  @configure 'Organization', 'name', 'shared', 'note', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/organizations'
  @configure_attributes = [
    { name: 'name',       display: 'Name',                tag: 'input',     type: 'text', limit: 100, null: false, info: true },
    { name: 'shared',     display: 'Shared organization', tag: 'boolean',   note: 'Customers in the organization can view each other items.', type: 'boolean', default: true, null: false, info: false },
    { name: 'note',       display: 'Note',                tag: 'textarea',  note: 'Notes are visible to agents only, never to customers.', limit: 250, null: true, info: true },
    { name: 'updated_at', display: 'Updated',             tag: 'datetime',  readonly: 1, info: false },
    { name: 'active',     display: 'Active',              tag: 'boolean',   default: true, null: false, info: false },
  ]
  @configure_overview = [
    'name',
    'shared',
  ]

  uiUrl: ->
    '#organization/profile/' + @id

  icon: (user) ->
    "organization icon"

  @_fillUp: (data) ->

    # addd users of organization
    if data['member_ids']
      data['members'] = []
      for user_id in data['member_ids']
        if App.User.exists( user_id )
          user = App.User.find( user_id )
          data['members'].push user
    data
