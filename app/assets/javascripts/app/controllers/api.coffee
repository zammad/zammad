class Index extends App.ControllerSubContent
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

    # serach area settings
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
      new App.ControllerTable(
        el:           @$('.js-appList')
        model:        App.Application
        table_id:     'applications'
        objects:      App.Application.all()
        bindRow:
          events:
            'click': @appEdit
      )
    table()
    #App.Application.fetchFull(
    #  table
    #  clear: true
    #)
    @subscribeApplicationId = App.Application.subscribe(table, initFetch: true, clear: true)


  release: =>
    super
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

App.Config.set('API', { prio: 1200, name: 'API', parent: '#system', target: '#system/api', controller: Index, permission: ['admin.api'] }, 'NavBarAdmin')
