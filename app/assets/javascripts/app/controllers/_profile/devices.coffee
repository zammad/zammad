class Index extends App.Controller
  events:
    'click [data-type=delete]': 'delete'

  constructor: ->
    super
    return if !@authenticate()
    @title 'Devices', true

    @load()
    @interval(
      =>
        @load()
      62000
    )

  # fetch data, render view
  load: =>
    @ajax(
      id:    'user_devices'
      type:  'GET'
      url:   "#{@apiPath}/user_devices"
      success: (data) =>
        @data = data
        @render()
    )

  render: =>
    @html App.view('profile/devices')(
      devices: @data || []
    )

  delete: (e) =>
    e.preventDefault()
    id = $(e.target).closest('a').data('device-id')

    @ajax(
      id:          'user_devices_delete'
      type:        'DELETE'
      url:         "#{@apiPath}/user_devices/#{id}"
      processData: true
      success:     @load
      error:       @error
    )

  error: (xhr, status, error) =>
    data = JSON.parse(xhr.responseText)
    @notify(
      type: 'error'
      msg:  App.i18n.translateContent(data.message)
    )

App.Config.set('Devices', { prio: 3100, name: 'Devices', parent: '#profile', target: '#profile/devices', controller: Index }, 'NavBarProfile')
