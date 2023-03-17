class App.Calendar extends App.Model
  @configure 'Calendar', 'name', 'timezone', 'default', 'business_hours', 'ical_url', 'public_holidays'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/calendars'

  @configure_attributes = [
    { name: 'name',           display: __('Name'),            tag: 'input',    type: 'text', limit: 100, null: false },
    { name: 'timezone',       display: __('Time zone'),       tag: 'timezone', null: false }
    { name: 'business_hours', display: __('Business Hours'),  tag: 'business_hours', null: true }
    { name: 'ical_url',       display: __('Holidays iCalendar Feed'), tag: 'ical_feed', placeholder: 'http://example.com/public_holidays.ical', null: true }
    { name: 'public_holidays',display: __('Holidays'),        tag: 'holiday_selector', null: true }
    { name: 'created_by_id',  display: __('Created by'),      relation: 'User', readonly: 1 },
    { name: 'created_at',     display: __('Created'),         tag: 'datetime', readonly: 1 },
    { name: 'updated_by_id',  display: __('Updated by'),      relation: 'User', readonly: 1 },
    { name: 'updated_at',     display: __('Updated'),         tag: 'datetime', readonly: 1 },
  ]

  displayName: ->
    "#{@name} - #{@timezone}"

  @description = __('''
A **calendar** is needed to calculate escalations based on business hours and to send out escalation notifications.

Define a **"standard"** calendar which is valid system-wide. The escalation notifications will only be sent to your agents during the defined business hours.

If you have customers with different business hours, you can create multiple calendars. Tickets are linked to calendars using **SLAs**.
''')
