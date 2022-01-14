class DefaultLocale extends App.Controller
  constructor: ->
    super

    check = =>

      preferences = App.Session.get('preferences')
      return if !preferences
      return if !_.isEmpty(preferences.locale)
      locale = App.i18n.get()
      @ajax(
        id:          "i18n-set-user-#{locale}"
        type:        'PUT'
        url:         "#{App.Config.get('api_path')}/users/preferences"
        data:        JSON.stringify(locale: locale)
        processData: true
      )

    if App.Session.get() isnt undefined
      @delay(check, 3500, 'default_locale')

App.Config.set('default_locale', DefaultLocale, 'Plugins')
