# coffeelint: disable=camel_case_classes
class App.UiElement.timezone extends App.UiElement.ApplicationUiElement
  @render: (attributeConfig, params) ->
    attribute = $.extend(true, {}, attributeConfig)

    attribute.options = []
    timezones = App.Config.get('timezones')

    # build list based on config
    for timezone_value, timezone_diff of timezones
      if !timezone_diff.toString().match(/(\+|\-)/)
        timezone_diff = "+#{timezone_diff}"
      item =
        name:  "#{timezone_value} (GMT#{timezone_diff})"
        value: timezone_value
      attribute.options.push item

    if attribute.show_system_default_option
      timezone_default_name = _.find(attribute.options, (option) -> option.value == App.Config.get('timezone_default')).name
      attribute.options.unshift({ name: App.i18n.translatePlain('System default - %s', timezone_default_name), value: 'system' })

    # set default value
    attribute.default = if attribute.show_system_default_option then 'system' else App.Config.get('timezone_default')

    # add null selection if needed
    @addNullOption(attribute, params)

    # sort attribute.options
    @sortOptions(attribute, params)

    # find selected/checked item of list
    @selectedOptions(attribute, params)

    attribute.tag =        'searchable_select'
    attribute.placeholder = App.i18n.translateInline('Enter time zone')
    App.UiElement.searchable_select.render(attribute)
