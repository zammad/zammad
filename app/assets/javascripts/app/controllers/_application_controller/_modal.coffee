class App.ControllerModal extends App.Controller
  authenticateRequired: false
  backdrop: true
  keyboard: true
  large: false
  small: false
  veryLarge: false
  head: '?'
  autoFocusOnFirstInput: true
  container: null
  buttonClass: 'btn--success'
  centerButtons: []
  leftButtons: []
  buttonClose: true
  buttonCancel: false
  buttonCancelClass: 'btn--text btn--subtle'
  buttonSubmit: true
  includeForm: true
  headPrefix: ''
  shown: true
  closeOnAnyClick: false
  initalFormParams: {}
  initalFormParamsIgnore: false
  showTrySupport: false
  showTryMax: 10
  showTrydelay: 1000

  events:
    'submit form':                        'submit'
    'click .js-submit:not(.is-disabled)': 'submit'
    'click .js-cancel':                   'cancel'
    'click .js-close':                    'cancel'

  className: 'modal fade'

  constructor: ->
    super
    @showTryCount = 0

    if @authenticateRequired
      return if !@authenticateCheckRedirect()

    # rerender view, e. g. on langauge change
    @controllerBind('ui:rerender', =>
      @update()
      'modal'
    )
    if @shown
      @render()

  showDelayed: =>
    delay = =>
      @showTryCount += 1
      @render()
    @delay(delay, @showTrydelay)

  modalAlreadyExists: ->
    return true if $('.modal').length > 0
    false

  content: ->
    'You need to implement a one @content()!'

  update: =>
    if @message
      content = App.i18n.translateContent(@message)
    else if @contentInline
      content = @contentInline
    else
      content = @content()
    modal = $(App.view('modal')(
      head:              @head
      headPrefix:        @headPrefix
      message:           @message
      detail:            @detail
      buttonClose:       @buttonClose
      buttonCancel:      @buttonCancel
      buttonCancelClass: @buttonCancelClass
      buttonSubmit:      @buttonSubmit
      buttonClass:       @buttonClass
      centerButtons:     @centerButtons
      leftButtons:       @leftButtons
      includeForm:       @includeForm
    ))
    modal.find('.modal-body').html(content)
    if !@initRenderingDone
      @initRenderingDone = true
      @html(modal)
    else
      @$('.modal-dialog').replaceWith(modal)
    @post()

  post: ->
    # nothing

  element: =>
    @el

  render: =>
    if @showTrySupport is true && @modalAlreadyExists() && @showTryCount <= @showTryMax
      @showDelayed()
      return

    @initalFormParamsIgnore = false

    if @buttonSubmit is true
      @buttonSubmit = 'Submit'
    if @buttonCancel is true
      @buttonCancel = 'Cancel & Go Back'

    @update()

    if @container
      @el.addClass('modal--local')
    if @veryLarge
      @el.addClass('modal--veryLarge')
    if @large
      @el.addClass('modal--large')
    if @small
      @el.addClass('modal--small')

    @el
      .on(
        'show.bs.modal':   @localOnShow
        'shown.bs.modal':  @localOnShown
        'hide.bs.modal':   @localOnClose
        'hidden.bs.modal': @localOnClosed
        'dismiss.bs.modal': @localOnCancel
      ).modal(
        keyboard:  @keyboard
        show:      true
        backdrop:  @backdrop
        container: @container
      )

    if @closeOnAnyClick
      @el.on('click', =>
        @close()
      )

  close: (e) =>
    if e
      e.preventDefault()
    @initalFormParamsIgnore = true
    @el.modal('hide')

  formParams: =>
    if @container
      return @formParam(@container.find('.modal form'))
    return @formParam(@$('.modal form'))

  showAlert: (message, suffix = 'danger') ->
    alert = $('<div>')
      .addClass("alert alert--#{suffix}")
      .text(message)

    @$('.modal-alerts-container').html(alert)

  clearAlerts: ->
    @$('.modal-alerts-container').empty()

  localOnShow: (e) =>
    @onShow(e)

  onShow: (e) ->
    # do nothing

  localOnShown: (e) =>
    @onShown(e)

  onShown: (e) =>
    if @autoFocusOnFirstInput

      # select generated form
      form = @$('.form-group').first()

      # if not exists, use whole @el
      if !form.get(0)
        form = @el

      # focus first input, select or textarea
      form.find('input:not([disabled]):not([type="hidden"]):not(".btn"), select:not([disabled]), textarea:not([disabled])').first().focus()

    @initalFormParams = @formParams()

  localOnClose: (e) =>
    diff = difference(@initalFormParams, @formParams())
    if @initalFormParamsIgnore is false && !_.isEmpty(diff)
      if !confirm(App.i18n.translateContent('The form content has been changed. Do you want to close it and lose your changes?'))
        e.preventDefault()
        return
    @onClose(e)

  onClose: ->
    # do nothing

  localOnClosed: (e) =>
    @onClosed(e)
    @el.modal('remove')

  onClosed: (e) ->
    # do nothing

  localOnCancel: (e) =>
    @onCancel(e)

  onCancel: (e) ->
    # do nothing

  cancel: (e) =>
    @close(e)
    @onCancel(e)

  onSubmit: (e) ->
    # do nothing

  submit: (e) =>
    e.stopPropagation()
    e.preventDefault()
    @clearAlerts()
    @onSubmit(e)

  startLoading: =>
    @$('.modal-body').addClass('hide')
    @$('.modal-loader').removeClass('hide')

  stopLoading: =>
    @$('.modal-body').removeClass('hide')
    @$('.modal-loader').addClass('hide')
