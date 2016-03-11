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

    values = {}
    for count in [0..31]
      values[count.toString()] = count.toString()

    $( App.view('generic/time_range')( attribute: attribute, ranges: ranges, values: values ) )
