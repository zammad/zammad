# coffeelint: disable=camel_case_classes
class App.UiElement.holiday_selector
  @render: (attribute, params) ->
    console.log('aa', attribute)
    days = {}
    if attribute.value
      days = attribute.value
      days_sorted = _.keys(days).sort()
      days_new = {}
      for day in days_sorted
        days_new[day] = days[day]

    item = $( App.view('calendar/holiday_selector')( attribute: attribute, days: days_new ) )