class App.SettingsAreaTicketNumber extends App.Controller
  events:
    'submit form': 'update'

  constructor: ->
    super
    @render()

  render: =>

    # defaults
    directValue = 0
    for item in @setting.options['form']
      directValue += 1
    if directValue > 1
      for item in @setting.options['form']
        item['default'] = @setting.state_current.value[item.name]
    else
      item['default'] = @setting.state_current.value

    @map =
      'Ticket::Number::Increment': 'ticket_number_increment'
      'Ticket::Number::Date': 'ticket_number_date'

    # form
    @configure_attributes = @setting.options['form']

    # item
    @html App.view('settings/ticket_number')(
      setting: @setting
    )

    togglePreferences = (params, attribute, @attributes, classname, form) =>
      return if attribute.name isnt 'ticket_number'
      @showPreferences(params.ticket_number)

    updatePreview = (params, attribute) =>
      paramsParent = @formParam(@$('.js-form'))
      number = "#{App.Config.get('ticket_hook')}???"
      if paramsParent.ticket_number is 'Ticket::Number::Increment'
        paramsItem = @paramsPreferences('Ticket::Number::Increment')
        number     = "#{App.Config.get('ticket_hook')}#{App.Config.get('system_id')}"
        counter    = '1'
        if paramsItem.min_size
          minSize = parseInt(paramsItem.min_size) - "#{App.Config.get('system_id')}".length
          if paramsItem.checksum
            minSize -= 1
          if minSize > 1
            for itemCounter in [2 .. minSize]
              counter = "0#{counter}"
        number += counter
        if paramsItem.checksum
          number += '9'
      else if paramsParent.ticket_number is 'Ticket::Number::Date'
        paramsItem   = @paramsPreferences('Ticket::Number::Date')
        current      = new Date()
        currentDay   = current.getDate()
        currentMonth = current.getMonth() + 1
        currentYear  = current.getFullYear()

        number = "#{App.Config.get('ticket_hook')}#{currentYear}#{currentMonth}#{currentDay}#{App.Config.get('system_id')}001"
        if paramsItem.checksum
          number += '9'

      @$('.js-preview').text(number)

    new App.ControllerForm(
      el: @el.find('.js-form'),
      model: { configure_attributes: @configure_attributes, className: '' }
      autofocus: false
      handlers: [togglePreferences, updatePreview]
    )

    # preferences
    preferences_settings = @setting.preferences.settings_included || ['ticket_number_increment', 'ticket_number_date']
    for preferences_setting in preferences_settings
      setting = App.Setting.findByAttribute('name', preferences_setting)
      value = App.Setting.get(preferences_setting)
      el = $(App.view("settings/#{preferences_setting}")(
        setting: setting
      ))
      new App.ControllerForm(
        el: el.find('.js-formItem'),
        model: { configure_attributes: setting.options['form'], className: '' }
        autofocus: false
        params: value
        handlers: [updatePreview]
      )
      @$('.js-formPreferences').append(el)

    # show current preferences
    @showPreferences(item['default'])

  showPreferences: (name) =>
    @$('.js-formPreferencesItem').addClass('hidden')
    @$(".js-formPreferencesItem[data-backend=\"#{name}\"]").removeClass('hidden')

  paramsPreferences: (name) =>
    @formParam(@$(".js-formPreferencesItem[data-backend=\"#{name}\"] form"))

  update: (e) =>
    e.preventDefault()
    @formDisable(@$('.js-form'))
    params = @formParam(@$('.js-form'))
    if params.ticket_number
      paramsItem = @paramsPreferences(params.ticket_number)
      setting_name = @map[params.ticket_number]
      if setting_name && paramsItem
        App.Setting.set(setting_name, paramsItem)

    @setting['state_current'] = {value: params.ticket_number}
    ui = @
    @setting.save(
      done: =>
        ui.formEnable(e)
        App.Event.trigger 'notify', {
          type:    'success'
          msg:     App.i18n.translateContent('Update successful!')
          timeout: 2000
        }

        # rerender ui || get new collections and session data
        App.Setting.preferencesPost(@setting)

      fail: (settings, details) ->
        ui.formEnable(e)
        App.Event.trigger 'notify', {
          type:    'error'
          msg:     App.i18n.translateContent(details.error_human || details.error || 'Unable to update object!')
          timeout: 2000
        }
    )
