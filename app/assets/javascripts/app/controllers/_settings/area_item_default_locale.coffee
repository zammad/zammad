class App.SettingsAreaItemDefaultLocale extends App.SettingsAreaItem

  render: =>

    options = {}
    locales = App.Locale.all()
    for locale in locales
      options[locale.locale] = locale.name
    configure_attributes = [
      { name: 'locale_default', display: '', tag: 'searchable_select', null: false, class: 'input', options: options, default: @setting.state_current.value },
    ]

    @html App.view(@template)(
      setting: @setting
    )

    new App.ControllerForm(
      el: @el.find('.form-item')
      model: { configure_attributes: configure_attributes, className: '' }
      autofocus: false
    )
