class App.Calendar extends App.Model
  @configure 'Calendar', 'name', 'timezone', 'default', 'business_hours', 'ical_url', 'public_holidays', 'note'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/calendars'

  @configure_attributes = [
    { name: 'name',           display: 'Name',            tag: 'input',    type: 'text', limit: 100, null: false },
    { name: 'timezone',       display: 'Time zone',       tag: 'timezone', null: false }
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
A **calendar** is needed for calculation of escalation based on business hours and sending out escalation notifications..

Define a **"standard"** calendar which is valid system-wide. Only in the defined business hours the escalation notifications will be sent to your agents.

Do you have customers with different business hours, you can create multiple calendars. Tickets are linked to calendars using **SLAs**.
'''
