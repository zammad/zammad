class App.SettingsForm extends App.Controller
  events:
    'submit form': 'update'

  constructor: ->
    super

    # check authentication
    @authenticateCheckRedirect()

    App.Setting.fetchFull(
      @render
      force: false
    )

  render: =>

    # search area settings
    settings = App.Setting.search(
      filter:
        area: @area
    )

    # filter online service settings
    if App.Config.get('system_online_service')
      settings = _.filter(settings, (setting) ->
        return if setting.online_service
        return if setting.preferences && setting.preferences.online_service_disable
        setting
      )
      return if _.isEmpty(settings)

    # filter disabled settings
    settings = _.filter(settings, (setting) ->
      return if setting.preferences && setting.preferences.disabled
      setting
    )

    # sort by prio
    settings = _.sortBy( settings, (setting) ->
      return if !setting.preferences
      setting.preferences.prio
    )

    localEl = $( App.view('settings/form')(
      settings: settings
    ))

    for setting in settings
      configure_attributes = setting.options['form']
      value = App.Setting.get(setting.name)
      params = {}
      params[setting.name] = value
      new App.ControllerForm(
        el: localEl.find("[data-name=#{setting.name}]")
        model: { configure_attributes: configure_attributes }
        params: params
      )
    @html localEl

  update: (e) =>
    e.preventDefault()
    #e.stopPropagation()
    @formDisable(e)
    params = @formParam(e.target)

    ui = @
    count = 0
    for name, value of params
      if App.Setting.findByAttribute('name', name)
        count += 1
        App.Setting.set(
          name,
          value,
          done: ->
            ui.formEnable(e)
            count -= 1
            if count == 0
              App.Event.trigger('notify', {
                type:    'success'
                msg:     App.i18n.translateContent('Update successful!')
                timeout: 2000
              })

            # rerender ui || get new collections and session data
            App.Setting.preferencesPost(@)

          fail: (settings, details) ->
            App.Event.trigger('notify', {
              type:    'error'
              msg:     App.i18n.translateContent(details.error_human || details.error || 'Unable to update object!')
              timeout: 2000
            })
        )
