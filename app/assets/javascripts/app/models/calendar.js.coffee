class App.Calendar extends App.Model
  @configure 'Calendar', 'name', 'timezone', 'default', 'business_hours', 'ical_url', 'public_holidays'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/calendars'

  displayName: ->
    "#{@name} - #{@timezone}"

  @description = '''
Ein **Kalender** wird benötigt um Eskalationen oder Auswertungen anhand von Geschäftszeiten zu berechnen.

Definieren Sie einen **"Standard"-Kalender** welcher Systemweit gültig ist. Nur in den angegebenen Geschäftszeiten werden Eskalations-Benachrichtigungen an Agenten versendet.

Haben Sie Kunden für welche Sie unterschiedliche Geschäftszeiten einhalten müssen, so können Sie mehrere Kalender anlegen. Die Zuweisung zu den Kunden-Tickets geschieht über die **SLAs**.
'''