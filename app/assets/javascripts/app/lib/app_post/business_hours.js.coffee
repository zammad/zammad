class App.BusinessHours extends Spine.Controller

  className: 'settings-list settings-list--stretch settings-list--toggleColumn'
  tag: 'table'

  events:
    'click .js-activateColumn': 'activateColumn'

  constructor: ->
    super

  render: =>
    days =
      mon: App.i18n.translateInline('Monday')
      tue: App.i18n.translateInline('Tuesday')
      wed: App.i18n.translateInline('Wednesday')
      thu: App.i18n.translateInline('Thursday')
      fri: App.i18n.translateInline('Friday')
      sat: App.i18n.translateInline('Saturday')
      sun: App.i18n.translateInline('Sunday')

    html = App.view('generic/business_hours')
      days: days
      hours: @options.hours

    console.log "BusinessHours:", "days", days, "hours", @options.hours, "html", html

    @html html

    @$('.js-time').timepicker
      showMeridian: false # meridian = am/pm

  activateColumn: (event) =>
    checkbox = @$(event.currentTarget)
    columnName = checkbox.attr('data-target')
    @$("[data-column=#{columnName}]").toggleClass('is-active', checkbox.prop('checked'))
