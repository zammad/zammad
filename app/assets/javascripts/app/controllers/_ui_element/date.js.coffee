class App.UiElement.date
  @render: (attributeOrig) ->

    attribute = _.clone(attributeOrig)
    attribute.nameRaw = attribute.name
    attribute.name = "{date}#{attribute.name}"

    # get time object
    if attribute.value
      if typeof attribute.value is 'string'
        time = new Date( Date.parse( "#{attribute.value}T00:00:00Z" ) )
      else
        time = new Date( attribute.value )

      # time items
      year   = time.getUTCFullYear()
      month  = time.getUTCMonth() + 1
      day    = time.getUTCDate()

    # create element
    item = $( App.view('generic/date')(
      attribute: attribute
      year:      year
      month:     month
      day:       day
    ) )

    # start bindings
    item.find('.js-today').bind('click', (e) =>
      e.preventDefault()
      @setNewTime(item, attribute, 0, true)
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
    if parseInt(number) < 10
      number = "0#{number}"
    number

  @setNewTime: (item, attribute, diff, reset = false, tolerant = false) ->

    resetTimeToToday = =>
      time = new Date()
      time.setMinutes( time.getMinutes() + diff )
      @setParams(item, attribute, time)

    return resetTimeToToday() if reset

    params = @getParams(item)
    if params.year is '' && params.month is '' && params.day is ''
      return if !tolerant
      resetTimeToToday()
      params = @getParams(item)

    time = new Date( Date.parse( "#{params.year}-#{@format(params.month)}-#{@format(params.day)}T00:00:00Z" ) )
    time.setMinutes( time.getMinutes() + diff )
    return if !time
    @setParams(item, attribute, time)

  @setShadowTimestamp: (item, attribute, time) ->
    timestamp = ''
    if time
      timestamp = time.toISOString().replace(/T\d\d:\d\d:\d\d\.\d\d\dZ$/, '')
    item.find("[name=\"#{attribute.name}\"]").val(timestamp)

  @setParams: (item, attribute, time) ->
    if time.toString() is 'Invalid Date'
      @setShadowTimestamp(item, attribute)
      return

    day = time.getDate()
    month = time.getMonth()+1
    year = time.getFullYear()
    item.find('[data-item=day]').val(day)
    item.find('[data-item=month]').val(month)
    item.find('[data-item=year]').val(year)
    @setShadowTimestamp(item, attribute, time)

  @getParams: (item) ->
    params = {}
    params.day    = item.find('[data-item=day]').val()
    params.month  = item.find('[data-item=month]').val()
    params.year   = item.find('[data-item=year]').val()
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


    #formGroup = item.closest('.form-group')
    formGroup = item
    if !_.isEmpty(errors)

      # if field is required, if not do not show error
      if params.year is '' && params.day is '' && params.month is ''
        return if attribute.null
        item.closest('.form-group').addClass('has-error')
        item.closest('.form-group').find('.help-inline').text( 'is required' )
        return

      # show invalid options
      for key, value of errors
        formGroup.addClass('has-error')
        formGroup.find("[data-item=#{key}]").addClass('has-error')

      return
