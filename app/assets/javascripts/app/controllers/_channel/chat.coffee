class ChannelChat extends App.ControllerSubContent
  requiredPermission: 'admin.channel_chat'
  header: 'Chat'
  events:
    'change .js-params': 'updateParams'
    'input .js-params': 'updateParams'
    'submit .js-demo-head': 'onUrlSubmit'
    'click .js-selectBrowserSize': 'selectBrowserSize'
    'click .js-swatch': 'usePaletteColor'
    'click .js-toggle-chat': 'toggleChat'
    'change .js-chatSetting input': 'toggleChatSetting'
    'click .js-eyedropper': 'pickColor'

  elements:
    '.js-browser': 'browser'
    '.js-browserBody': 'browserBody'
    '.js-screenshot': 'screenshot'
    '.js-website': 'website'
    '.js-chat': 'chat'
    '.js-chatHeader': 'chatHeader'
    '.js-chat-welcome': 'chatWelcome'
    '.js-testurl-input': 'urlInput'
    '.js-backgroundColor': 'chatBackground'
    '.js-code': 'code'
    '.js-palette': 'palette'
    '.js-color': 'colorField'
    '.js-chatSetting input': 'chatSetting'
    '.js-eyedropper': 'eyedropper'

  apiOptions: [
    {
      name: 'chatId'
      default: '1'
      type: 'Number'
      description: 'Identifier of the chat-topic.'
    }
    {
      name: 'show'
      default: true
      type: 'Boolean'
      description: 'Show the chat when ready.'
    }
    {
      name: 'target'
      default: "$('body')"
      type: 'jQuery Object'
      description: 'Where to append the chat to.'
    }
    {
      name: 'host'
      default: '(Empty)'
      type: 'String'
      description: "If left empty, the host gets auto-detected - in this case %s. The auto-detection reads out the host from the <script> tag. If you don't include it via a <script> tag you need to specify the host."
      descriptionSubstitute: window.location.origin
    }
    {
      name: 'debug'
      default: false
      type: 'Boolean'
      description: 'Enables console logging.'
    }
    {
      name: 'title'
      default: "'<strong>Chat</strong> with us!'"
      type: 'String'
      description: 'Welcome Title shown on the closed chat. Can contain HTML.'
    }
    {
      name: 'fontSize'
      default: 'undefined'
      type: 'String'
      description: 'CSS font-size with a unit like 12px, 1.5em. If left to undefined it inherits the font-size of the website.'
    }
    {
      name: 'flat'
      default: 'false'
      type: 'Boolean'
      description: 'Removes the shadows for a flat look.'
    }
    {
      name: 'buttonClass'
      default: "'open-zammad-chat'"
      type: 'String'
      description: 'Add this class to a button on your page that should open the chat.'
    }
    {
      name: 'inactiveClass'
      default: "'is-inactive'"
      type: 'String'
      description: 'This class gets added to the button on initialization and gets removed once the chat connection got established.'
    }
    {
      name: 'cssAutoload'
      default: 'true'
      type: 'Boolean'
      description: 'Automatically loads the chat.css file. If you want to use your own css, just set it to false.'
    }
    {
      name: 'cssUrl'
      default: 'undefined'
      type: 'String'
      description: 'Location of an external chat.css file.'
    }
  ]

  isOpen: true
  browserSize: 'desktop'
  previewUrl: ''
  previewScale: 1

  constructor: ->
    super
    if @Session.get('email')
      @previewUrl = "www.#{@Session.get('email').replace(/^.+?\@/, '')}"

    @load()

    @permanent =
      chatId: 1
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

        firstChat = App.Chat.first()
        if firstChat
          @permanent =
            chatId: firstChat.id
        @stopLoading()
        @render(data)
    )

  render: (data = {}) =>
    @html App.view('channel/chat')(
      baseurl: window.location.origin
      apiOptions: @apiOptions
      previewUrl: @previewUrl
      chatSetting: @Config.get('chat')
    )

    new Topics(
      el: @$('.js-topics')
    )

    @code.each (i, block) ->
      hljs.highlightBlock block

    @updatePreview()
    @updateParams()
    @changeDemoWebsite()

    # bind updatePreview with parameter animate = false
    $(window).on 'resize.chat-designer', => @updatePreview false

  release: ->
    $(window).off 'resize.chat-designer'
    @website.off('click.eyedropper')

  selectBrowserSize: (event) =>
    tab = $(event.target).closest('[data-size]')

    # select tab
    tab.addClass('is-selected').siblings().removeClass('is-selected')
    @browserSize = tab.attr('data-size')
    @updatePreview()

  updatePreview: (animate =  true) =>
    # reset zoom
    @chat
      .removeClass('is-fullscreen')
      .toggleClass('no-transition', !animate)
      .css 'transform', "translateY(#{ @getChatOffset() }px)"
    @browser.attr('data-size', @browserSize)
    @previewScale = 1

    switch @browserSize
      when 'mobile'
        @chat.addClass('is-fullscreen').css 'transform', "translateY(#{ @getChatOffset(true) }px)"
      when '1:1'
        @previewScale = Math.max(1, 1280/@el.width())
        @website.css 'transform', "scale(#{ @previewScale })"
      when 'desktop'
        scale = Math.min(1, @el.width()/1280) # don't use it for the previewScale (used for the color picker)
        @website.css 'transform', ''
        @chat.css 'transform', "translateY(#{ @getChatOffset() * scale }px) scale(#{ scale })"

  getChatOffset: (fullscreen) ->
    return 0 if @isOpen

    if fullscreen
      return @browserBody.height() - @chatHeader.outerHeight()
    else
      return @chat.height() - @chatHeader.outerHeight()

  onUrlSubmit: (event) ->
    event.preventDefault() if event
    @urlInput.focus()
    @changeDemoWebsite()

  changeDemoWebsite: ->
    return if @urlInput.val() is '' or @urlInput.val() is @urlCache
    @urlCache = @urlInput.val()

    @url = @urlCache
    if !@url.startsWith('http')
      @url = "http://#{ @url }"

    @urlInput.addClass('is-loading')

    @palette.empty()

    @screenshot.attr('src', '')

    $.ajax
      url: 'https://images.zammad.com/api/v1/webpage/combined'
      data:
        url: @url
        count: 20
      success: @renderDemoWebsite
      dataType: 'json'

  renderDemoWebsite: (data) =>
    @_screenshotSource = data['data_url']

    @screenshot.attr 'src', @_screenshotSource

    @renderPalette data['palette']

    @urlInput.removeClass('is-loading')

  renderPalette: (palette) ->

    palette = _.map palette, tinycolor

    # filter white
    palette = _.filter palette, (color) ->
      color.getLuminance() < 0.85

    htmlString = ''

    max = 8
    for color, i in palette
      htmlString += App.view('channel/color_swatch')
        color: color.toHexString()
      break if i is max

    @palette.html htmlString

    # auto use first color
    if palette[0]
      @usePaletteColor undefined, palette[0].toHexString()

  usePaletteColor: (event, code) ->
    if event
      code = $(event.currentTarget).attr('data-color')
    @colorField.val code
    @updateParams()

  pickColor: ->
    return if !@_screenshotSource

    if @_pickingColor
      @_pickingColor = false
      @website
        .off('click.eyedropper')
        .removeClass('is-picking')
      @eyedropper.removeClass('is-active')
    else
      @_pickingColor = true
      @website
        .on('click.eyedropper', @onColorPicked)
        .addClass('is-picking')
      @eyedropper.addClass('is-active')

  onColorPicked: (event) =>
    website_x = @website.position().left
    website_y = @website.position().top

    relative_x = event.pageX - @browserBody.offset().left
    relative_y = event.pageY - @browserBody.offset().top

    image = new Image()
    image.src = @_screenshotSource

    canvas = document.createElement('canvas')
    ctx = canvas.getContext('2d')

    canvas.width = @browserBody.width()
    canvas.height = @browserBody.height()

    ctx.drawImage(image, website_x, website_y, @website.width() * @previewScale, @website.width() * @previewScale)
    pixels = ctx.getImageData(relative_x, relative_y, 1, 1).data

    @colorField.val("rgb(#{pixels.slice(0,3).join(',')})").trigger('change')

  toggleChat: =>
    @chat.toggleClass('is-open')
    @isOpen = @chat.hasClass('is-open')
    @updatePreview()

  toggleChatSetting: =>
    value = @chatSetting.prop('checked')
    App.Setting.set('chat', value)

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
    if params.flat is 'on'
      @chat.addClass('zammad-chat--flat')
      params.flat = true
    else
      @chat.removeClass('zammad-chat--flat')
    @chatWelcome.html params.title

    @updatePreview false

    if @permanent
      for key, value of @permanent
        params[key] = value
    paramString = ''
    for key, value of params
      if _.isNumber(value) || _.isBoolean(value) || !_.isEmpty(value)
        if paramString != ''
          # coffeelint: disable=no_unnecessary_double_quotes
          paramString += ",\n"
          # coffeelint: enable=no_unnecessary_double_quotes
        if value == true || value == false || _.isNumber(value)
          paramString += "    #{key}: #{value}"
        else
          paramString += "    #{key}: '#{quote(value)}'"
    @$('.js-modal-params').html(paramString)

    # highlight
    @code.each (i, block) ->
      hljs.highlightBlock block

App.Config.set('Chat', { prio: 4000, name: 'Chat', parent: '#channels', target: '#channels/chat', controller: ChannelChat, permission: ['admin.channel_chat'] }, 'NavBarAdmin')

class Topics extends App.Controller
  events:
    'click .js-add': 'new'
    'click .js-edit': 'edit'
    'click .js-remove': 'remove'

  constructor: ->
    super
    @render()

  render: =>
    @html App.view('channel/topics')(
      chats: App.Chat.all()
    )

  new: (e) =>
    new App.ControllerGenericNew(
      pageData:
        title: 'Chats'
        object: 'Chat'
        objects: 'Chats'
      genericObject: 'Chat'
      callback:   @render
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
      callback:  @render
    )

  remove: (e) =>
    e.preventDefault()
    id   = $(e.target).closest('tr').data('id')
    item = App.Chat.find(id)
    new App.ControllerGenericDestroyConfirm(
      item:      item
      container: @el.closest('.content')
      callback:  @render
    )
