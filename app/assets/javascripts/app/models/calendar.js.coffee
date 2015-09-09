class App.Calendar extends App.Model
  @configure 'Calendar', 'name', 'timezone', 'default', 'business_hours', 'ical_url', 'public_holidays'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/calendars'
