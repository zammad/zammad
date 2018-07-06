# coffeelint: disable=camel_case_classes
class App.UiElement.time_range
  @render: (attribute) ->
    ranges =
      minute: 'Minute(s)'
      hour: 'Hour(s)'
      day: 'Day(s)'
      month: 'Month(s)'
      year: 'Year(s)'
    for key, value of ranges
      ranges[key] = App.i18n.translateInline(value)

    range = 'minute'
    if attribute.value && attribute.value.range
      range = attribute.value.range
    values =
      minute: [1..120]
      hour: [1..48]
      day: [1..31]
      month: [1..12]
      year: [1..20]

    element = $( App.view('generic/time_range')(attribute: attribute, ranges: ranges))
    @localRenderPulldown(element.filter('.js-valueRangeSelector'), values[range], attribute)
    element.find('select.form-control.js-range').on('change', (e) =>
      range = $(e.currentTarget).val()
      @localRenderPulldown($(e.currentTarget).closest('.js-filterElement').find('.js-valueRangeSelector'), values[range], attribute)
    )
    element

  @localRenderPulldown: (el, range, attribute) ->
    return if !range
    values = {}
    for count in range
      values[count.toString()] = count.toString()
    select = App.view('generic/time_range_value_selector')(attribute: attribute, values: values)
    el.html(select)
