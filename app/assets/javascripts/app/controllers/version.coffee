class Version extends App.ControllerSubContent
  requiredPermission: 'admin.version'
  header: 'Version'

  constructor: ->
    super
    @load()

  # fetch data, render view
  load: ->
    @startLoading()
    @ajax(
      id:    'version'
      type:  'GET'
      url:   "#{@apiPath}/version"
      success: (data) =>
        @stopLoading()
        @version = data.version
        @render()
    )

  render: ->

    @html App.view('version')(
      version: @version
    )

App.Config.set('Version', { prio: 3800, name: 'Version', parent: '#system', target: '#system/version', controller: Version, permission: ['admin.version'] }, 'NavBarAdmin' )
