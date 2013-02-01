class App.Sla extends Spine.Model
  @configure 'Sla', 'name', 'condition', 'data', 'active'
  @extend Spine.Model.Ajax
  @url: 'api/slas'
  @configure_attributes = [
    { name: 'name',                display: 'Name',                tag: 'input',    type: 'text', limit: 100, null: false, 'class': 'span4' },
    { name: 'first_response_time', display: 'First Resposne Time', tag: 'input',    type: 'text', limit: 100, null: true, 'class': 'span4' },
    { name: 'update_time',         display: 'Update Time',         tag: 'input',    type: 'text', limit: 100, null: true, 'class': 'span4' },
    { name: 'solution_time',       display: 'Solution Time',       tag: 'input',    type: 'text', limit: 100, null: true, 'class': 'span4' },
    { name: 'condition',  display: 'Conditions where SLA is used', tag: 'ticket_attribute_selection', null: true, class: 'span4' },
    { 
      name:    'working_hour'
      display: 'Working Hours'
      tag:     'working_hour'
      default: ''
      null:    true
      nulloption: true
      translate:  true
      options:
        customer:               'Customer'
        ticket_state:           'State'
        ticket_priority:        'Priority'
        group:                  'Group'
        owner:                  'Owner'
      class:   'span4'
    },
    { name: 'updated_at',          display: 'Updated',             type: 'time', readonly: 1 },
    { name: 'active',              display: 'Active',              tag: 'boolean',  note: 'boolean', 'default': true, 'null': false, 'class': 'span4' },
  ]
  @configure_delete = true
  @configure_overview = [
    'name',
  ]