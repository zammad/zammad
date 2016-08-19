class App.SettingsAreaSwitch extends App.Controller
  events:
    'change .js-setting input': 'toggleSetting'
    'submit form': 'update'

  elements:
    '.js-setting input': 'uiSetting'

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

    # form
    @configure_attributes = @setting.options['form']

    @subSetting = []
    for localSetting in @setting.preferences.sub
      @subSetting.push App.Setting.findByAttribute('name', localSetting)

    # item
    @html App.view('settings/switch')(
      checked: App.Setting.get(@setting.name)
      setting: @setting
      subSetting: @subSetting
    )
    for localSetting in @subSetting
      new App.ControllerForm(
        el: @$('.form-item')
        params: localSetting.state_current.value
        model: { configure_attributes: localSetting.options['form'], className: '' }
        autofocus: false
      )

  toggleSetting: =>
    value = @uiSetting.prop('checked')
    App.Setting.set(@setting.name, value)

  update: (e) =>
    e.preventDefault()
    @formDisable(e)
    params = @formParam(e.target)

    localSetting = $(e.currentTarget).data('name')
    setting = App.Setting.findByAttribute('name', localSetting)

    directValue = 0
    directData  = undefined
    for item in setting.options['form']
      directValue += 1
      directData  = params[item.name]

    if directValue > 1
      state_current = {
        value: params
      }
      #App.Config.set((setting.name, params)
    else
      state_current = {
        value: directData
      }
      #App.Config.set(setting.name, directData)

    setting['state_current'] = state_current
    ui = @
    setting.save(
      done: ->
        ui.formEnable(e)
        App.Event.trigger 'notify', {
          type:    'success'
          msg:     App.i18n.translateContent('Update successful!')
          timeout: 2000
        }

        # rerender ui || get new collections and session data
        App.Setting.preferencesPost(setting)

      fail: (settings, details) ->
        ui.formEnable(e)
        App.Event.trigger 'notify', {
          type:    'error'
          msg:     App.i18n.translateContent(details.error_human || details.error || 'Unable to update object!')
          timeout: 2000
        }
    )
