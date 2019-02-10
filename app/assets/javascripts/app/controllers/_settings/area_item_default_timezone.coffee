class App.SettingsAreaItemDefaultTimezone extends App.SettingsAreaItem
  result: {}

  render: =>
    @fetchTimezones()

  localRender: (data) =>
    options = {}
    for timezone, offset of data.timezones
      if !offset.toString().match(/(\+|\-)/)
        offset = "+#{offset}"
      options[timezone] = "#{timezone} (GMT#{offset})"
    configure_attributes = [
      { name: 'timezone_default', display: '', tag: 'searchable_select', null: false, class: 'input', options: options, default: @setting.state_current.value },
    ]

    @html App.view(@template)(
      setting: @setting
    )

    new App.ControllerForm(
      el: @el.find('.form-item')
      model: { configure_attributes: configure_attributes, className: '' }
      autofocus: false
    )

  fetchTimezones: =>
    @ajax(
      id:    'calendar_timezones'
      type:  'GET'
      url:   "#{@apiPath}/calendars/timezones"
      success: (data) =>
        @result = data
        @localRender(data)
    )
