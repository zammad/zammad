class App.BusinessHours extends Spine.Controller

  className: 'settings-list settings-list--stretch settings-list--toggleColumn'
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

  render: =>
    maxTimeframeDay = _.max @hours, (day) -> day.timeframes.length

    html = App.view('generic/business_hours')
      days: @days
      hours: @options.hours
      maxTimeframes: maxTimeframeDay.timeframes.length

    @html html

    @$('.js-time')
      .timepicker
        showMeridian: false # meridian = am/pm
      .on 'changeTime.timepicker', @onTimeChange

  onTimeChange: (event) =>
    input = @$(event.currentTarget)
    day = input.attr('data-day')
    slot = input.attr('data-slot')
    i = input.attr('data-i')
    console.log "something changed", event.time
    @options.hours[day].timeframes[slot][i] = "#{event.time.hours}:#{event.time.minutes}"

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
