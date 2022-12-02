# coffeelint: disable=camel_case_classes
class App.UiElement.time_range
  @render: (attribute) ->
    ranges =
      minute: __('Minute(s)')
      hour: __('Hour(s)')
      day: __('Day(s)')
      week: __('Week(s)'),
      month: __('Month(s)')
      year: __('Year(s)')

    for key, value of ranges
      ranges[key] = App.i18n.translateInline(value)

    range = 'minute'
    if attribute.value && attribute.value.range
      range = attribute.value.range
    values =
      minute: [1..120]
      hour: [1..48]
      day: [1..31]
      week: [1..53]
      month: [1..12]
      year: [1..20]

    element = $( App.view('generic/time_range')(attribute: attribute, ranges: ranges))
    @localRenderPulldown(element.filter('.js-valueRangeSelector'), values[range], attribute)
    element.find('select.form-control.js-range').on('change', (e) =>
      range = $(e.currentTarget).val()
      value_selector = $(e.currentTarget).closest('.js-filterElement').find('.js-valueRangeSelector')
      selected_value = value_selector.find('select').val() if value_selector
      @localRenderPulldown(value_selector, values[range], attribute, selected_value)
    )
    element

  @localRenderPulldown: (el, range, attribute, selected_value) ->
    return if !range or !el
    values = {}
    for count in range
      values[count.toString()] = count.toString()
    if !selected_value
      if attribute.value
        selected_value = attribute.value.value
      else
        selected_value = 1
    select = App.view('generic/time_range_value_selector')(attribute: attribute, values: values, selected_value: selected_value)
    el.html(select)
