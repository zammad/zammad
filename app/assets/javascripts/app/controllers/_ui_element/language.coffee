# coffeelint: disable=camel_case_classes
class App.UiElement.language extends App.UiElement.ApplicationUiElement
  @render: (attributeConfig, params) ->
    attribute = $.extend(true, {}, attributeConfig)

    # build options list
    if _.isEmpty(attribute.options)
      attribute.options = App.Locale.all().map (locale) ->
        { name: locale.name, value: locale.locale }

    if attribute.show_system_default_option
      locale_default_name = App.Locale.findByAttribute('locale', App.Config.get('locale_default')).name
      attribute.options.unshift({ name: App.i18n.translatePlain('System default - %s', locale_default_name), value: 'system' })

    # set default value
    attribute.default = if attribute.show_system_default_option then 'system' else App.Config.get('locale_default')

    if _.isEmpty(attribute.value)
      attribute.value = if attribute.show_system_default_option then 'system' else attribute.default

    # set translate
    attribute.translate = true

    # build options list based on config
    @getConfigOptionList(attribute, params)

    # sort attribute.options
    @sortOptions(attribute, params)

    # find selected/checked item of list
    @selectedOptions(attribute, params)

    # disable item of list
    @disabledOptions(attribute, params)

    # filter attributes
    @filterOption(attribute, params)

    new App.SearchableSelect(attribute: attribute).element()
