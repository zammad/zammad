class App.EmailAddress extends App.Model
  @configure 'EmailAddress', 'realname', 'email', 'channel_id', 'note', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/email_addresses'

  @filterChannel: (options, type) ->
    return options if type isnt 'collection'
    _.filter(
      options
      (channel) ->
        return channel if channel && channel.area is 'Email::Account'
    )

  @configure_attributes = [
    { name: 'realname',   display: 'Display name',  tag: 'input', type: 'text', limit: 250, null: false },
    { name: 'email',      display: 'Email',     tag: 'input', type: 'email', limit: 250, null: false },
    { name: 'channel_id', display: 'Channel',   tag: 'select', multiple: false, null: true, relation: 'Channel', nulloption: true, filter: @filterChannel, do_not_log: true },
    { name: 'note',       display: 'Note',      tag: 'textarea', note: 'Notes are visible to agents only, never to customers.', limit: 250, null: true },
    { name: 'updated_at', display: 'Updated',   tag: 'datetime', readonly: 1 },
    { name: 'active',     display: 'Active',    tag: 'active',   readonly: 1 },
  ]
  @configure_overview = [
    'realname', 'email'
  ]
