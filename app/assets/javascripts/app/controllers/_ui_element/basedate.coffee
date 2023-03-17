# coffeelint: disable=camel_case_classes
# Base class for providing date picker. Must be extended
class App.UiElement.basedate
  @templateName: ->
    throw 'Must override in a subclass'

  @render: (attributeConfig) ->
    attribute = $.extend(true, {}, attributeConfig)

    if attribute.name
      attribute.nameRaw = attribute.name
      attribute.name = "{#{@templateName()}}#{attribute.name}"

    item = $( App.view("generic/#{@templateName()}")(
      attribute: attribute
    ) )

    # set our custom template
    $.fn.datepicker.defaults.template = App.view('generic/datepicker')()

    # apply date widgets
    $.fn.datepicker.dates['custom'] = @buildCustomDates()

    @applyPickers(item, attribute)
    @bindEvents(item, attribute)

    item

  @log: (name, args...) ->
    App.Log.debug "Ui.element.#{@templateName()}.#{name}", args...

  @applyPickers: (item, attribute) ->
    item.find('.js-datepicker').datepicker(
      clearBtn: attribute.null
      weekStart: 1
      autoclose: true
      todayBtn: 'linked'
      todayHighlight: true
      format: App.i18n.timeFormat()['FORMAT_DATE']
      rtl: App.i18n.dir() is 'rtl'
      container: item
      language: 'custom'
      orientation: attribute.orientation
      disableScroll: attribute.disableScroll
      calendarWeeks: App.Config.get('datepicker_show_calendar_weeks')
    )

    @setNewTimeInitial(item, attribute)

  # observer changes / update needed to force rerender to get correct today shown
  @bindEvents: (item, attribute) ->
    item
      .find('input')
      .on('focus', (e) ->
        item.find('.js-datepicker').datepicker('rerender')
      ).on('keyup blur change', (e) =>
        @setNewTime(item, attribute, 0)
        @validation(item, attribute, true)
      )

    item.on('validate', (e) =>
      @validation(item, attribute)
    )

  @inputElement: (item, attribute) ->
    if attribute.name
      return item.find("[name=\"#{attribute.name}\"]")
    return item.find('input[type="hidden"]')

  @setNewTime: (item, attribute, tolerant = false) ->
    currentInput = @currentInput(item, attribute)
    return if !currentInput

    if !@validateInput(currentInput)
      @inputElement(item, attribute).val('')
      return

    @inputElement(item, attribute).val(@buildTimestamp(currentInput))

  # returns array with date or false if cannot get date
  @currentInput: (item, attribute) ->
    datetime = item.find('.js-datepicker').datepicker('getDate')
    if !datetime || datetime.toString() is 'Invalid Date'
      @inputElement(item, attribute).val('')
      return false

    @log 'setNewTime', datetime

    year  = datetime.getFullYear()
    month = datetime.getMonth() + 1
    day   = datetime.getDate()
    date  = "#{App.Utils.formatTime(year)}-#{App.Utils.formatTime(month,2)}-#{App.Utils.formatTime(day,2)}"
    [date]

  @validateInput: (currentInput) ->
    currentInput[0] isnt ''

  @buildTimestamp: (currentInput) ->
    throw 'Must override in a subclass'

  @dateSetter: ->
    throw 'Must override in a subclass'

  @setNewTimeInitial: (item, attribute) ->
    timestamp = @inputElement(item, attribute).val()
    @log 'setNewTimeInitial', timestamp
    if !timestamp
      @setNoTimestamp(item)
      return

    timeObject = new Date( Date.parse( timestamp ) )

    @log 'setNewTimeInitial', timestamp, timeObject
    @setTimestamp(item, timeObject)
    item.find('.js-datepicker').datepicker('update')

  @setNoTimestamp: (item) ->
    return

  @setTimestamp: (item, timeObject) ->
    item.find('.js-datepicker').datepicker(@dateSetter(), timeObject)

  @validation: (item, attribute, runtime) ->
    # remove old validation
    if attribute.validationContainer is 'self'
      item.find('.js-datepicker').removeClass('has-error')
    else
      item.closest('.form-group').removeClass('has-error')
      item.find('.has-error').removeClass('has-error')
      item.find('.help-inline').html('')
      item.closest('.form-group').find('.help-inline').html('')

    timestamp = @inputElement(item, attribute).val()

    # check required attributes
    errors = {}
    if !timestamp
      if !attribute.null
        errors[attribute.name] = 'missing'
    else
      timeObject = new Date( Date.parse( timestamp ) )


    @log 'validation', errors
    return if _.isEmpty(errors)

    # show invalid options
    if attribute.validationContainer is 'self'
      item.find('.js-datepicker').addClass('has-error')
    else
      formGroup = item.closest('.form-group')
      for key, value of errors
        formGroup.addClass('has-error')

  @buildCustomDates: ->
    data = {
      days: [__('Sunday'), __('Monday'), __('Tuesday'), __('Wednesday'), __('Thursday'), __('Friday'), __('Saturday')],
      daysMin: [__('Sun'), __('Mon'), __('Tue'), __('Wed'), __('Thu'), __('Fri'), __('Sat')],
      daysShort: [__('Sun'), __('Mon'), __('Tue'), __('Wed'), __('Thu'), __('Fri'), __('Sat')],
      months: [__('January'), __('February'), __('March'), __('April'), __('May'), __('June'),
        __('July'), __('August'), __('September'), __('October'), __('November'), __('December')],
      monthsShort: [__('Jan'), __('Feb'), __('Mar'), __('Apr'), __('May'), __('Jun'), __('Jul'), __('Aug'), __('Sep'), __('Oct'), __('Nov'), __('Dec')],
      today: __('today'),
      clear: __('clear')
    }

    App.i18n.translateDeepPlain(data)
