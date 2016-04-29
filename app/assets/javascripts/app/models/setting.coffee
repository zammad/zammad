class App.Setting extends App.Model
  @configure 'Setting', 'name', 'state_current'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/settings'

  @get: (name) ->
    setting = App.Setting.findByAttribute('name', name)
    setting.state_current.value

  @set: (name, value, options = {}) ->
    setting = App.Setting.findByAttribute('name', name)
    setting.state_current.value = value
    if !options.done
      options.done = ->
        App.Setting.preferencesPost(@)

    if !options.fail
      options.fail = (settings, details) ->
        App.Event.trigger 'notify', {
          type:    'error'
          msg:     App.i18n.translateContent(details.error_human || details.error || 'Unable to update object!')
          timeout: 2000
        }
    setting.save(options)
    App.Config.set(name, value)

  @preferencesPost: (setting) ->
    return if !setting.preferences
    if setting.preferences.render
      App.Event.trigger('ui:rerender')

    if setting.preferences.trigger
      trigger = setting.preferences.trigger
      delay = -> App.Event.trigger(trigger)
      App.Delay.set(delay, 20)

    if setting.preferences.session_check
      App.Auth.loginCheck()
