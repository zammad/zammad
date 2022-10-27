class App.ControllerConfirmDelete extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: __('Delete')
  buttonClass: 'btn--danger'
  head: __('Are you sure?')
  safeWord: __('Delete')
  fieldDisplay: undefined
  small: true

  content: =>
    @controller = new App.ControllerForm(
      model: {
        configure_attributes: [
          {
            name: 'sure',
            display: @fieldDisplay,
            null: true,
            tag: 'input',
            placeholder: App.i18n.translatePlain(@safeWord).toUpperCase()
          }
        ]
      }
      autofocus: true
    )

    @controller.form

  isCheckWordMatching: =>
    input = App.ControllerForm.params(@el).sure

    input == App.i18n.translatePlain(@safeWord).toUpperCase()

  highlightError: =>
    @$('form').addClass('has-error')

  onSubmit: =>
    if !@isCheckWordMatching()
      @highlightError()
      return

    @formDisable(@controller.el)

    @callback(@)
