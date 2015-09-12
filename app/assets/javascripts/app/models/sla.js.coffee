class App.Sla extends App.Model
  @configure 'Sla', 'name', 'first_response_time', 'update_time', 'close_time', 'condition', 'calendar_id'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/slas'
  @configure_attributes = [
    { name: 'name',                display: 'Name',                tag: 'input',    type: 'text', limit: 100, null: false },
    { name: 'first_response_time', display: 'First Response Time', tag: 'input',    type: 'text', limit: 100, null: true, note: 'In minutes, only business times are counted.' },
    { name: 'update_time',         display: 'Update Time',         tag: 'input',    type: 'text', limit: 100, null: true, note: 'In minutes, only business times are counted.' },
    { name: 'close_time',          display: 'Solution Time',       tag: 'input',    type: 'text', limit: 100, null: true, note: 'In minutes, only business times are counted.' },
    { name: 'calendar_id',         display: 'Calendar',            tag: 'select', relation: 'Calendar', null: false },
    { name: 'condition',           display: 'Conditions where SLA is used', tag: 'ticket_attribute_selection', null: true },
    { name: 'created_by_id',  display: 'Created by',  relation: 'User', readonly: 1 },
    { name: 'created_at',     display: 'Created',     tag: 'datetime', readonly: 1 },
    { name: 'updated_by_id',  display: 'Updated by',  relation: 'User', readonly: 1 },
    { name: 'updated_at',     display: 'Updated',     tag: 'datetime', readonly: 1 },
  ]
  @configure_delete = true
  @configure_overview = [
    'name',
  ]

  @description = '''
**Service-Level-Agreements**, abgekürzt **SLAs**, unterstützen Sie gegenüber Kunden gewisse zeitliche Reaktionen einzuhalten. Somit können Sie z. B. sagen Kunden sollen immer nach spätestens 8 Stunden eine Reaktion von Ihnen bekommen. Falls es zu einer drohenden Unterschreitung oder einer Unterschreitung kommt, weißt Zammad Sie auf solche Ereignisse hin.

Es können **Reaktionszeit** (Zeit zwischen Erstellung eines Tickets und erster Reaktion eines Agenten), **Aktualisierungszeit** (Zeit zwischen Nachfrage eines Kunden und Reaktion eines Agenten) und **Lösungszeit** (Zeit zwischen Erstellung und schließen eines Tickets) definiert werden.

Drohenden Unterschreitungen oder Unterschreitungen werden in einer eigenen Ansicht in den Übersichten angezeigt. Zudem können **E-Mail Benachrichtigungen** konfiguriert werden.
'''