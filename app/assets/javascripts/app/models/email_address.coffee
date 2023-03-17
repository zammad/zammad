class App.EmailAddress extends App.Model
  @configure 'EmailAddress', 'realname', 'email', 'channel_id', 'note', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/email_addresses'

  displayName: ->
    if @realname
      # Do not use App.Utils.buildEmailAddress here because we don't build an email address and the
      #   quoting would confuse sorting in the GUI.
      return "#{@realname} <#{@email}>"
    @email

  @filterChannel: (options, type, params) ->
    return options if type isnt 'collection'

    localChannel = undefined
    if params && params.channel_id
      if App.Channel.exists(params.channel_id)
        localChannel = App.Channel.find(params.channel_id)

    _.filter(
      options
      (channel) ->
        return if !channel
        if localChannel
          return channel if channel.area is localChannel.area
        else
          return channel if channel.area is 'Google::Account' || channel.area is 'Microsoft365::Account' || channel.area is 'Email::Account'
    )

  @configure_attributes = [
    { name: 'realname',   display: __('Display name'),  tag: 'input', type: 'text', limit: 250, null: false },
    { name: 'email',      display: __('Email'),     tag: 'input', type: 'email', limit: 250, null: false },
    { name: 'channel_id', display: __('Channel'),   tag: 'select', multiple: false, null: true, relation: 'Channel', nulloption: true, filter: @filterChannel, do_not_log: true },
    { name: 'note',       display: __('Note'),      tag: 'textarea', note: __('Notes are visible to agents only, never to customers.'), limit: 250, null: true },
    { name: 'updated_at', display: __('Updated'),   tag: 'datetime', readonly: 1 },
    { name: 'active',     display: __('Active'),    tag: 'active',   readonly: 1 },
  ]
  @configure_overview = [
    'realname', 'email'
  ]
