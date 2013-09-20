class App.Organization extends App.Model
  @configure 'Organization', 'name', 'shared', 'note', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/organizations'
  @configure_attributes = [
    { name: 'name',       display: 'Name',                tag: 'input',     type: 'text', limit: 100, 'null': false, 'class': 'span4' },
    { name: 'shared',     display: 'Shared organiztion',  tag: 'boolean',   note: 'Customers in the organiztion can view each other items.', type: 'boolean', 'default': true, 'null': false, 'class': 'span4' },
    { name: 'note',       display: 'Note',                tag: 'textarea',  note: 'Notes are visible to agents only, never to customers.', limit: 250, 'null': true, 'class': 'span4' },
    { name: 'updated_at', display: 'Updated',             type: 'time', readonly: 1 },
    { name: 'active',     display: 'Active',              tag: 'boolean',   note: 'boolean', 'default': true, 'null': false, 'class': 'span4' },
  ]
  @configure_overview = [
    'name',
    'shared',
  ]

  @_fillUp: (data) ->

    # addd users of organization
    if data['user_ids']
      data['user_ids'] = []
      for user_id in data['user_ids']
        if App.User.exists( user_id )
          user = App.User.find( user_id )
          data['user_ids'].push user
    data