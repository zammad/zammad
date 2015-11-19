class App.Twitter extends App.Model
  @configure 'Twitter', 'name', 'channels'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/twitter'
  @configure_attributes = [
    { name: 'name', display: 'Name', tag: 'input', type: 'text', limit: 100, null: false }
  ]
  @configure_delete = true
  @configure_overview = [
    'name',
  ]

  @description = '''
**Twitter Accounts**, abgekürzt **SLAs**, unterstützen Sie gegenüber Kunden gewisse zeitliche Reaktionen einzuhalten. Somit können Sie z. B. sagen Kunden sollen immer nach spätestens 8 Stunden eine Reaktion von Ihnen bekommen. Falls es zu einer drohenden Unterschreitung oder einer Unterschreitung kommt, weißt Zammad Sie auf solche Ereignisse hin.

Es können **Reaktionszeit** (Zeit zwischen Erstellung eines Tickets und erster Reaktion eines Agenten), **Aktualisierungszeit** (Zeit zwischen Nachfrage eines Kunden und Reaktion eines Agenten) und **Lösungszeit** (Zeit zwischen Erstellung und schließen eines Tickets) definiert werden.

Drohenden Unterschreitungen oder Unterschreitungen werden in einer eigenen Ansicht in den Übersichten angezeigt. Zudem können **E-Mail Benachrichtigungen** konfiguriert werden.
'''