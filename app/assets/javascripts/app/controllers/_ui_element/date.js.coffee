class App.UiElement.date
  @render: (attribute) ->

    # set data type
    if attribute.name
      attribute.nameRaw = attribute.name
      attribute.name    = '{date}' + attribute.name
    if attribute.value
      if typeof( attribute.value ) is 'string'
        unixtime = new Date( Date.parse( "#{attribute.value}T00:00:00Z" ) )
      else
        unixtime = new Date( attribute.value )
      year     = unixtime.getUTCFullYear()
      month    = unixtime.getUTCMonth() + 1
      day      = unixtime.getUTCDate()
      hour     = unixtime.getUTCHours()
      minute   = unixtime.getUTCMinutes()
    item = $( App.view('generic/date')(
      attribute: attribute
      year:      year
      month:     month
      day:       day
    ) )

    setNewTime = (diff, el, reset) ->
      name = $(el).closest('.form-group').find('[data-name]').attr('data-name')

      # remove old validation
      item.find('.has-error').removeClass('has-error')
      item.closest('.form-group').find('.help-inline').html('')

      day    = item.closest('.form-group').find("[name=\"{date}#{name}___day\"]").val()
      month  = item.closest('.form-group').find("[name=\"{date}#{name}___month\"]").val()
      year   = item.closest('.form-group').find("[name=\"{date}#{name}___year\"]").val()
      format = (number) ->
        if parseInt(number) < 10
          number = "0#{number}"
        number
      if !reset && (year isnt '' && month isnt '' && day isnt '')
        time = new Date( Date.parse( "#{year}-#{format(month)}-#{format(day)}T00:00:00Z" ) )
        time.setMinutes( time.getMinutes() + diff + time.getTimezoneOffset() )
      else
        time = new Date()
        time.setMinutes( time.getMinutes() + diff )
      item.closest('.form-group').find("[name=\"{date}#{name}___day\"]").val( time.getDate() )
      item.closest('.form-group').find("[name=\"{date}#{name}___month\"]").val( time.getMonth()+1 )
      item.closest('.form-group').find("[name=\"{date}#{name}___year\"]").val( time.getFullYear() )

    item.find('.js-today').bind('click', (e) ->
      e.preventDefault()
      setNewTime(0, @, true)
    )
    item.find('.js-plus-day').bind('click', (e) ->
      e.preventDefault()
      setNewTime(60 * 24, @)
    )
    item.find('.js-minus-day').bind('click', (e) ->
      e.preventDefault()
      setNewTime(-60 * 24, @)
    )
    item.find('.js-plus-week').bind('click', (e) ->
      e.preventDefault()
      setNewTime(60 * 24 * 7, @)
    )
    item.find('.js-minus-week').bind('click', (e) ->
      e.preventDefault()
      setNewTime(-60 * 24 * 7, @)
    )

    item.find('input').bind('keyup blur focus change', (e) ->

      # do validation
      name = $(@).attr('name')
      if name
        fieldPrefix = name.split('___')[0]

      # remove old validation
      item.find('.has-error').removeClass('has-error')
      item.closest('.form-group').find('.help-inline').html('')

      day    = item.closest('.form-group').find("[name=\"#{fieldPrefix}___day\"]").val()
      month  = item.closest('.form-group').find("[name=\"#{fieldPrefix}___month\"]").val()
      year   = item.closest('.form-group').find("[name=\"#{fieldPrefix}___year\"]").val()

      # validate exists
      errors = {}
      if !day
        errors.day = 'missing'
      if !month
        errors.month = 'missing'
      if !year
        errors.year = 'missing'

      # ranges
      if day
        daysInMonth = 31
        if month && year
          daysInMonth = new Date(year, month, 0).getDate();

        if parseInt(day).toString() is 'NaN'
          errors.day = 'invalid'
        else if parseInt(day) > daysInMonth || parseInt(day) < 1
          errors.day = 'invalid'

      if month
        if parseInt(month).toString() is 'NaN'
          errors.month = 'invalid'
        else if parseInt(month) > 12 || parseInt(month) < 1
          errors.month = 'invalid'

      if year
        if parseInt(year).toString() is 'NaN'
          errors.year = 'invalid'
        else if parseInt(year) > 2100 || parseInt(year) < 2001
          errors.year = 'invalid'

      if !_.isEmpty(errors)

        # if field is required, if not do not show error
        if year is '' && day is '' && month
          if attribute.null
            e.preventDefault()
            e.stopPropagation()
            return
          else
            item.closest('.form-group').find('.help-inline').text( 'is required' )

        # show invalid options
        for key, value of errors
          item.closest('.form-group').addClass('has-error')
          item.closest('.form-group').find("[name=\"#{fieldPrefix}___#{key}\"]").addClass('has-error')
          #item.closest('.form-group').find('.help-inline').text( value )

        e.preventDefault()
        e.stopPropagation()
        return
    )

    item