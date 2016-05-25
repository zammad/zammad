class Widget extends App.Controller
  constructor: ->
    super

    App.Event.bind(
      'config_update'
      (data) ->
        App.Config.set(data.name, data.value)
        App.Event.trigger('config_update_local', data)
    )

App.Config.set('app_config_update', Widget, 'Widgets')
