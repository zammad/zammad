class TranslationSupport extends App.Controller
  constructor: ->
    super

    check = =>

      # only show if system is already up and running
      return if !@Config.get('system_init_done')

      # to not translate en
      return if App.i18n.notTranslatedFeatureEnabled(App.i18n.get())

      # only show for admins
      return if !@isRole('Admin')

      # verify current state of translation
      meta    = App.i18n.meta()
      percent = parseInt( meta.translated / (meta.total / 100) )
      return if percent > 95
      message = App.i18n.translateContent('Only %s% of this language is translated, help to improve Zammad and complete the translation.', percent)
      if percent > 80
        message = App.i18n.translateContent('Up to %s% of this language is translated, help to make Zammad even better and complete the translation.', percent)

      # show message
      modal = new App.ControllerModal(
        head:        App.i18n.translateContent('Help to improve Zammad!')
        message:     message
        cancel:      false
        close:       true
        shown:       true
        button:      'Complete translations'
        buttonClass: 'btn--success'
        onSubmitCallback: =>
          @navigate '#system/translation'
          modal.hide()
      )

    @bind 'i18n:language:change', =>
      @delay(check, 2500, 'translation_support')

    @bind 'auth:login', =>
      @delay(check, 2500, 'translation_support')

App.Config.set( 'translaton_support', TranslationSupport, 'Widgets' )