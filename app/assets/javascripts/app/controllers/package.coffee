class Package extends App.ControllerSubContent
  requiredPermission: 'admin.package'
  header: __('Packages')
  events:
    'click .package-action[data-type="uninstall"]':  'action'

  constructor: ->
    super
    @load()

  load: ->
    @ajax(
      id:    'packages',
      type:  'GET',
      url:   "#{@apiPath}/packages",
      processData: true,
      success: (data) =>
        @packages             = data.packages
        @package_installation = data.package_installation
        @local_gemfiles       = data.local_gemfiles
        @render()
      )

  render: ->

    for item in @packages
      item.action = []
      if item.state == 'installed'
#        item.action = ['uninstall', 'deactivate']
        item.action = ['uninstall']
      else if item.state == 'uninstalled'
        item.action = ['install']
      else if item.state == 'deactivate'
        item.action = ['uninstall', 'activate']

    @html App.view('package')(
      head:     __('Dashboard')
      packages: @packages
      package_installation: @package_installation
      local_gemfiles: @local_gemfiles
    )

  action: (e) ->
    e.preventDefault()
    id = $(e.target).parents('[data-id]').data('id')

    new App.ControllerConfirmDelete(
      fieldDisplay: App.i18n.translatePlain('There is no rollback of this deletion. If you are sure that you wish to proceed, please type "%s" into the input. All related data to this package will be lost.', App.i18n.translatePlain('Delete')),
      callback: (modal) =>

        @ajax(
          id:    'packages'
          type:  'DELETE'
          url:   "#{@apiPath}/packages",
          data:  JSON.stringify(id: id)
          processData: false
          success: =>
            modal.close()
            @load()
        )
    )

App.Config.set('Packages', { prio: 3700, name: __('Packages'), parent: '#system', target: '#system/package', controller: Package, permission: ['admin.package'] }, 'NavBarAdmin')
