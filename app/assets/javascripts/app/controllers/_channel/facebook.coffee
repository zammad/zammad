class ChannelFacebook extends App.ControllerSubContent
  requiredPermission: 'admin.channel_facebook'
  header: 'Facebook'
  events:
    'click .js-new':       'new'
    'click .js-edit':      'edit'
    'click .js-delete':    'delete'
    'click .js-disable':   'disable'
    'click .js-enable':    'enable'
    'click .js-configApp': 'configApp'

  constructor: ->
    super

    #@interval(@load, 60000)
    @load()

  load: =>
    @startLoading()
    @ajax(
      id:   'facebook_index'
      type: 'GET'
      url:  "#{@apiPath}/channels_facebook"
      processData: true
      success: (data, status, xhr) =>
        @stopLoading()
        App.Collection.loadAssets(data.assets)
        @callbackUrl = data.callback_url
        @render(data)
    )

  render: (data) =>

    # if no facebook app is registered, show intro
    if !App.ExternalCredential.findByAttribute('name', 'facebook')
      @html App.view('facebook/index')()
      return

    channels = []
    for channel_id in data.channel_ids
      channel = App.Channel.find(channel_id)
      if channel && channel.options && channel.options.sync
        displayName = '-'
        if !channel.options.sync
          channel.options.sync = {}
        if channel.options && channel.options.pages
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
    window.location.href = "#{@apiPath}/external_credentials/facebook/link_account"

  edit: (e, id) =>
    if e
      e.preventDefault()
      id = $(e.target).closest('.action').data('id')
    channel = App.Channel.find(id)
    if !channel
      @navigate '#channels/facebook'
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
          id:   'facebook_delete'
          type: 'DELETE'
          url:  "#{@apiPath}/channels_facebook"
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
      id:   'facebook_disable'
      type: 'POST'
      url:  "#{@apiPath}/channels_facebook_disable"
      data: JSON.stringify(id: id)
      processData: true
      success: =>
        @load()
    )

  enable: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('.action').data('id')
    @ajax(
      id:   'facebook_enable'
      type: 'POST'
      url:  "#{@apiPath}/channels_facebook_enable"
      data: JSON.stringify(id: id)
      processData: true
      success: =>
        @load()
    )

class AppConfig extends App.ControllerModal
  head: 'Connect Facebook App'
  shown: true
  button: 'Connect'
  buttonCancel: true
  small: true

  content: ->
    @external_credential = App.ExternalCredential.findByAttribute('name', 'facebook')
    content = $(App.view('facebook/app_config')(
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
      id:   'facebook_app_verify'
      type: 'POST'
      url:  "#{@apiPath}/external_credentials/facebook/app_verify"
      data: JSON.stringify(@formParams())
      processData: true
      success: (data, status, xhr) =>
        if data.attributes
          if !@external_credential
            @external_credential = new App.ExternalCredential
          @external_credential.load(name: 'facebook', credentials: @formParams())
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
  head: 'Facebook Account'
  shown: true
  buttonCancel: true

  content: ->
    if !@channel.options.sync
      @channel.options.sync = {}
    if !@channel.options.sync.pages
      @channel.options.sync.pages = {}
    content = $( App.view('facebook/account_edit')(channel: @channel) )

    groupSelection = (selected_id, el, prefix) ->
      selection = App.UiElement.select.render(
        name: "#{prefix}::group_id"
        multiple: false
        limit: 100
        null: false
        relation: 'Group'
        nulloption: true
        value: selected_id
        class: 'form-control--small'
      )
      el.html(selection)

    if @channel.options.pages
      for page in @channel.options.pages
        pageConfigured = false
        for page_id, pageParams of @channel.options.sync.pages
          if page.id is page_id
            pageConfigured = true
            groupSelection(pageParams.group_id, content.find(".js-groups[data-page-id=#{page.id}]"), "pages::#{page.id}")
        if !pageConfigured
          groupSelection('', content.find(".js-groups[data-page-id=#{page.id}]"), "pages::#{page.id}")

    content

  onClosed: =>
    return if !@isChanged
    @isChanged = false
    @load()

  onSubmit: (e) =>
    @formDisable(e)
    @channel.options.sync = @formParams()
    @ajax(
      id:   'channel_facebook_update'
      type: 'POST'
      url:  "#{@apiPath}/channels_facebook/#{@channel.id}"
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

App.Config.set('Facebook', { prio: 5100, name: 'Facebook', parent: '#channels', target: '#channels/facebook', controller: ChannelFacebook, permission: ['admin.channel_facebook'] }, 'NavBarAdmin')
