class TranslationSupport extends App.Controller
  constructor: ->
    super

    check = =>

      # only show if system is already up and running
      return if !@Config.get('system_init_done')

      # to not translate en
      return if !App.i18n.notTranslatedFeatureEnabled(App.i18n.get())

      # only show for admins
      return if !@permissionCheck('admin.translation')

      # do not show in setup screens
      return if window.location.hash.toString().match(/getting/)

      # verify current state of translation
      meta    = App.i18n.meta()
      percent = parseInt( meta.translated / (meta.total / 100) )
      return if percent > 95

      # show message
      new Modal(percent: percent)

    @controllerBind('i18n:language:change', =>
      @delay(check, 2500, 'translation_support')
    )
    if App.Session.get() isnt undefined
      @delay(check, 2500, 'translation_support')

App.Config.set( 'translaton_support', TranslationSupport, 'Plugins' )

class Modal extends App.ControllerModal
  buttonClose: true
  buttonCancel: 'No Thanks!'
  buttonSubmit: 'Complete translations'
  head: 'Help to improve Zammad!'
  shown: false

  constructor: ->
    super
    return if App.LocalStorage.get('translation_support_no', @Session.get('id'))
    @render()

  content: =>
    better = false
    if @percent > 80
      better = true
    App.view('translation/support')(
      percent: @percent
      better: better
    )

  onCancel: =>
    App.LocalStorage.set('translation_support_no', true, @Session.get('id'))
    @close()

  onSubmit: =>
    @navigate '#system/translation'
    @close()
