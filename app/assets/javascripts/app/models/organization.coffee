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

  members: (offset, limit, callback) ->
    member_ids         = @member_ids.slice(offset, limit)
    missing_member_ids = _.filter(member_ids, (id) -> !App.User.findNative(id))

    userResult = ->
      users = []
      for user_id in member_ids
        user = App.User.find(user_id)
        continue if !user
        users.push(user)
      return users

    return callback(userResult()) if missing_member_ids.length < 1

    App.Ajax.request(
      type: 'POST'
      url: "#{@constructor.apiPath}/users/search"
      data: JSON.stringify(
        query: '*'
        ids: missing_member_ids
        limit: limit
        full:  true
      )
      processData: true,
      success: (data, status, xhr) ->
        App.Collection.loadAssets(data.assets)
        callback(userResult())
      error: (data, status) ->
        callback([])
    )

  searchResultAttributes: ->
    classList = ['organization', 'organization-popover' ]
    icon = 'organization'

    if @active is false
      classList.push 'is-inactive'
      icon = 'inactive-' + icon

    display:    "#{@displayName()}"
    id:         @id
    class:      classList.join(' ')
    url:        @uiUrl()
    icon:       icon

  activityMessage: (item) ->
    return if !item
    return if !item.created_by

    if item.type is 'create'
      return App.i18n.translateContent('%s created Organization |%s|', item.created_by.displayName(), item.title)
    else if item.type is 'update'
      return App.i18n.translateContent('%s updated Organization |%s|', item.created_by.displayName(), item.title)
    return "Unknow action for (#{@objectDisplayName()}/#{item.type}), extend activityMessage() of model."
