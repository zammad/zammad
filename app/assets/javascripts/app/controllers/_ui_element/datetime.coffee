# coffeelint: disable=camel_case_classes
class App.UiElement.datetime
  @render: (attributeOrig) ->

    attribute = _.clone(attributeOrig)
    attribute.nameRaw = attribute.name
    attribute.name = "{datetime}#{attribute.name}"

    # get time object
    if attribute.value
      if typeof attribute.value is 'string'
        time = new Date( Date.parse( attribute.value ) )
      else
        time = new Date( attribute.value )

      # time items
      year   = time.getFullYear()
      month  = time.getMonth() + 1
      day    = time.getDate()
      hour   = time.getHours()
      minute = time.getMinutes()

    # create element
    item = $( App.view('generic/datetime')(
      attribute: attribute
      year:      year
      month:     month
      day:       day
      hour:      hour
      minute:    minute
    ) )

    # start bindings
    item.find('.js-today').bind('click', (e) =>
      e.preventDefault()
      @setNewTime(item, attribute, 0, true)
      @validation(item, attribute)
    )
    item.find('.js-plus-hour').bind('click', (e) =>
      e.preventDefault()
      @setNewTime(item, attribute, 60, false, true)
      @validation(item, attribute)
    )
    item.find('.js-minus-hour').bind('click', (e) =>
      e.preventDefault()
      @setNewTime(item, attribute, -60, false, true)
      @validation(item, attribute)
    )
    item.find('.js-plus-day').bind('click', (e) =>
      e.preventDefault()
      @setNewTime(item, attribute, 60 * 24, false, true)
      @validation(item, attribute)
    )
    item.find('.js-minus-day').bind('click', (e) =>
      e.preventDefault()
      @setNewTime(item, attribute, -60 * 24, false, true)
      @validation(item, attribute)
    )
    item.find('.js-plus-week').bind('click', (e) =>
      e.preventDefault()
      @setNewTime(item, attribute, 60 * 24 * 7, false, true)
      @validation(item, attribute)
    )
    item.find('.js-minus-week').bind('click', (e) =>
      e.preventDefault()
      @setNewTime(item, attribute, -60 * 24 * 7, false, true)
      @validation(item, attribute)
    )
    item.find('input').bind('keyup blur focus change', (e) =>
      @setNewTime(item, attribute, 0)
      @validation(item, attribute, true)
    )
    item.bind('validate', (e) =>
      @validation(item, attribute)
    )
    #setShadowTimestamp()
    @setNewTime(item, attribute, 0)

    item

  @format: (number) ->
    if number isnt '' && Number(number) < 10
      number = "0#{Number(number)}"
    number

  @setNewTime: (item, attribute, diff, reset = false, tolerant = false) ->

    resetTimeToToday = =>
      time = new Date()
      time.setMinutes( time.getMinutes() + diff )
      @setParams(item, attribute, time)

    return resetTimeToToday() if reset

    params = @getParams(item)
    if params.year is '' && params.month is '' && params.day is '' && params.hour is '' && params.minute is ''
      return if !tolerant
      resetTimeToToday()
      params = @getParams(item)

    time = new Date( Date.parse( "#{params.year}-#{@format(params.month)}-#{@format(params.day)}T#{@format(params.hour)}:#{@format(params.minute)}:00Z" ) )
    time.setMinutes( time.getMinutes() + diff + time.getTimezoneOffset() )
    return if !time
    @setParams(item, attribute, time)

  @setShadowTimestamp: (item, attribute, time) ->
    timestamp = ''
    if time
      timestamp = time.toISOString().replace(/\d\d\.\d\d\dZ$/, '00.000Z')
    item.find("[name=\"#{attribute.name}\"]").val(timestamp)

  @setParams: (item, attribute, time) ->
    App.Log.debug 'UiElement.datetime.setParams', time.toString()

    if time.toString() is 'Invalid Date'
      @setShadowTimestamp(item, attribute)
      return

    day = time.getDate()
    month = time.getMonth()+1
    year = time.getFullYear()
    hour = time.getHours()
    minute = time.getMinutes()
    item.find('[data-item=day]').val(day)
    item.find('[data-item=month]').val(month)
    item.find('[data-item=year]').val(year)
    item.find('[data-item=hour]').val(hour)
    item.find('[data-item=minute]').val(minute)
    @setShadowTimestamp(item, attribute, time)

  @getParams: (item) ->
    params = {}
    params.day    = item.find('[data-item=day]').val().trim()
    params.month  = item.find('[data-item=month]').val().trim()
    params.year   = item.find('[data-item=year]').val().trim()
    params.hour   = item.find('[data-item=hour]').val().trim()
    params.minute = item.find('[data-item=minute]').val().trim()
    App.Log.debug 'UiElement.datetime.getParams', params
    params

  @validation: (item, attribute, runtime) ->

    # remove old validation
    item.closest('.form-group').removeClass('has-error')
    item.find('.has-error').removeClass('has-error')
    item.find('.help-inline').html('')
    item.closest('.form-group').find('.help-inline').html('')

    params = @getParams(item)

    # check required attributes
    errors = {}
    if !runtime && !attribute.null
      if params.day is ''
        errors.day = 'missing'
      if params.month is ''
        errors.month = 'missing'
      if params.year is ''
        errors.year = 'missing'
      if params.hour is ''
        errors.hour = 'missing'
      if params.minute is ''
        errors.minute = 'missing'

    # ranges
    if params.day
      daysInMonth = 31
      if params.month && params.year
        daysInMonth = new Date(params.year, params.month, 0).getDate()

      if isNaN( Number(params.day) )
        errors.day = 'invalid'
      else if Number(params.day) > daysInMonth || Number(params.day) < 1
        errors.day = 'invalid'

    if params.month
      if isNaN( Number(params.month) )
        errors.month = 'invalid'
      else if Number(params.month) > 12 || Number(params.month) < 1
        errors.month = 'invalid'

    if params.year
      if isNaN( Number(params.year) )
        errors.year = 'invalid'
      else if Number(params.year) > 2200 || Number(params.year) < 2001
        errors.year = 'invalid'

    if params.hour
      if isNaN( Number(params.hour) )
        errors.hour = 'invalid'
      else if parseInt(params.hour) > 23 || parseInt(params.hour) < 0
        errors.hour = 'invalid'

    if params.minute
      if isNaN( Number(params.minute) )
        errors.minute = 'invalid'
      else if Number(params.minute) > 59
        errors.minute = 'invalid'

    #formGroup = item.closest('.form-group')
    formGroup = item
    App.Log.debug 'UiElement.datetime.validation', errors
    if !_.isEmpty(errors)

      # if field is required, if not do not show error
      if params.year is '' && params.day is '' && params.month is '' && params.hour is '' && params.minute is ''
        return if attribute.null
        item.closest('.form-group').addClass('has-error')
        item.closest('.form-group').find('.help-inline').text( 'is required' )
        return

      # show invalid options
      for key, value of errors
        formGroup.addClass('has-error')
        formGroup.find("[data-item=#{key}]").addClass('has-error')

      return
