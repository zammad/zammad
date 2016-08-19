class App.SettingsAreaItem extends App.Controller
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

    # form
    @configure_attributes = @setting.options['form']

    # item
    @html App.view('settings/item')(
      setting: @setting
    )

    new App.ControllerForm(
      el: @el.find('.form-item'),
      model: { configure_attributes: @configure_attributes, className: '' }
      autofocus: false
    )

  update: (e) =>
    e.preventDefault()
    @formDisable(e)
    params = @formParam(e.target)

    directValue = 0
    directData  = undefined
    for item in @setting.options['form']
      directValue += 1
      directData  = params[item.name]

    if directValue > 1
      state_current = {
        value: params
      }
      #App.Config.set((@setting.name, params)
    else
      state_current = {
        value: directData
      }
      #App.Config.set(@setting.name, directData)

    @setting['state_current'] = state_current
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
