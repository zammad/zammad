class ChannelTwitter extends App.ControllerSubContent
  requiredPermission: 'admin.channel_twitter'
  events:
    'click .js-new':       'new'
    'click .js-edit':      'edit'
    'click .js-delete':    'delete'
    'click .js-configApp': 'configApp'
    'click .js-disable':   'disable'
    'click .js-enable':    'enable'

  constructor: ->
    super

    #@interval(@load, 60000)
    @load()

  load: =>
    @startLoading()
    @ajax(
      id:   'twitter_index'
      type: 'GET'
      url:  "#{@apiPath}/channels_twitter"
      processData: true
      success: (data, status, xhr) =>
        @stopLoading()
        App.Collection.loadAssets(data.assets)
        @callbackUrl = data.callback_url
        @render(data)
    )

  render: (data) =>

    # if no twitter app is registered, show intro
    external_credential = App.ExternalCredential.findByAttribute('name', 'twitter')
    if !external_credential
      @html App.view('twitter/index')()
      return

    channels = []
    for channel_id in data.channel_ids
      channel = App.Channel.find(channel_id)
      if channel && channel.options && channel.options.sync && channel.options.sync.search
        for search in channel.options.sync.search
          displayName = '-'
          if search.group_id
            group = App.Group.find(search.group_id)
            displayName = group.displayName()
          search.groupName = displayName
      if channel && channel.options && channel.options.sync && channel.options.sync.mentions
        displayName = '-'
        if channel.options.sync.mentions.group_id
          group = App.Group.find(channel.options.sync.mentions.group_id)
          displayName = group.displayName()
        channel.options.sync.mentions.groupName = displayName
      if channel && channel.options && channel.options.sync && channel.options.sync.direct_messages
        displayName = '-'
        if channel.options.sync.direct_messages.group_id
          group = App.Group.find(channel.options.sync.direct_messages.group_id)
          displayName = group.displayName()
        channel.options.sync.direct_messages.groupName = displayName
      channels.push channel
    @html App.view('twitter/list')(
      channels: channels
      external_credential: external_credential
    )

    if @channel_id
      @edit(undefined, @channel_id)
      @channel_id = undefined

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

  configApp: =>
    new AppConfig(
      container: @el.parents('.content')
      callbackUrl: @callbackUrl
      load: @load
    )

  new: (e) ->
    window.location.href = "#{@apiPath}/external_credentials/twitter/link_account"

  edit: (e, id) =>
    if e
      e.preventDefault()
      id = $(e.target).closest('.action').data('id')
    channel = App.Channel.find(id)
    if !channel
      @navigate '#channels/twitter'
      return

    new AccountEdit(
      channel: channel
      container: @el.parents('.content')
      load: @load
    )

  delete: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    new App.ControllerConfirm(
      message: 'Sure?'
      callback: =>
        @ajax(
          id:   'twitter_delete'
          type: 'DELETE'
          url:  "#{@apiPath}/channels_twitter"
          data: JSON.stringify(id: id)
          processData: true
          success: =>
            @load()
        )
      container: @el.closest('.content')
    )

  disable: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    @ajax(
      id:   'twitter_disable'
      type: 'POST'
      url:  "#{@apiPath}/channels_twitter_disable"
      data: JSON.stringify(id: id)
      processData: true
      success: =>
        @load()
    )

  enable: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    @ajax(
      id:   'twitter_enable'
      type: 'POST'
      url:  "#{@apiPath}/channels_twitter_enable"
      data: JSON.stringify(id: id)
      processData: true
      success: =>
        @load()
    )

class AppConfig extends App.ControllerModal
  head: 'Connect Twitter App'
  shown: true
  button: 'Connect'
  buttonCancel: true
  small: true

  content: ->
    @external_credential = App.ExternalCredential.findByAttribute('name', 'twitter')
    content = $(App.view('twitter/app_config')(
      external_credential: @external_credential
      callbackUrl: @callbackUrl
    ))
    content.find('.js-select').on('click', (e) =>
      @selectAll(e)
    )
    content

  onClosed: =>
    return if !@isChanged
    @isChanged = false
    @load()

  onSubmit: (e) =>
    @formDisable(e)

    # verify app credentials
    @ajax(
      id:   'twitter_app_verify'
      type: 'POST'
      url:  "#{@apiPath}/external_credentials/twitter/app_verify"
      data: JSON.stringify(@formParams())
      processData: true
      success: (data, status, xhr) =>
        if data.attributes
          if !@external_credential
            @external_credential = new App.ExternalCredential
          @external_credential.load(name: 'twitter', credentials: data.attributes)
          @external_credential.save(
            done: =>
              @isChanged = true
              @close()
            fail: =>
              @el.find('.alert').removeClass('hidden').text('Unable to create entry.')
          )
          return
        @formEnable(e)
        @el.find('.alert').removeClass('hidden').text(data.error || 'Unable to verify App.')
    )

class AccountEdit extends App.ControllerModal
  head: 'Twitter Account'
  shown: true
  buttonCancel: true

  content: ->
    content = $( App.view('twitter/account_edit')(channel: @channel) )

    createGroupSelection = (selected_id, prefix) ->
      return App.UiElement.select.render(
        name: "#{prefix}::group_id"
        multiple: false
        limit: 100
        null: false
        relation: 'Group'
        nulloption: true
        value: selected_id
        class: 'form-control--small'
      )

    addSearchTerm = =>
      params = @getParams()
      @searchTerms = params.search || []
      @searchTerms.push
        term: ''
        group_id: ''
      renderSearchTerms()
      content.find('.js-searchTermList [name="search::term"]').last().focus()

    removeSearchTerm = (event) =>
      index = $(event.currentTarget).attr('data-index')
      params = @getParams()
      @searchTerms = params.search || []
      @searchTerms.splice(index, 1)
      renderSearchTerms()

    renderSearchTerms = =>
      return if !@searchTerms

      content.find('.js-searchTermList').empty()

      for item, i in @searchTerms
        content.find('.js-searchTermList').append App.view('twitter/search_term')
          term: item.term
          index: i

        select = createGroupSelection(item.group_id, 'search')
        content.find(".js-termGroup[data-index=\"#{i}\"]").replaceWith select

    if @channel.options && @channel.options.sync && @channel.options.sync.search
      @searchTerms = @channel.options.sync.search
    else
      @searchTerms = []

    renderSearchTerms()

    content.find('.js-searchTermAdd').click(addSearchTerm)
    content.find('.js-searchTermList').on('click', '.js-searchTermRemove', removeSearchTerm)

    content.find('.js-mentionsGroup').replaceWith createGroupSelection(@channel.options.sync.mentions.group_id, 'mentions')
    content.find('.js-directMessagesGroup').replaceWith createGroupSelection(@channel.options.sync.direct_messages.group_id, 'direct_messages')
    content

  getParams: =>
    params = @formParams()
    search = []
    position = 0
    if params.search
      if _.isArray(params.search.term)
        for key in params.search.term
          item =
            term: params.search.term[position]
            group_id: params.search.group_id[position]
          search.push item
          position += 1
      else
        search.push params.search
    params.search = search
    if params.track_retweets
      params.track_retweets = true
    else
      params.track_retweets = false
    params

  onClosed: =>
    return if !@isChanged
    @isChanged = false
    @load()

  onSubmit: (e) =>
    @formDisable(e)
    @channel.options.sync = @getParams()
    @ajax(
      id:   'channel_twitter_update'
      type: 'POST'
      url:  "#{@apiPath}/channels_twitter/#{@channel.id}"
      data: JSON.stringify(@channel.attributes())
      processData: true
      success: (data, status, xhr) =>
        @isChanged = true
        @close()
      error: (xhr) =>
        data = JSON.parse(xhr.responseText)
        @formEnable(e)
        @el.find('.alert').removeClass('hidden').text(data.error || 'Unable to save changes.')
    )

App.Config.set('Twitter', { prio: 5000, name: 'Twitter', parent: '#channels', target: '#channels/twitter', controller: ChannelTwitter, permission: ['admin.channel_twitter'] }, 'NavBarAdmin')
