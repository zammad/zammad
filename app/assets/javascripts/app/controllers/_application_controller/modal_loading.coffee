class App.ControllerModalLoading extends App.Controller
  className: 'modal fade'
  showTrySupport: true

  constructor: ->
    super

    if @container
      @el.addClass('modal--local')

    @render()

    @el.modal(
      keyboard:  false
      show:      true
      backdrop:  'static'
      container: @container
    ).on(
      'hidden.bs.modal': @localOnClosed
    )

  render: ->
    @html App.view('generic/modal_loader')(
      head: @head
      message: App.i18n.translateContent(@message)
    )

  update: (message, translate = true) =>
    if translate
      message = App.i18n.translateContent(message)
    @$('.js-loading').html(message)

  hideIcon: =>
    @$('.js-loadingIcon').addClass('hide')

  showIcon: =>
    @$('.js-loadingIcon').removeClass('hide')

  localOnClosed: =>
    @el.remove()

  hide: (delay) =>
    remove = =>
      @el.modal('hide')
    if !delay
      remove()
      return
    App.Delay.set(remove, delay * 1000)
