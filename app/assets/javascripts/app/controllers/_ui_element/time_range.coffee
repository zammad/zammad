# coffeelint: disable=camel_case_classes
class App.UiElement.time_range
  @render: (attribute) ->
    ranges =
      minute: 'minute(s)'
      hour: 'hour(s)'
      day: 'day(s)'
      month: 'month(s)'
      year: 'year(s)'
    for key, value of ranges
      ranges[key] = App.i18n.translateInline(value)

    values = {}
    for count in [0..31]
      values[count.toString()] = count.toString()

    $( App.view('generic/time_range')( attribute: attribute, ranges: ranges, values: values ) )
