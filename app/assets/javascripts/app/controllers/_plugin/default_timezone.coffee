class DefaultTimezone extends App.Controller
  constructor: ->
    super

    @delay(@setTimezoneIfNeeded, 8500, 'default_timezone')

  setTimezoneIfNeeded: =>
    return if !_.isEmpty(App.Config.get('timezone_default'))

    timezone = App.i18n.detectBrowserTimezone()
    return if !timezone

    return if !@permissionCheck('admin.system')

    App.Setting.fetchFull(
      => @updateSetting(timezone)
      force: false
    )

  updateSetting: (timezone) ->
    App.Setting.set('timezone_default', timezone)

App.Config.set('default_timezone', DefaultTimezone, 'Plugins')
