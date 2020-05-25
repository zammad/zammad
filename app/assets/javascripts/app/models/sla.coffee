class App.Sla extends App.Model
  @configure 'Sla', 'name', 'first_response_time', 'update_time', 'solution_time', 'condition', 'calendar_id'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/slas'
  @configure_attributes = [
    { name: 'name',           display: 'Name',            tag: 'input',    type: 'text', limit: 100, null: false },
    { name: 'condition',      display: 'Ticket Selector', tag: 'ticket_selector', null: false, note: 'Create rules that single out the tickets for the Service Level Agreement.' },
    { name: 'calendar_id',    display: 'Calendar',        tag: 'select', relation: 'Calendar', null: false },
    { name: 'sla_times',      display: 'SLA Times',       tag: 'sla_times', null: true },
    { name: 'created_by_id',  display: 'Created by',      relation: 'User', readonly: 1 },
    { name: 'created_at',     display: 'Created',         tag: 'datetime', readonly: 1 },
    { name: 'updated_by_id',  display: 'Updated by',      relation: 'User', readonly: 1 },
    { name: 'updated_at',     display: 'Updated',         tag: 'datetime', readonly: 1 },
    { name: 'first_response_time', null: false, skipRendering: true, required_if: { 'first_response_time_enabled': ['on'] } },
    { name: 'update_time',         null: false, skipRendering: true, required_if: { 'update_time_enabled': ['on'] } },
    { name: 'solution_time',       null: false, skipRendering: true, required_if: { 'solution_time_enabled': ['on'] } },
  ]
  @configure_delete = true
  @configure_overview = [
    'name',
  ]

  @description = '''
** Service Level Agreements **, abbreviated ** SLAs **, help you to meet certain customers' time-related responses. Thus, for example, you can say customers should always get a response from you after 8 hours at the latest. In the event of an imminent violation or a breach, Zammad will alert you to such events.

It can be ** response time ** (time between the creation of a ticket and the first reaction of an agent), ** update time ** (time between a customer's request and an agent's reaction) and ** solution time ** (time between creation and closing a ticket ) To be defined.

Any violations are displayed in a separate view in the overviews. You can also configure ** e-mail notifications **.
'''
