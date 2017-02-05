class App.Calendar extends App.Model
  @configure 'Calendar', 'name', 'timezone', 'default', 'business_hours', 'ical_url', 'public_holidays', 'note'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/calendars'

  @configure_attributes = [
    { name: 'name',           display: 'Name',            tag: 'input',    type: 'text', limit: 100, null: false },
    { name: 'timezone',       display: 'Time zone',        tag: 'timezone', null: false }
    { name: 'business_hours', display: 'Business Hours',  tag: 'business_hours', null: true }
    { name: 'ical_url',       display: 'Holidays iCalendar Feed', tag: 'ical_feed', placeholder: 'http://example.com/public_holidays.ical', null: true }
    { name: 'public_holidays',display: 'Holidays',        tag: 'holiday_selector', null: true }
    { name: 'note',           display: 'Note',            tag: 'textarea', limit: 250, null: true },
    { name: 'created_by_id',  display: 'Created by',      relation: 'User', readonly: 1 },
    { name: 'created_at',     display: 'Created',         tag: 'datetime', readonly: 1 },
    { name: 'updated_by_id',  display: 'Updated by',      relation: 'User', readonly: 1 },
    { name: 'updated_at',     display: 'Updated',         tag: 'datetime', readonly: 1 },
  ]

  displayName: ->
    "#{@name} - #{@timezone}"

  @description = '''
Ein **Kalender** wird benötigt um Eskalationen oder Auswertungen anhand von Geschäftszeiten zu berechnen.

Definieren Sie einen **"Standard"-Kalender** welcher Systemweit gültig ist. Nur in den angegebenen Geschäftszeiten werden Eskalations-Benachrichtigungen an Agenten versendet.

Haben Sie Kunden für welche Sie unterschiedliche Geschäftszeiten einhalten müssen, so können Sie mehrere Kalender anlegen. Die Zuweisung zu den Kunden-Tickets geschieht über die **SLAs**.
'''
