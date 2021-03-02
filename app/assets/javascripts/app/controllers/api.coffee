class Api extends App.ControllerSubContent
  requiredPermission: 'admin.api'
  header: 'API'
  events:
    'click .action':  'action'
    'change .js-TokenAccess input': 'toggleTokenAccess'
    'change .js-PasswordAccess input': 'togglePasswordAccess'
    'click .js-appNew': 'appNew'

  elements:
    '.js-TokenAccess input': 'TokenAccess'
    '.js-PasswordAccess input': 'PasswordAccess'

  constructor: ->
    super
    App.Setting.fetchFull(
      @render
      force: false
    )

  render: =>

    # search area settings
    settings = App.Setting.search(
      filter:
        area: 'API::Base'
    )

    @html App.view('api')(
      settings: settings
    )

    if @subscribeApplicationId
      App.Setting.unsubscribe(@subscribeApplicationId)

    table = =>

      callbackHeader = (headers) ->
        attribute =
          name: 'view'
          display: 'View'
        headers.splice(3, 0, attribute)
        attribute =
          name: 'token'
          display: 'Token'
        headers.splice(4, 0, attribute)
        headers

      callbackViewAttributes = (value, object, attribute, header) ->
        value = 'X'
        value

      callbackTokenAttributes = (value, object, attribute, header) ->
        value = 'X'
        value

      new App.ControllerTable(
        el:      @$('.js-appList')
        model:   App.Application
        tableId: 'applications'
        objects: App.Application.all()
        bindRow:
          events:
            'click': @appEdit
        bindCol:
          view:
            events:
              'click': @appView
          token:
            events:
              'click': @appToken
        callbackHeader: [callbackHeader]
        callbackAttributes:
          view: [callbackViewAttributes]
          token: [callbackTokenAttributes]
      )
    table()
    @subscribeApplicationId = App.Application.subscribe(table, initFetch: true, clear: true)


  release: =>
    if @subscribeApplicationId
      App.Application.unsubscribe(@subscribeApplicationId)

  action: (e) ->
    e.preventDefault()
    id = $(e.target).parents('[data-id]').data('id')
    type = $(e.target).data('type')
    if type is 'uninstall'
      httpType = 'DELETE'

    if httpType
      @ajax(
        id:    'packages'
        type:  httpType
        url:   "#{@apiPath}/packages",
        data:  JSON.stringify(id: id)
        processData: false
        success: =>
          @load()
        )

  toggleTokenAccess: =>
    value = @TokenAccess.prop('checked')
    App.Setting.set('api_token_access', value)

  togglePasswordAccess: =>
    value = @PasswordAccess.prop('checked')
    App.Setting.set('api_password_access', value)

  appToken: (id, e) ->
    e.preventDefault()
    new ViewAppTokenModal(
      app: App.Application.find(id)
    )

  appView: (id, e) ->
    e.preventDefault()
    new ViewAppModal(
      app: App.Application.find(id)
    )

  appNew: (e) ->
    e.preventDefault()
    new App.ControllerGenericNew(
      pageData:
        object: 'Application'
      genericObject: 'Application'
      callback: =>
        @render()
      container: @el.closest('.content')
    )

  appEdit: (id, e) =>
    e.preventDefault()
    item = App.Application.find(id)

    new App.ControllerGenericEdit(
      id:       item.id
      pageData:
        object: 'Application'
      genericObject: 'Application'
      callback: =>
        @render()
      container: @el.closest('.content')
    )

class ViewAppModal extends App.ControllerModal
  headPrefix: 'App'
  buttonSubmit: false
  buttonCancel: true
  shown: true
  small: true
  events:
    'click .js-select': 'selectAll'

  constructor: (params) ->
    @head = params.app.name
    super

  content: ->
    "AppID: <input class=\"js-select\" type=\"text\" value=\"#{@app.uid}\">
    <br>
    Secret: <input class=\"js-select\" type=\"text\" value=\"#{@app.secret}\">"

class ViewAppTokenModal extends App.ControllerModal
  headPrefix: 'Generate Token'
  buttonSubmit: 'Generate Token'
  buttonCancel: true
  shown: true
  small: true
  events:
    'click .js-select': 'selectAll'

  constructor: (params) ->
    @head = params.app.name
    super

  content: ->
    "#{App.i18n.translateContent('Generate Access Token for |%s|', App.Session.get().displayNameLong())}"

  onSubmit: =>
    @ajax(
      id:          'application_token'
      type:        'POST'
      url:         "#{@apiPath}/applications/token"
      processData: true
      data:        JSON.stringify(id: @app.id)
      success:     (data, status, xhr) =>
        @contentInline = "#{App.i18n.translateContent('New Access Token is')}: <input class=\"js-select\" type=\"text\" value=\"#{data.token}\">"
        @update()
        @$('.js-submit').remove()
    )

App.Config.set('API', { prio: 1200, name: 'API', parent: '#system', target: '#system/api', controller: Api, permission: ['admin.api'] }, 'NavBarAdmin')
