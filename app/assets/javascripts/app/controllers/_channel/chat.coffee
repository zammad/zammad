class App.ChannelChat extends App.Controller
  events:
    'click .js-add': 'new'
    'click .js-edit': 'edit'
    'click .js-remove': 'remove'
    'click .js-widget': 'widget'
    'change .js-params': 'updateParams'
    'keyup .js-params': 'updateParams'
    'submit .js-testurl': 'changeDemoWebsite'
    'blur .js-testurl-input': 'changeDemoWebsite'
    'click .js-selectBrowserWidth': 'selectBrowserWidth'

  elements:
    '.js-demo': 'demo'
    '.js-browser': 'browser'
    '.js-iframe': 'iframe'
    '.js-chat': 'chat'
    '.js-testurl-input': 'urlInput'
    '.js-backgroundColor': 'chatBackground'

  constructor: ->
    super
    @load()

    @widgetDesignerPermanentParams =
      id: 'id'

    $(window).on 'resize.chat-designer', @resizeDemo

  load: =>
    @startLoading()
    @ajax(
      id:   'chat_index'
      type: 'GET'
      url:  @apiPath + '/chats'
      processData: true
      success: (data, status, xhr) =>
        App.Collection.loadAssets(data.assets)
        @stopLoading()
        @render(data)
    )

  render: (data = {}) =>

    chats = []
    for chat_id in data.chat_ids
      chats.push App.Chat.find(chat_id)

    @html App.view('channel/chat')(
      baseurl: window.location.origin
      chats: chats
    )

    @updateParams()

    new App.SettingsArea(
      el:   @$('.js-settings')
      area: 'Chat::Base'
    )

  selectBrowserWidth: (event) =>
    tab = $(event.target).closest('[data-value]')

    # select tab
    tab.addClass('is-selected').siblings().removeClass('is-selected')
    
    value = tab.attr('data-value')
    width = parseInt value, 10

    # reset zoom
    @chat.css('transform', "")
    @browser.css('width', "")
    @chat.removeClass('is-fullscreen')
    @iframe.css
      transform: ""
      width: ""
      height: ""

    return if value is 'fit'

    if width < @demo.width()
      @chat.addClass('is-fullscreen')
      @browser.css('width', "#{ width }px")
    else
      percentage = @demo.width()/width
      @chat.css('transform', "scale(#{ percentage })")
      @iframe.css
        transform: "scale(#{ percentage })"
        width: @demo.width() / percentage
        height: @demo.height() / percentage

  changeDemoWebsite: (event) =>
    event.preventDefault() if event

    # fire both on enter and blur
    # but cache url
    return if @urlInput.val() is "" or @urlInput.val() is @url
    @url = @urlInput.val()

    src = @url
    if !src.startsWith('http')
      src = "http://#{ src }"

    @iframe.attr 'src', src

  new: (e) =>
    new App.ControllerGenericNew(
      pageData:
        title: 'Chats'
        object: 'Chat'
        objects: 'Chats'
      genericObject: 'Chat'
      callback:   @load
      container:  @el.closest('.content')
      large:      true
    )

  edit: (e) =>
    e.preventDefault()
    id = $(e.target).closest('tr').data('id')
    new App.ControllerGenericEdit(
      id:        id
      genericObject: 'Chat'
      pageData:
        object: 'Chat'
      container: @el.closest('.content')
      callback:  @load
    )

  remove: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('tr').data('id')
    item = App.Chat.find(id)
    new App.ControllerGenericDestroyConfirm(
      item:      item
      container: @el.closest('.content')
      callback:  @load
    )

  widget: (e) =>
    e.preventDefault()
    id = $(e.target).closest('.action').data('id')
    new Widget(
      permanent:
        id: id
    )

  updateParams: =>
    quote = (value) ->
      if value.replace
        value = value.replace('\'', '\\\'')
          .replace(/\</g, '&lt;')
          .replace(/\>/g, '&gt;')
      value
    params = @formParam(@$('.js-params'))

    if parseInt(params.fontSize, 10) > 2
      @chat.css('font-size', params.fontSize)
    @chatBackground.css('background', params.background)

    if @permanent
      for key, value of @permanent
        params[key] = value
    paramString = ''
    for key, value of params
      if value != ''
        if paramString != ''
          paramString += ",\n"
        if value == 'true' || value == 'false' || _.isNumber(value)
          paramString += "    #{key}: #{value}"
        else
          paramString += "    #{key}: '#{quote(value)}'"
    @$('.js-modal-params').html(paramString)

App.Config.set( 'Chat', { prio: 4000, name: 'Chat', parent: '#channels', target: '#channels/chat', controller: App.ChannelChat, role: ['Admin'] }, 'NavBarAdmin' )
