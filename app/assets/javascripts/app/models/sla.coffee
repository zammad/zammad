class App.Sla extends App.Model
  @configure 'Sla', 'name', 'first_response_time', 'response_time', 'update_time', 'solution_time', 'condition', 'calendar_id'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/slas'
  @configure_attributes = [
    { name: 'name',           display: __('Name'),            tag: 'input',    type: 'text', limit: 100, null: false },
    { name: 'condition',      display: __('Ticket Selector'), tag: 'ticket_selector', null: false, note: __('Create rules that single out the tickets for the Service Level Agreement.'), noCurrentUser: true },
    { name: 'calendar_id',    display: __('Calendar'),        tag: 'select', relation: 'Calendar', null: false },
    { name: 'sla_times',      display: __('SLA Times'),       tag: 'sla_times', null: true },
    { name: 'created_by_id',  display: __('Created by'),      relation: 'User', readonly: 1 },
    { name: 'created_at',     display: __('Created'),         tag: 'datetime', readonly: 1 },
    { name: 'updated_by_id',  display: __('Updated by'),      relation: 'User', readonly: 1 },
    { name: 'updated_at',     display: __('Updated'),         tag: 'datetime', readonly: 1 },
    { name: 'first_response_time',skipRendering: true },
    { name: 'response_time',        skipRendering: true },
    { name: 'update_time',        skipRendering: true },
    { name: 'solution_time',      skipRendering: true },
  ]
  @configure_delete = true
  @configure_overview = [
    'name',
  ]

  @description = __('''
**Service Level Agreements**, abbreviated **SLAs**, help you to meet specific response times for your customers' requests. This way you can define goals such as answering every inquiry within eight hours. If you are at risk of missing this target, Zammad will alert you.

You can define targets for three different metrics: **response time** (time between the creation of a ticket and the first reaction of an agent), **update time** (time between a customer's request and an agent's reaction), and **solution time** (time between creating and closing a ticket).

Any escalated tickets (i.e. tickets that have missed the defined target) are displayed in a separate view in your overviews. You can also configure **email notifications**.
''')
