class App.KnowledgeBasePermissionsDialog extends App.ControllerModal
  events:
    #'submit form':          'submitPermissions'
    'click td.u-clickable': 'cellBackgroundClicked'

  head: 'Permissions'
  includeForm: true
  buttonSubmit: true
  accessLevels: { editor: 'Editor', reader: 'Reader', none: 'None' }

  cellBackgroundClicked: (e) ->
    return if e.target != e.currentTarget

    e.preventDefault()
    e.currentTarget.querySelector('input')?.click()

  data: null

  constructor: (params) ->
    super

    @load()

  content: =>
    return if !@data

    App.view('knowledge_base/permissions_dialog')(
      accessLevels: @accessLevels
      params: @loadedParams(@data)
      roles: @formRoles(@data)
    )

  loadedParams: (data) ->
    params = []

    for permission in data.permissions
      params[permission.role_id] = permission.access

    for role in data.roles_editor
      params[role.id] ||= 'editor'

    for role in data.roles_reader
      params[role.id] ||= 'reader'

    params

  formRoles: (data) ->
    data.roles_editor.forEach (elem) => @formRolesItem(elem, 'editor', data)
    data.roles_reader.forEach (elem) => @formRolesItem(elem, 'reader', data)

    _.sortBy data.roles_editor.concat(data.roles_reader), (elem) -> elem.name

  formRolesItem: (elem, role_name, data) ->
    elem.accessLevel = role_name
    elem.limit = _.findWhere(data.inherited, { role_id: elem.id })?.access

    if elem.limit?
      elem.accessLevelIsDisabled = {
        editor: elem.limit != 'editor'
        reader: elem.limit == 'none'
        none:   false
      }
    else
      elem.accessLevelIsDisabled = {
        editor: elem.accessLevel != 'editor'
        reader: false
        none:   false
      }

  load: =>
    @ajax(
      id:          'knowledge_base_permissions_get'
      type:        'get'
      url:         @object.generateURL('permissions')
      processData: true
      success:     (data, status, xhr) =>
        @data = data
        @update()
      error:       (xhr) =>
        @showAlert(xhr.responseJSON?.error || __('Changes could not be loaded.'))
    )

  toggleDisabled: (state) =>
    @el.find('input:not([data-permanently-disabled]), button').attr('disabled', state)

  onSubmit: (e) =>
    @clearAlerts()
    @toggleDisabled(true)

    data = @formParams()

    params = { permissions_dialog: { permissions: data } }

    @ajax(
      id:          'knowledge_base_permissions_patch'
      type:        'PATCH'
      data:        JSON.stringify(params)
      url:         @object.generateURL('permissions')
      processData: true
      success:     (data, status, xhr) =>
        @close()
      error:       (xhr) =>
        @toggleDisabled(false)
        @showAlert(xhr.responseJSON?.error || __('Changes could not be saved.'))
    )
