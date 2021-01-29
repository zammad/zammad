class AppConfigUpdate
  constructor: ->
    App.Event.bind(
      'config_update'
      (data) ->
        App.Config.set(data.name, data.value)
        App.Event.trigger('config_update_local', data)
    )

  release: ->
    App.Event.unbind('config_update')

App.Config.set('app_config_update', AppConfigUpdate, 'Plugins')
