class Index extends App.ControllerContent
  events:
    'click .js-new':       'new'
    'click .js-edit':      'edit'
    'click .js-delete':    'delete'
    'click .js-configApp': 'configApp'

  constructor: ->
    super
    return if !@authenticate()

    #@interval(@load, 60000)
    @load()

  load: =>
    @startLoading()
    @ajax(
      id:   'twitter_index'
      type: 'GET'
      url:  "#{@apiPath}/channels/twitter_index"
      processData: true
      success: (data, status, xhr) =>
        @stopLoading()
        App.Collection.loadAssets(data.assets)
        @callbackUrl = data.callback_url
        @render(data)
    )

  render: (data) =>

    # if no twitter app is registered, show intro
    if !App.ExternalCredential.findByAttribute(name: 'twitter')
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
    )
      # accounts: accounts
      # showDescription: showDescription
      # description:     description

    if @channel_id
      @edit(undefined, @channel_id)

  configApp: =>
    external_credential = App.ExternalCredential.findByAttribute('name', 'twitter')
    contentInline = $(App.view('twitter/app_config')(
      external_credential: external_credential
      callbackUrl: @callbackUrl
    ))
    contentInline.find('.js-select').on('click', (e) =>
      @selectAll(e)
    )
    modal = new App.ControllerModal(
      head: 'Connect Twitter App'
      container: @el.parents('.content')
      contentInline: contentInline
      shown: true
      button: 'Connect'
      cancel: true
      small: true
      onSubmit: (e) =>
        @formDisable(e)

        # verify app credentals
        @ajax(
          id:   'twitter_app_verify'
          type: 'POST'
          url:  "#{@apiPath}/external_credentials/twitter/app_verify"
          data: JSON.stringify(modal.formParams())
          processData: true
          success: (data, status, xhr) =>
            if data.attributes
              if !external_credential
                external_credential = new App.ExternalCredential
              external_credential.load(name: 'twitter', credentials: modal.formParams())
              external_credential.save(
                done: =>
                  @load()
                  modal.close()
                fail: ->
                  modal.element().find('.alert').removeClass('hidden').text('Unable to create entry.')
              )
              return
            @formEnable(e)
            modal.element().find('.alert').removeClass('hidden').text(data.error || 'Unable to verify App.')
        )
    )

  new: (e) ->
    window.location.href = "#{@apiPath}/external_credentials/twitter/link_account"

  edit: (e, id) =>
    if e
      e.preventDefault()
      id = $(e.target).closest('.action').data('id')
    channel = App.Channel.find(id)
    content = $( App.view('twitter/account_edit')(channel: channel) )

    groupSelection = (selected_id, el, prefix) ->
      selection = App.UiElement.select.render(
        name: "#{prefix}::group_id"
        multiple: false
        limit: 100
        null: false
        relation: 'Group'
        nulloption: true
        default: selected_id
      )
      el.find('.js-groups').html(selection)

    placeholderAdd = (value = '', group_id) ->
      placeholder = content.find('.js-searchTermPlaceholder').clone()
      placeholder.removeClass('hidden').removeClass('js-searchTermPlaceholder')
      placeholder.find('input').val(value)
      placeholder.find('input').attr('name', 'search::term')
      groupSelection(group_id, placeholder, 'search')
      content.find('.js-searchTermList').append(placeholder)

    for item in channel.options.sync.search
      placeholderAdd(item.term, item.group_id, 'search')

    content.find('.js-searchTermAdd').on('click', ->
      placeholderAdd('', '')
    )
    content.find('.js-searchTerm').on('click', '.js-searchTermRemove',(e) ->
      $(e.target).closest('.js-searchTermItem').remove()
    )

    groupSelection(channel.options.sync.mentions.group_id, content.find('.js-mention'), 'mentions')
    groupSelection(channel.options.sync.direct_messages.group_id, content.find('.js-directMessage'), 'direct_messages')

    modal = new App.ControllerModal(
      head: 'Twitter Account'
      container: @el.parents('.content')
      contentInline: content
      shown: true
      cancel: true
      onSubmit: (e) =>
        @formDisable(e)
        params = modal.formParams()
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
        channel.options.sync = params
        @ajax(
          id:   'channel_twitter_update'
          type: 'POST'
          url:  "#{@apiPath}/channels/twitter_verify/#{channel.id}"
          data: JSON.stringify(channel.attributes())
          processData: true
          success: (data, status, xhr) =>
            @load()
            modal.close()
          fail: =>
            @formEnable(e)
        )
    )

  delete: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    item = App.Channel.find(id)
    new App.ControllerGenericDestroyConfirm(
      item:      item
      container: @el.closest('.content')
      callback:  @load
    )

  description: (e) =>
    new App.ControllerGenericDescription(
      description: App.Twitter.description
      container:   @el.closest('.content')
    )

App.Config.set('Twitter', { prio: 5000, name: 'Twitter', parent: '#channels', target: '#channels/twitter', controller: Index, role: ['Admin'] }, 'NavBarAdmin')
