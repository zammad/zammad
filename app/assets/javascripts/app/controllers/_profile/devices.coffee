class ProfileDevices extends App.ControllerSubContent
  requiredPermission: 'user_preferences.device'
  header: 'Devices'
  events:
    'click [data-type=delete]': 'delete'

  constructor: ->
    super
    @load()
    @interval(
      =>
        @load()
      62000
    )

  # fetch data, render view
  load: (force = false) =>
    @ajax(
      id:    'user_devices'
      type:  'GET'
      url:   "#{@apiPath}/user_devices"
      success: (data) =>

        # verify is rerender is needed
        if !force && @lastestUpdated && data && data[0] && @lastestUpdated.updated_at is data[0].updated_at
          return
        @lastestUpdated = data[0]
        @data = data
        @render()
    )

  render: =>
    @html App.view('profile/devices')(
      devices: @data || []
    )

  delete: (e) =>
    e.preventDefault()
    id = $(e.target).closest('div').data('device-id')

    @ajax(
      id:          'user_devices_delete'
      type:        'DELETE'
      url:         "#{@apiPath}/user_devices/#{id}"
      processData: true
      success: =>
        @load(true)
      error: @error
    )

  error: (xhr, status, error) =>
    data = JSON.parse(xhr.responseText)
    @notify(
      type: 'error'
      msg:  App.i18n.translateContent(data.message)
    )

App.Config.set('Devices', { prio: 3100, name: 'Devices', parent: '#profile', target: '#profile/devices', controller: ProfileDevices, permission: ['user_preferences.device'] }, 'NavBarProfile')
