class App.BusinessHours extends Spine.Controller

  className: 'settings-list settings-list--fixed settings-list--stretch settings-list--toggleColumn'
  tag: 'table'

  events:
    'click .js-toggle-day': 'toggleDay'
    'click .js-add-time': 'addTime'
    'click .js-remove-time': 'removeTime'

  constructor: ->
    super

    @days =
      mon: App.i18n.translateInline('Monday')
      tue: App.i18n.translateInline('Tuesday')
      wed: App.i18n.translateInline('Wednesday')
      thu: App.i18n.translateInline('Thursday')
      fri: App.i18n.translateInline('Friday')
      sat: App.i18n.translateInline('Saturday')
      sun: App.i18n.translateInline('Sunday')

    # validate config
    for day of @days
      if !@hours[day]
        @hours[day] = {}
    for day, meta of @hours
      if !meta.active
        meta.active = false
      if !meta.timeframes
        meta.timeframes = []

  render: =>
    @updateMaxTimeframes()

    html = App.view('generic/business_hours')
      attribute: @attribute
      days: @days
      hours: @options.hours
      maxTimeframes: @maxTimeframes

    @html html

    @$('.js-time')
      .timepicker
        showMeridian: false # meridian = am/pm
      .on 'changeTime.timepicker', @onTimeChange

    @el.toggleClass 'is-invalid', !@validate()

  updateMaxTimeframes: =>
    maxTimeframeDay = _.max @hours, (day) -> day.timeframes.length
    @maxTimeframes = maxTimeframeDay.timeframes.length

  onTimeChange: (event) =>
    input = @$(event.currentTarget)
    day = input.attr('data-day')
    slot = input.attr('data-slot')
    i = input.attr('data-i')
    @options.hours[day].timeframes[slot][i] = event.time.hoursAndMinutes

    @el.toggleClass 'is-invalid', !@validate()

  addTime: (event) =>
    day = @$(event.currentTarget).attr('data-day')
    @options.hours[day].timeframes.push(['13:00', '17:00'])
    @render()

  removeTime: (event) =>
    day = @$(event.currentTarget).attr('data-day')
    @options.hours[day].timeframes.pop()
    @render()

  toggleDay: (event) =>
    checkbox = @$(event.currentTarget)
    day = checkbox.attr('data-target')
    @options.hours[day].active = checkbox.prop('checked')
    @$("[data-day=#{day}]").toggleClass('is-active', checkbox.prop('checked'))

    @el.toggleClass 'is-invalid', !@validate()

  validate: =>
    for day, hours of @options.hours
      break if !hours.active

      # edge case: full day
      if hours.timeframes[0][0] is '00:00' and hours.timeframes[hours.timeframes.length - 1][1] is '00:00'
        return true

      # check each timeframe
      for slot in [0..hours.timeframes.length - 1]

        # check if start time is earlier than end time
        if not @earlier hours.timeframes[slot][0], hours.timeframes[slot][1]
          return false

        # check if start time of slot is later than end time of slot before
        if slot > 0 && not @later hours.timeframes[slot][0], hours.timeframes[slot-1][1]
          return false

    # all passed
    return true

  later: (a, b) ->
    # a later b
    # input 'hh:mm'
    [ha, ma] = a.split(':').map (val) -> parseInt val, 10
    [hb, mb] = b.split(':').map (val) -> parseInt val, 10

    if ha > hb
      return true
    if ha is hb
      if ma > mb
        return true
    return false

  earlier: (a, b) ->
    # a earlier than b
    # input 'hh:mm'

    [ha, ma] = a.split(':').map (val) -> parseInt val, 10
    [hb, mb] = b.split(':').map (val) -> parseInt val, 10

    if ha < hb
      return true
    if ha is hb
      if ma < mb
        return true
    return false