class App.Mention extends App.Model
  @configure 'Mention', 'mentionable_id', 'mentionable_type'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/mentions'
  @configure_attributes = [
    { name: 'user_id', display: __('User'), tag: 'select',   multiple: false, limit: 100, null: true, relation: 'User', width: '12%', edit: true },
  ]

  @searchUser: (query, group_id, callback) ->
    roles    = App.Role.withPermissions('ticket.agent')
    role_ids = roles.map (role) -> role.id

    group_ids = {}
    group_ids[group_id] = 'read'

    App.Ajax.request(
      id: 'mention_search_user'
      type: 'GET'
      url:  "#{@apiPath}/users/search"
      data:
        limit: 10
        query: query
        role_ids: role_ids
        group_ids: group_ids
        full: true
      processData: true
      success: (data, status, xhr) ->
        if data.assets
          App.Collection.loadAssets(data.assets, targetModel: @className)
        callback(data)
    )
