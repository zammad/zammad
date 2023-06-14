App.TimeAccountingUnitMixin =
  timeAccountingUnitOptions: ->
    [
      {
        display: __('no unit')
        value:   ''
      },
      {
        display: __('hour(s)')
        value:   'hour'
      },
      {
        display: __('quarter-hour(s)')
        value:   'quarter'
      },
      {
        display: __('minute(s)')
        value:   'minute'
      },
      {
        display: __('custom unit')
        value:   'custom'
      },
    ]

  timeAccountingDisplayUnit: ->
    switch @Config.get('time_accounting_unit')
      when 'hour'
        return __('hour(s)')
      when 'quarter'
        return __('quarter-hour(s)')
      when 'minute'
        return __('minute(s)')
      when 'custom'
        if @Config.get('time_accounting_unit_custom')
          return @Config.get('time_accounting_unit_custom')
        return null
      else
        return null
