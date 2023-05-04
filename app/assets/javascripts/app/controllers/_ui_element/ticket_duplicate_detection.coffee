# coffeelint: disable=camel_case_classes
class App.UiElement.ticket_duplicate_detection extends App.UiElement.ApplicationUiElement
  warningVisible: false

  @render: (attribute, params = {}) ->
    @el = $( App.view('generic/ticket_duplicate_detection')( attribute: attribute ) )

    # Bind a custom function to a data attribute for later.
    @el.data('handleValue', @handleValue)

    # Display a warning in case there is already some data present.
    @handleValue(params[attribute.name])

    @el

  @handleValue: (data) =>
    return @hideWarning() if data is undefined || !data.count

    @showWarning(data)

  @hideWarning: ->
    return if not @warningVisible

    @el.addClass('hide')

    @warningVisible = false

  @showWarning: (data) ->
    @warning = $( App.view('generic/ticket_duplicate_detection/warning')( items: data.items or [] ) )

    @el
      .html(@warning)
      .removeClass('hide')

    # Initialize collapse on the overflow element.
    @el.find('.js-collapse')
      .collapse()
      .removeClass('hide')

    @bindEvents()

    @warningVisible = true

    # Scroll the warning into view if needed.
    if App.Browser.detection().browser?.name is 'Explorer'
      @el.get(0).scrollIntoView(true)
    else
      @el.get(0).scrollIntoView(behavior: 'smooth')

  @bindEvents: ->
    @el.find('.js-close').on('click', (e) =>
      e.preventDefault()

      @hideWarning()
    )

    @el.find('.js-toggleCollapse').on('click', (e) =>
      e.preventDefault()

      @toggleCollapse()
    )

  @toggleCollapse: ->
    @el.find('.js-collapse')
      .collapse('toggle')

    if @seeMoreOpen
      @label = App.i18n.translateContent('See more')
      @seeMoreOpen = false
    else
      @label = App.i18n.translateContent('See less')
      @seeMoreOpen = true

    @el.find('.js-toggleCollapse').html(@label)
