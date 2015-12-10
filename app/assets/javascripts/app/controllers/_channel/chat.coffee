class App.ChannelChat extends App.Controller
  events:
    'change .js-params': 'updateParams'
    'input .js-params': 'updateParams'
    'submit .js-demo-head': 'onUrlSubmit'
    'blur .js-testurl-input': 'changeDemoWebsite'
    'click .js-selectBrowserWidth': 'selectBrowserWidth'
    'click .js-swatch': 'usePaletteColor'
    'click .js-toggle-chat': 'toggleChat'
    'click .js-chatSetting': 'toggleChatSetting'

  elements:
    '.js-browser': 'browser'
    '.js-browserBody': 'browserBody'
    '.js-iframe': 'iframe'
    '.js-screenshot': 'screenshot'
    '.js-website': 'website'
    '.js-chat': 'chat'
    '.js-chatHeader': 'chatHeader'
    '.js-chat-welcome': 'chatWelcome'
    '.js-testurl-input': 'urlInput'
    '.js-backgroundColor': 'chatBackground'
    '.js-paramsBlock': 'paramsBlock'
    '.js-code': 'code'
    '.js-palette': 'palette'
    '.js-color': 'colorField'
    '.js-chatSetting input': 'chatSetting'

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
  browserWidth: 1280
  previewUrl: ''

  constructor: ->
    super
    @title 'Chat'
    if @Session.get('email')
      @previewUrl = "www.#{@Session.get('email').replace(/^.+?\@/, '')}"

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

    # bind updatePreview with parameter animate = false
    $(window).on 'resize.chat-designer', => @updatePreview false

  release: ->
    $(window).off 'resize.chat-designer'

  selectBrowserWidth: (event) =>
    tab = $(event.target).closest('[data-value]')

    # select tab
    tab.addClass('is-selected').siblings().removeClass('is-selected')
    @browserWidth = tab.attr('data-value')
    @updatePreview()

  updatePreview: (animate =  true) =>
    width = parseInt @browserWidth, 10

    # reset zoom
    @chat
      .removeClass('is-fullscreen')
      .toggleClass('no-transition', !animate)
      .css 'transform', "translateY(#{ @getChatOffset() }px)"
    @browser.css('width', '')
    @website.css
      transform: ''
      width: ''
      height: ''

    return if @browserWidth is 'fit'

    if width < @el.width()
      @chat.addClass('is-fullscreen').css 'transform', "translateY(#{ @getChatOffset(true) }px)"
      @browser.css('width', "#{ width }px")
    else
      percentage = @el.width()/width
      @chat.css 'transform', "translateY(#{ @getChatOffset() * percentage }px) scale(#{ percentage })"
      @website.css
        transform: "scale(#{ percentage })"
        width: @el.width() / percentage
        height: @browserBody.height() / percentage

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
    @website.attr('data-mode', 'iframe')
    @iframe.attr('src', @url)

    $.ajax
      url: 'https://images.zammad.com/api/v1/webpage/combined'
      data:
        url: @url
        count: 20
      success: @renderDemoWebsite
      dataType: 'json'

  renderDemoWebsite: (data) =>
    imageSource = data['data_url']

    if imageSource
      @screenshot.attr 'src', imageSource
      @iframe.attr('src', '')
      @website.attr('data-mode', 'screenshot')

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

  toggleChat: =>
    @chat.toggleClass('is-open')
    @isOpen = @chat.hasClass('is-open')
    @updatePreview()

  toggleChatSetting: =>
    value = @chatSetting.prop('checked')
    setting = App.Setting.findByAttribute('name', 'chat')
    setting.state_current = { value: value }
    setting.save()
    @Config.set('chat', value)
    delay = -> App.Event.trigger('ui:rerender')
    @delay(delay, 200)

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
      if value != ''
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
    @paramsBlock.each (i, block) ->
      hljs.highlightBlock block

App.Config.set( 'Chat', { prio: 4000, name: 'Chat', parent: '#channels', target: '#channels/chat', controller: App.ChannelChat, role: ['Admin'] }, 'NavBarAdmin' )

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
