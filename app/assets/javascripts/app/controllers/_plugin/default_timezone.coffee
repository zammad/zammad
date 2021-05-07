class DefaultTimezone extends App.Controller
  constructor: ->
    super

    check = =>
      timezone = App.i18n.detectBrowserTimezone()
      return if !timezone

      # check system timezone_default
      if _.isEmpty(@Config('timezone_default')) && @permissionCheck('admin.system')
        App.Setting.fetchFull(
          => @updateSetting(timezone)
          force: false
        )

      # prepare user based timezone
      # check current user timezone
      #preferences = App.Session.get('preferences')
      #return if !preferences
      #return if !_.isEmpty(preferences.timezone)
      #@ajax(
      #  id:          "i18n-set-user-timezone"
      #  type:        'PUT'
      #  url:         "#{App.Config.get('api_path')}/users/preferences"
      #  data:        JSON.stringify(timezone: timezone)
      #  processData: true
      #)

    if App.Session.get() isnt undefined
      @delay(check, 8500, 'default_timezone')

  updateSetting: (timezone) ->
    App.Setting.set('timezone_default', timezone)

App.Config.set('default_timezone', DefaultTimezone, 'Plugins')
