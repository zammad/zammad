class Package extends App.ControllerSubContent
  @requiredPermission: 'admin.package'
  header: __('Packages')

  elements:
    '.js-fileUpload': 'fileUpload'
    '.js-submit': 'packageSubmit'

  events:
    'change .js-fileUpload': 'selectFile'
    'click .js-packageSettings': 'packageSettings'
    'click .js-packageAction[data-table-action="uninstall"]': 'uninstall'
    'click .js-packageAction[data-table-action="update_api"]': 'update_api'
    'click .js-packageAction[data-table-action="install_api"]': 'install_api'

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
        @token_setting_id     = data.token_setting_id
        @token_present        = data.token_present
        @api_package_metas = data.api_package_metas || {}
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
      item.action = ['uninstall']
      if @api_package_metas[item.name] && item.vendor is @api_package_metas[item.name].vendor
        if @isNewerVersion(item.version, @api_package_metas[item.name].version)
          item.action.unshift('update_api')

    api_packages_installable = []
    for name, data of @api_package_metas
      continue if _.find(@packages, (row) -> row.name is name)

      api_packages_installable.push(name)

    @html App.view('package')(
      head:     __('Dashboard')
      packages: @packages
      package_installation: @package_installation
      local_gemfiles: @local_gemfiles
      token_present: @token_present
      api_package_metas: @api_package_metas
      api_packages_installable: api_packages_installable
    )

  uninstall: (e) ->
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

  isNewerVersion: (local, remote) ->
    local_parts  = local.split('.').map((n) -> parseInt(n))
    remote_parts = remote.split('.').map((n) -> parseInt(n))
    local_parts[0] * 1000000 + local_parts[1] * 1000 + local_parts[2] < remote_parts[0] * 1000000 + remote_parts[1] * 1000 + remote_parts[2]

  selectFile: (e) ->
    if !_.isEmpty(@fileUpload.val())
      @packageSubmit.prop('disabled', false)
    else
      @packageSubmit.prop('disabled', true)

  update_api: (e) ->
    e.preventDefault()

    id = $(e.target).parents('[data-id]').data('id')
    @ajax(
      id:    'packages'
      type:  'PUT'
      url:   "#{@apiPath}/packages/api",
      data:  JSON.stringify(id: id)
      processData: false
      success: =>
        @notify(
          type:      'success'
          msg:       __('Package updated successfully.')
          removeAll: true
        )
        @load()
    )

  install_api: (e) ->
    e.preventDefault()

    id = $(e.target).parents('[data-id]').data('id')
    @ajax(
      id:    'packages'
      type:  'POST'
      url:   "#{@apiPath}/packages/api",
      data:  JSON.stringify(id: id)
      processData: false
      success: =>
        @notify(
          type:      'success'
          msg:       __('Package installed successfully.')
          removeAll: true
        )
        @load()
    )

  packageSettings: (e) ->
    e.preventDefault()
    e.stopPropagation()
    new PackageSettingsModal(
      token_setting_id: @token_setting_id
      token_present: @token_present
      parent: @
    )

class PackageSettingsModal extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: true
  head: __('Configure')
  events:
    'click .js-reset': 'resetToDefault'

  constructor: (params) ->
    if params.token_present
      @centerButtons = [
        {
          text: __('Reset to default settings')
          className: 'btn--danger js-reset'
        }
      ]

    super

  content: ->
    token_value = ''
    token_value = 'present' if @token_present

    configureAttributes = [
      { name: 'token', display: __('API Token'), tag: 'input', type: 'password', autocomplete: 'one-time-code', single: true, null: true, value: token_value, help: __('Please enter the API token you received from Zammad.') },
    ]
    @controller = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
        className: ''
      autofocus: true
    )
    @controller.form

  resetToDefault: =>
    return if !@token_present

    target = @controller.form[0]

    $(target).find('[name="token"]').val('')

    @onSubmit(new Event('submit', { cancelable: true, bubbles: true, target: target }))

  onSubmit: (e) =>
    params = @formParam(e.target)
    return @close() if params.token is 'present'

    @ajax(
      type:  'PUT'
      url:   "#{@apiPath}/settings/#{@token_setting_id}"
      data: JSON.stringify({ state_current: { value: params.token } }),
      success: (data, status, xhr) =>
        @notify(
          type:      'success'
          msg:       __('Update successful.')
          removeAll: true
        )
        @close()
    )

  close: =>
    super
    @parent.load()

App.Config.set('Packages', { prio: 3700, name: __('Packages'), parent: '#system', target: '#system/package', controller: Package, permission: (controller) -> App.Config.get('admin_packages') && controller.permissionCheck('admin.package') }, 'NavBarAdmin')
