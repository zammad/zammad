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
    'click .js-swatch': 'useSwatchColor'

  elements:
    '.js-browser': 'browser'
    '.js-iframe': 'iframe'
    '.js-chat': 'chat'
    '.js-testurl-input': 'urlInput'
    '.js-backgroundColor': 'chatBackground'
    '.js-paramsBlock': 'paramsBlock'
    '.js-code': 'code'
    '.js-swatches': 'swatches'
    '.js-color': 'colorField'

  apiOptions: [
    {
      name: 'channel'
      default: "'default'"
      type: 'String'
      description: 'Name of the chat-channel.'
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
      name: 'port'
      default: 6042
      type: 'Int'
      description: ''
    }
    {
      name: 'debug'
      default: false
      type: 'Boolean'
      description: 'Enables console logging.'
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
      type: 'boolean'
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
      name: 'title'
      default: "'<strong>Chat</strong> with us!'"
      type: 'String'
      description: 'Welcome Title shown on the closed chat. Can contain HTML.'
    }
  ]

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
      apiOptions: @apiOptions
    )

    @code.each (i, block) ->
      hljs.highlightBlock block

    @updateParams()

  selectBrowserWidth: (event) =>
    tab = $(event.target).closest('[data-value]')

    # select tab
    tab.addClass('is-selected').siblings().removeClass('is-selected')
    value = tab.attr('data-value')
    width = parseInt value, 10

    # reset zoom
    @chat.css('transform', '')
    @browser.css('width', '')
    @chat.removeClass('is-fullscreen')
    @iframe.css
      transform: ''
      width: ''
      height: ''

    return if value is 'fit'

    if width < @el.width()
      @chat.addClass('is-fullscreen')
      @browser.css('width', "#{ width }px")
    else
      percentage = @el.width()/width
      @chat.css('transform', "scale(#{ percentage })")
      @iframe.css
        transform: "scale(#{ percentage })"
        width: @el.width() / percentage
        height: @el.height() / percentage

  changeDemoWebsite: (event) =>
    event.preventDefault() if event

    # fire both on enter and blur
    # but cache url
    return if @urlInput.val() is '' or @urlInput.val() is @url
    @url = @urlInput.val()

    src = @url
    if !src.startsWith('http')
      src = "http://#{ src }"

    @urlInput.addClass('is-loading')

    # clear swatches and iframe
    @swatches.empty()
    @iframe.attr('src', '').css('background-image', '')

    $.ajax
      url: 'https://images.zammad.com/api/v1/webpage/colors'
      data:
        url: src
      success: @renderDemoWebsite
      dataType: 'json'

  renderDemoWebsite: (data) =>

    # @iframe.attr 'src', src
    @renderSwatches data

    @urlInput.removeClass('is-loading')

  renderSwatches: (swatches) ->

    swatches = _.map swatches, tinycolor

    # filter white
    swatches = _.filter swatches, (color) =>
      0.25 < color.getLuminance() < 0.85

    htmlString = ''

    max = 8
    for color, i in swatches
      htmlString += App.view('channel/color_swatch')
        color: color.toHexString()
      break if i is max

    @swatches.html htmlString

    # auto use first color
    if swatches[0]
      @useSwatchColor undefined, swatches[0].toHexString()

  useSwatchColor: (event, code) ->
    if event
      code = $(event.currentTarget).attr('data-color')
    @colorField.val code
    @updateParams()

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

  widget: (e) ->
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
    if params.flat is 'on'
      @chat.addClass('zammad-chat--flat')
      params.flat = true
    else
      @chat.removeClass('zammad-chat--flat')

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

App.Config.set( 'Chat Widget', { prio: 4000, name: 'Chat Widget', parent: '#channels', target: '#channels/chat', controller: App.ChannelChat, role: ['Admin'] }, 'NavBarAdmin' )
