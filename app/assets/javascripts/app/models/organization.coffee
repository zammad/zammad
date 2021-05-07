class App.Organization extends App.Model
  @configure 'Organization', 'name', 'shared', 'note', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/organizations'
  @configure_attributes = [
    { name: 'name',           display: 'Name',                tag: 'input',     type: 'text', limit: 100, null: false, info: true },
    { name: 'shared',         display: 'Shared organization', tag: 'boolean',   note: 'Customers in the organization can view each other items.', type: 'boolean', default: true, null: false, info: false },
    { name: 'created_by_id',  display: 'Created by',    relation: 'User', readonly: 1, info: false },
    { name: 'created_at',     display: 'Created at',    tag: 'datetime',  readonly: 1, info: false },
    { name: 'updated_by_id',  display: 'Updated by',    relation: 'User', readonly: 1, info: false },
    { name: 'updated_at',     display: 'Updated at',    tag: 'datetime',  readonly: 1, info: false },
  ]
  @configure_clone = true
  @configure_overview = [
    'name',
    'shared',
  ]

  @description = '''
Using **Organisations** you can **group** customers. This has among others two important benefits:

1. As an **Agent** you do not only have an overview of the open tickets for one person but an **overview over their whole organisation**.
2. As a **Customer** you can also check the **Tickets which your colleagues created** and modify their tickets (if your organization is set to "shared", which can be defined per organization).
'''

  uiUrl: ->
    "#organization/profile/#{@id}"

  icon: ->
    'organization'

  @_fillUp: (data) ->

    # add users of organization
    if data['member_ids']
      data['members'] = []
      for user_id in data['member_ids']
        if App.User.exists(user_id)
          user = App.User.findNative(user_id)
          data['members'].push user
    data

  searchResultAttributes: ->
    display:    "#{@displayName()}"
    id:         @id
    class:      'organization organization-popover'
    url:        @uiUrl()
    icon:       'organization'

  activityMessage: (item) ->
    return if !item
    return if !item.created_by

    if item.type is 'create'
      return App.i18n.translateContent('%s created Organization |%s|', item.created_by.displayName(), item.title)
    else if item.type is 'update'
      return App.i18n.translateContent('%s updated Organization |%s|', item.created_by.displayName(), item.title)
    return "Unknow action for (#{@objectDisplayName()}/#{item.type}), extend activityMessage() of model."
