# coffeelint: disable=camel_case_classes
# Base class for providing date picker. Must be extended
class App.UiElement.basedate
  @templateName: ->
    throw 'Must override in a subclass'

  @render: (attributeOrig) ->
    attribute = _.clone(attributeOrig)
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
      weekStart: 1
      autoclose: true
      todayBtn: 'linked'
      todayHighlight: true
      format: App.i18n.timeFormat().date
      rtl: App.i18n.dir() is 'rtl'
      container: item
      language: 'custom'
    )

    @setNewTimeInitial(item, attribute)

  # observer changes / update needed to forece rerender to get correct today shown
  @bindEvents: (item, attribute) ->
    item
      .find('input')
      .bind('focus', (e) ->
        item.find('.js-datepicker').datepicker('rerender')
      ).bind('keyup blur change', (e) =>
        @setNewTime(item, attribute, 0)
        @validation(item, attribute, true)
      )

    item.bind('validate', (e) =>
      @validation(item, attribute)
    )

  @setNewTime: (item, attribute, tolerant = false) ->
    currentInput = @currentInput(item, attribute)
    return if !currentInput

    if !@validateInput(currentInput)
      item.find("[name=\"#{attribute.name}\"]").val('')
      return

    item.find("[name=\"#{attribute.name}\"]").val(@buildTimestamp(currentInput))

  # returns array with date or false if cannot get date
  @currentInput: (item, attribute) ->
    datetime = item.find('.js-datepicker').datepicker('getDate')
    if !datetime || datetime.toString() is 'Invalid Date'
      item.find("[name=\"#{attribute.name}\"]").val('')
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
    timestamp = item.find("[name=\"#{attribute.name}\"]").val()
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

    timestamp = item.find("[name=\"#{attribute.name}\"]").val()

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
      days: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
      daysMin: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      daysShort: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      months: ['January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'],
      monthsShort: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
      today: 'today',
      clear: 'clear'
    }

    App.i18n.translateDeep(data)
