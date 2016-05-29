# coffeelint: disable=camel_case_classes
class App.UiElement.timer
  @render: (attribute) ->
    days =
      Mon: 'Monday'
      Tue: 'Tuesday'
      Wed: 'Wednesday'
      Thu: 'Thursday'
      Fri: 'Friday'
      Sat: 'Saturday'
      Sun: 'Sunday'
    hours =
      0: '12 am'
      1: '1 am'
      2: '2 am'
      3: '3 am'
      4: '4 am'
      5: '5 am'
      6: '6 am'
      7: '7 am'
      8: '8 am'
      9: '9 am'
      10: '10 am'
      11: '11 am'
      12: '12 am'
      13: '1 pm'
      14: '2 pm'
      15: '3 pm'
      16: '4 pm'
      17: '5 pm'
      18: '6 pm'
      19: '7 pm'
      20: '8 pm'
      21: '9 pm'
      22: '10 pm'
      23: '11 pm'
    hours =
      0: '00'
      1: '01'
      2: '02'
      3: '03'
      4: '04'
      5: '05'
      6: '06'
      7: '07'
      8: '08'
      9: '09'
      10: '10'
      11: '11'
      12: '12'
      13: '13'
      14: '14'
      15: '15'
      16: '16'
      17: '17'
      18: '18'
      19: '19'
      20: '20'
      21: '21'
      22: '22'
      23: '23'
    minutes =
      0: '00'
      10: '10'
      20: '20'
      30: '30'
      40: '40'
      50: '50'

    if !attribute.value
      attribute.value = {}
    if _.isEmpty(attribute.value.days)
      attribute.value.days =
        Mon: true
    if _.isEmpty(attribute.value.hours)
      attribute.value.hours =
        0: true
    if _.isEmpty(attribute.value.minutes)
      attribute.value.minutes =
        0: true

    timer = $( App.view('generic/timer')( attribute: attribute, days: days, hours: hours, minutes: minutes ) )
    timer.find('.js-boolean').data('field-type', 'boolean')
    timer.find('.select-value').bind('click', (e) =>
      @select(e)
    )
    @createOutputString(timer)

    timer

  @select: (e) =>
    target = $(e.currentTarget)

    if target.hasClass('is-selected')
      # prevent zero selections
      if target.siblings('.is-selected').size() > 0
        target.removeClass('is-selected')
        target.next().val('false')
    else
      target.addClass('is-selected')
      target.next().val('true')

    formGroup = $(e.currentTarget).closest('.form-group')
    @createOutputString(formGroup)

  @createOutputString: (formGroup) =>
    days = $.map(formGroup.find('[data-type=day]').filter('.is-selected'), (el) -> return $(el).text() )
    hours = $.map(formGroup.find('[data-type=hour]').filter('.is-selected'), (el) -> return $(el).text() )
    minutes = $.map(formGroup.find('[data-type=minute]').filter('.is-selected'), (el) -> return $(el).text() )

    hours = @injectMinutes(hours, minutes)

    days = @joinItems days
    hours = @joinItems hours

    formGroup.find('.js-timerResult').text(App.i18n.translateInline('Run every %s at %s', days, hours))

  @injectMinutes: (hours, minutes) ->
    newHours = [] # hours.length x minutes.length long

    for hour in hours
      # split off am/pm
      [hour, suffix] = hour.split(' ')

      for minute in minutes
        combined = "#{ hour }:#{ minute }"
        combined += " #{suffix}" if suffix

        newHours.push combined

    newHours

  @joinItems: (items) ->
    switch items.length
      when 1 then return items[0]
      when 2 then return "#{ items[0] } #{App.i18n.translateInline('and')} #{ items[1] }"
      else
        return "#{ items.slice(0, -1).join(', ') } #{App.i18n.translateInline('and')} #{ items[items.length-1] }"
