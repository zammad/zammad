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
      id:   'facebook_index'
      type: 'GET'
      url:  "#{@apiPath}/channels/facebook_index"
      processData: true
      success: (data, status, xhr) =>
        @stopLoading()
        App.Collection.loadAssets(data.assets)
        @callbackUrl = data.callback_url
        @render(data)
    )

  render: (data) =>

    # if no facebook app is registered, show intro
    if !App.ExternalCredential.findByAttribute(name: 'facebook')
      @html App.view('facebook/index')()
      return

    channels = []
    for channel_id in data.channel_ids
      channel = App.Channel.find(channel_id)
      if channel && channel.options && channel.options.sync
        displayName = '-'
        if channel.options.sync.wall.group_id
          group = App.Group.find(channel.options.sync.wall.group_id)
          displayName = group.displayName()
        channel.options.sync.wall.groupName = displayName
        for page in channel.options.pages
          displayName = '-'
          for page_id, pageParams of channel.options.sync.pages
            if page.id is page_id
              if pageParams.group_id
                group = App.Group.find(pageParams.group_id)
                displayName = group.displayName()
                page.groupName = displayName
      channels.push channel
    @html App.view('facebook/list')(
      channels: channels
    )
      # accounts: accounts
      # showDescription: showDescription
      # description:     description

    if @channel_id
      @edit(undefined, @channel_id)

  configApp: =>
    external_credential = App.ExternalCredential.findByAttribute('name', 'facebook')
    contentInline = $(App.view('facebook/app_config')(
      external_credential: external_credential
      callbackUrl: @callbackUrl
    ))
    contentInline.find('.js-select').on('click', (e) =>
      @selectAll(e)
    )
    modal = new App.ControllerModal(
      head: 'Connect Facebook App'
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
          id:   'facebook_app_verify'
          type: 'POST'
          url:  "#{@apiPath}/external_credentials/facebook/app_verify"
          data: JSON.stringify(modal.formParams())
          processData: true
          success: (data, status, xhr) =>
            if data.attributes
              if !external_credential
                external_credential = new App.ExternalCredential
              external_credential.load(name: 'facebook', credentials: modal.formParams())
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
    window.location.href = "#{@apiPath}/external_credentials/facebook/link_account"

  edit: (e, id) =>
    if e
      e.preventDefault()
      id = $(e.target).closest('.action').data('id')
    channel = App.Channel.find(id)
    if !channel.options.sync
      channel.options.sync = {}
    if !channel.options.sync.wall
      channel.options.sync.wall = {}
    if !channel.options.sync.pages
      channel.options.sync.pages = {}
    content = $( App.view('facebook/account_edit')(channel: channel) )

    groupSelection = (selected_id, el, prefix) ->
      selection = App.UiElement.select.render(
        name: "#{prefix}::group_id"
        multiple: false
        limit: 100
        null: false
        relation: 'Group'
        nulloption: true
        default: selected_id
        class: 'form-control--small'
      )
      el.html(selection)

    groupSelection(channel.options.sync.wall.group_id, content.find('.js-wall .js-groups'), 'wall')
    for page in channel.options.pages
      pageConfigured = false
      for page_id, pageParams of channel.options.sync.pages
        if page.id is page_id
          pageConfigured = true
          groupSelection(pageParams.group_id, content.find(".js-groups[data-page-id=#{page.id}]"), "pages::#{page.id}")
      if !pageConfigured
        groupSelection('', content.find(".js-groups[data-page-id=#{page.id}]"), "pages::#{page.id}")

    modal = new App.ControllerModal(
      head: 'Facebook Account'
      container: @el.parents('.content')
      contentInline: content
      shown: true
      cancel: true
      onSubmit: (e) =>
        @formDisable(e)
        channel.options.sync = modal.formParams()
        @ajax(
          id:   'channel_facebook_update'
          type: 'POST'
          url:  "#{@apiPath}/channels/facebook_verify/#{channel.id}"
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

App.Config.set('Facebook', { prio: 5100, name: 'Facebook', parent: '#channels', target: '#channels/facebook', controller: Index, role: ['Admin'] }, 'NavBarAdmin')
