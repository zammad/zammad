# coffeelint: disable=camel_case_classes
class App.UiElement.date
  @render: (attributeOrig) ->

    attribute = _.clone(attributeOrig)
    attribute.nameRaw = attribute.name
    attribute.name = "{date}#{attribute.name}"

    item = $( App.view('generic/date')(
      attribute: attribute
    ) )

    # set our custom template
    $.fn.datepicker.defaults.template = App.view('generic/datepicker')()

    # apply date widgets
    $.fn.datepicker.dates['custom'] =
      days: [
        App.i18n.translateInline('Sunday'),
        App.i18n.translateInline('Monday'),
        App.i18n.translateInline('Tuesday'),
        App.i18n.translateInline('Wednesday'),
        App.i18n.translateInline('Thursday'),
        App.i18n.translateInline('Friday'),
        App.i18n.translateInline('Saturday'),
        App.i18n.translateInline('Sunday'),
      ],
      daysMin: [
        App.i18n.translateInline('Sun'),
        App.i18n.translateInline('Mon'),
        App.i18n.translateInline('Tue'),
        App.i18n.translateInline('Wed'),
        App.i18n.translateInline('Thu'),
        App.i18n.translateInline('Fri'),
        App.i18n.translateInline('Sat'),
        App.i18n.translateInline('Sun')
      ],
      daysShort: [
        App.i18n.translateInline('Sun'),
        App.i18n.translateInline('Mon'),
        App.i18n.translateInline('Tue'),
        App.i18n.translateInline('Wed'),
        App.i18n.translateInline('Thu'),
        App.i18n.translateInline('Fri'),
        App.i18n.translateInline('Sat'),
        App.i18n.translateInline('Sun')
      ],
      months: [
        App.i18n.translateInline('January'),
        App.i18n.translateInline('February'),
        App.i18n.translateInline('March'),
        App.i18n.translateInline('April'),
        App.i18n.translateInline('May'),
        App.i18n.translateInline('June'),
        App.i18n.translateInline('July'),
        App.i18n.translateInline('August'),
        App.i18n.translateInline('September'),
        App.i18n.translateInline('October'),
        App.i18n.translateInline('November'),
        App.i18n.translateInline('December'),
      ],
      monthsShort: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
      today: App.i18n.translateInline('today'),
      clear: App.i18n.translateInline('clear')
    currentDate = undefined

    item.find('.js-datepicker').datepicker(
      weekStart: 1
      autoclose: true
      todayBtn: 'linked'
      todayHighlight: true
      format: App.i18n.timeFormat().date
      container: item
      language: 'custom'
    )

    # set initial date time
    @setNewTimeInitial(item, attribute)

    # observer changes / update needed to forece rerender to get correct today shown
    item.find('input').bind('focus', (e) ->
      item.find('.js-datepicker').datepicker('rerender')
    )
    item.find('input').bind('keyup blur change', (e) =>
      @setNewTime(item, attribute, 0)
      @validation(item, attribute, true)
    )
    item.bind('validate', (e) =>
      @validation(item, attribute)
    )

    item

  @setNewTime: (item, attribute, tolerant = false) ->

    datetime = item.find('.js-datepicker').datepicker('getDate')
    if !datetime || datetime.toString() is 'Invalid Date'
      App.Log.debug 'UiElement.date.setNewTime', datetime
      item.find("[name=\"#{attribute.name}\"]").val('')
      return

    App.Log.debug 'UiElement.date.setNewTime', datetime
    year  = datetime.getFullYear()
    month = datetime.getMonth() + 1
    day   = datetime.getDate()
    date  = "#{App.Utils.formatTime(year)}-#{App.Utils.formatTime(month,2)}-#{App.Utils.formatTime(day,2)}"

    if date is ''
      item.find("[name=\"#{attribute.name}\"]").val('')
      return

    App.Log.debug 'UiElement.date.setNewTime', date
    item.find("[name=\"#{attribute.name}\"]").val(date)

  @setNewTimeInitial: (item, attribute) ->
    App.Log.debug 'UiElement.date.setNewTimeInitial', timestamp
    timestamp = item.find("[name=\"#{attribute.name}\"]").val()
    return if !timestamp

    timeObject = new Date( Date.parse( timestamp ) )

    hour   = timeObject.getHours()
    minute = timeObject.getMinutes()

    App.Log.debug 'UiElement.date.setNewTimeInitial', timestamp, timeObject
    item.find('.js-datepicker').datepicker('setUTCDate', timeObject)
    item.find('.js-datepicker').datepicker('update')

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


    App.Log.debug 'UiElement.date.validation', errors
    return if _.isEmpty(errors)

    # show invalid options
    if attribute.validationContainer is 'self'
      item.find('.js-datepicker').addClass('has-error')
    else
      formGroup = item.closest('.form-group')
      for key, value of errors
        formGroup.addClass('has-error')
