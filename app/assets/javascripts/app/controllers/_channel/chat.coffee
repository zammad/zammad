class App.ChannelChat extends App.Controller
  events:
    'click .js-add': 'new'
    'click .js-edit': 'edit'
    'click .js-remove': 'remove'
    'click .js-widget': 'widget'
    'change .js-params': 'updateParams'
    'keyup .js-params': 'updateParams'

  constructor: ->
    super
    @interval(@load, 30000)
    #@load()

    @widgetDesignerPermanentParams =
      id: 'id'

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
