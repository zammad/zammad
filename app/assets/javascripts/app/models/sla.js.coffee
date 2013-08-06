class App.Sla extends App.Model
  @configure 'Sla', 'name', 'first_response_time', 'update_time', 'close_time', 'condition', 'timezone', 'data', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @api_path + '/slas'
  @configure_attributes = [
    { name: 'name',                display: 'Name',                tag: 'input',    type: 'text', limit: 100, null: false, 'class': 'span4' },
    { name: 'first_response_time', display: 'First Response Time', tag: 'input',    type: 'text', limit: 100, null: true, 'class': 'span4', note: 'In minutes, only business times are counted.' },
    { name: 'update_time',         display: 'Update Time',         tag: 'input',    type: 'text', limit: 100, null: true, 'class': 'span4', note: 'In minutes, only business times are counted.' },
    { name: 'close_time',          display: 'Solution Time',       tag: 'input',    type: 'text', limit: 100, null: true, 'class': 'span4', note: 'In minutes, only business times are counted.' },
    { name: 'condition',           display: 'Conditions where SLA is used', tag: 'ticket_attribute_selection', null: true, class: 'span4' },
    { name: 'timezone',            display: 'Timezone',            tag: 'timezone', null: true, class: 'span4' },
    {
      name:    'data'
      display: 'Business Times'
      tag:     'working_hour'
      default:
        Mon: true
        Tue: true
        Wed: true
        Thu: true
        Fri: true
        beginning_of_workday: '8:00'
        end_of_workday: '18:00'
      null:    true
      nulloption: true
      translate:  true
      options:
        customer:         'Customer'
        ticket_state:     'State'
        ticket_priority:  'Priority'
        group:            'Group'
        owner:            'Owner'
      class:   'span4'
    },
    { name: 'updated_at',          display: 'Updated',             type: 'time', readonly: 1 },
    { name: 'active',              display: 'Active',              tag: 'boolean',  note: 'boolean', 'default': true, 'null': false, 'class': 'span4' },
  ]
  @configure_delete = true
  @configure_overview = [
    'name',
  ]
