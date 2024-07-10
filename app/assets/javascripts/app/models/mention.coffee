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

  @findCurrentUserTicketMention: (ticket_id) ->
    current_user_id = App.Session.get('id')
    _.find(App.Mention.findAllByAttribute('mentionable_id', ticket_id), (mention) ->
      mention.mentionable_type is 'Ticket' && mention.user_id is current_user_id
    )

  @createCurrentUserTicketMention: (ticket_id) ->
    return if @findCurrentUserTicketMention(ticket_id)

    (new App.Mention).load(
      mentionable_type: 'Ticket'
      mentionable_id: ticket_id
    ).save()

  @destroyCurrentUserTicketMention: (ticket_id) ->
    @findCurrentUserTicketMention(ticket_id)?.destroy()
