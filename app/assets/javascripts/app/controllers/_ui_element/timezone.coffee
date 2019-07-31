# coffeelint: disable=camel_case_classes
class App.UiElement.timezone extends App.UiElement.ApplicationUiElement
  @render: (attribute, params) ->

    attribute.options = []
    timezones = App.Config.get('timezones')

    # build list based on config
    for timezone_value, timezone_diff of timezones
      if timezone_diff > 0
        timezone_diff = '+' + timezone_diff
      item =
        name:  "#{timezone_value} (GMT#{timezone_diff})"
        value: timezone_value
      attribute.options.push item

    # add null selection if needed
    @addNullOption(attribute, params)

    # sort attribute.options
    @sortOptions(attribute, params)

    # find selected/checked item of list
    @selectedOptions(attribute, params)

    attribute.tag =        'searchable_select'
    attribute.placeholder = App.i18n.translateInline('Enter timezone...')
    App.UiElement.searchable_select.render(attribute)
