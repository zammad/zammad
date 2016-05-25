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
        if options.notify
          App.Event.trigger 'notify', {
            type:    'success'
            msg:     App.i18n.translateContent('Update successful!')
            timeout: 2000
          }
        App.Setting.preferencesPost(@)

    if !options.fail
      options.fail = (settings, details) ->
        App.Event.trigger 'notify', {
          type:    'error'
          msg:     App.i18n.translateContent(details.error_human || details.error || 'Unable to update object!')
          timeout: 2000
        }
    App.Config.set(name, value)
    setting.save(options)

  @preferencesPost: (setting) ->
    return if !setting.preferences
    if setting.preferences.render
      App.Event.trigger('ui:rerender')

    if setting.preferences.trigger
      events = setting.preferences.trigger
      if !_.isArray(setting.preferences.trigger)
        events = [setting.preferences.trigger]
      delay = ->
        for event in events
          App.Event.trigger(event)
      App.Delay.set(delay, 20)

    if setting.preferences.session_check
      App.Auth.loginCheck()
