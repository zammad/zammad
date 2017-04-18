class App.Setting extends App.Model
  @configure 'Setting', 'name', 'state_current'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/settings'

  @get: (name) ->
    setting = App.Setting.findByAttribute('name', name)
    throw "No such setting '#{name}' found!" if !setting
    setting.state_current.value

  @set: (name, value, options = {}) ->
    setting = App.Setting.findByAttribute('name', name)
    throw "No such setting '#{name}' found!" if !setting
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
        if options.doneLocal
          options.doneLocal(@)

    if !options.fail
      options.fail = (settings, details) ->
        App.Event.trigger 'notify', {
          type:    'error'
          msg:     App.i18n.translateContent(details.error_human || details.error || 'Unable to update object!')
          timeout: 2000
        }
        if options.failLocal
          options.failLocal(@)
    if setting.frontend
      App.Config.set(name, value)
    setting.save(options)

  @preferencesPost: (setting) ->
    return if !setting.preferences
    if setting.preferences.render
      setting.preferences.trigger ||= []
      setting.preferences.trigger.push 'ui:rerender'

    return if _.isEmpty(setting.preferences.trigger)
    events = setting.preferences.trigger
    if !_.isArray(setting.preferences.trigger)
      events = [setting.preferences.trigger]

    count = 0
    for event in events
      count += 1
      do (event, count) ->
        delay = ->
          App.Event.trigger(event)
        App.Delay.set(delay, 300 * count)
