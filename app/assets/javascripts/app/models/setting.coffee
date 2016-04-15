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
    setting.save(options)
    App.Config.set(name, value)
