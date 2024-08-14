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
            msg:     __('Update successful.')
            timeout: 2000
          }
        App.Setting.preferencesPost(@)
        if options.doneLocal
          options.doneLocal(@)

    if !options.fail
      options.fail = (settings, details) ->
        App.Event.trigger 'notify', {
          type:    'error'
          msg:     details?.error_human || details?.error || __('The setting could not be updated.')
          timeout: 3000
        }
        if options.failLocal
          options.failLocal(@)
    if setting.frontend
      App.Config.set(name, value)
    setting.save(options)

  @reset: (name, callback, options = {}) ->
    setting = App.Setting.findByAttribute('name', name)
    throw "No such setting '#{name}' found!" if !setting

    App.Ajax.request(
      type: 'POST'
      url: "#{@url}/reset/#{setting.id}"
      processData: true,
      success: (data, status, xhr) ->
        if setting.frontend
          App.Config.set(name, setting.state_initial.value)

        if data.assets
          App.Collection.loadAssets(data.assets, targetModel: @className)
        else
          setting.refresh(data)

        if options.notify
          App.Event.trigger 'notify', {
            type:    'success'
            msg:     __('Reset successful.')
            timeout: 2000
          }
      error: (xhr, statusText, error) ->
        given_error = xhr.responseJSON?.error || statusText || error

        App.Event.trigger 'notify', {
          type:    'error'
          msg:     given_error || __('The setting could not be reset.')
          timeout: 3000
        }
    )

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
