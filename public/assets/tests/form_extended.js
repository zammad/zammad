
// form
test('form checks', function() {

  // use unsorted order to check if the frontend is sorting correctly
  App.TicketPriority.refresh([
    {
      id:         2,
      name:       '2 normal',
      note:       'some note 2',
      active:     false,
      created_at: '2014-06-10T10:17:34.000Z',
    },
    {
      id:         3,
      name:       '3 high',
      note:       'some note 3',
      active:     true,
      created_at: '2014-06-10T10:17:44.000Z',
    },
    {
      id:         4,
      name:       '4 very high',
      note:       'some note 4',
      active:     true,
      created_at: '2014-06-10T10:17:54.000Z',
    },
    {
      id:         5,
      name:       '5 xxx very high',
      note:       'some note 5',
      active:     false,
      created_at: '2014-06-10T10:17:56.000Z',
    },
    {
      id:         1,
      name:       '1 low',
      note:       'some note 1',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
  ])

  App.TicketState.refresh([
    {
      id:         1,
      name:       'new',
      note:       'some note 1',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         2,
      name:       'open',
      note:       'some note 2',
      active:     true,
      created_at: '2014-06-10T10:17:34.000Z',
    },
    {
      id:         3,
      name:       'should not be shown',
      note:       'some note 3',
      active:     false,
      created_at: '2014-06-10T10:17:34.000Z',
    },
  ])

  App.User.refresh([
    {
      id:         47,
      login:      'bod@example.com',
      email:      'bod@example.com',
      firstname:  'Bob',
      lastname:   'Smith',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
  ])

  App.Organization.refresh([
    {
      id:         12,
      name:      'Org 1',
      active:     true,
      created_at: '2014-06-10T11:19:34.000Z',
    },
  ])

  /* working hours and escalation_times */
  $('#forms').append('<hr><h1>form condition check</h1><form id="form1"></form>')
  var el = $('#form1')
  var defaults = {
    priority1_id: '1',
    priority2_id: ['1', '2'],
    priority3_id: '2',
    working_hours: {
      mon: {
        active: true,
        timeframes: [
          ['09:00','17:00']
        ]
      },
      tue: {
        active: true,
        timeframes: [
          ['00:00','22:00']
        ]
      },
      wed: {
        active: true,
        timeframes: [
          ['09:00','17:00']
        ]
      },
      thu: {
        active: true,
        timeframes: [
          ['09:00','12:00'],
          ['13:00','17:00']
        ]
      },
      fri: {
        active: true,
        timeframes: [
          ['09:00','17:00']
        ]
      },
      sat: {
        active: false,
        timeframes: [
          ['10:00','14:00']
        ]
      },
      sun: {
        active: false,
        timeframes: [
          ['10:00','14:00']
        ]
      },
    },
    first_response_time: 150,
    solution_time: '',
    update_time: 45,
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'priority1_id', display: 'Priroity1', tag: 'select', relation: 'TicketPriority', null: true, options: {} },
        { name: 'priority2_id', display: 'Priroity2', tag: 'select', multiple: true, relation: 'TicketPriority', null: true, options: {} },
        { name: 'priority3_id', display: 'Priroity3', tag: 'select', relation: 'TicketPriority', null: true },
        { name: 'escalation_times', display: 'Times', tag: 'sla_times', null: true },
        { name: 'working_hours',    display: 'Hours', tag: 'business_hours', null: true },
      ]
    },
    params: defaults,
    autofocus: true
  })
  var params = App.ControllerForm.params(el)
  var test_params = {
    priority1_id: '1',
    priority2_id: ['1', '2'],
    priority3_id: '2',
    first_response_time: '150',
    first_response_time_in_text: '02:30',
    solution_time: '',
    solution_time_in_text: '',
    update_time: '45',
    update_time_in_text: '00:45',
    working_hours: {
      mon: {
        active: true,
        timeframes: [
          ['09:00','17:00']
        ]
      },
      tue: {
        active: true,
        timeframes: [
          ['00:00','22:00']
        ]
      },
      wed: {
        active: true,
        timeframes: [
          ['09:00','17:00']
        ]
      },
      thu: {
        active: true,
        timeframes: [
          ['09:00','12:00'],
          ['13:00','17:00']
        ]
      },
      fri: {
        active: true,
        timeframes: [
          ['09:00','17:00']
        ]
      },
      sat: {
        active: false,
        timeframes: [
          ['10:00','14:00']
        ]
      },
      sun: {
        active: false,
        timeframes: [
          ['10:00','14:00']
        ]
      },
    },
  }
  deepEqual(params, test_params, 'form param check')

  // check possible options
  equal(el.find('[name="priority1_id"] option').length, 3)
  equal(el.find('[name="priority2_id"] option').length, 4)
  equal(el.find('[name="priority3_id"] option').length, 4)

  // change sla times
  el.find('[name="first_response_time_in_text"]').val('0:30').trigger('blur')
  el.find('#update_time').click()

  var params = App.ControllerForm.params(el)
  var test_params = {
    priority1_id: '1',
    priority2_id: ['1', '2'],
    priority3_id: '2',
    working_hours: {
      mon: {
        active: true,
        timeframes: [
          ['09:00','17:00']
        ]
      },
      tue: {
        active: true,
        timeframes: [
          ['00:00','22:00']
        ]
      },
      wed: {
        active: true,
        timeframes: [
          ['09:00','17:00']
        ]
      },
      thu: {
        active: true,
        timeframes: [
          ['09:00','12:00'],
          ['13:00','17:00']
        ]
      },
      fri: {
        active: true,
        timeframes: [
          ['09:00','17:00']
        ]
      },
      sat: {
        active: false,
        timeframes: [
          ['10:00','14:00']
        ]
      },
      sun: {
        active: false,
        timeframes: [
          ['10:00','14:00']
        ]
      },
    },
    first_response_time: '30',
    first_response_time_in_text: '00:30',
    solution_time: '',
    solution_time_in_text: '',
    update_time: '',
    update_time_in_text: '',
  }
  deepEqual(params, test_params, 'form param check')

  /* empty params or defaults */
  $('#forms').append('<hr><h1>form condition check</h1><form id="form2"></form>')
  var el = $('#form2')
  new App.ControllerForm({
    el:    el,
    model: {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'ticket_selector', null: true },
        { name: 'executions', display: 'Executions', tag: 'ticket_perform_action', null: true, notification: true },
      ]
    },
    autofocus: true
  })
  var params = App.ControllerForm.params(el)
  var test_params = {
    condition: {
      'ticket.state_id': {
        operator: 'is',
        value: '2',
      },
    },
    executions: {
      'ticket.state_id': {
        value: '2',
      },
    },
  }
  deepEqual(params, test_params, 'form param check');

  /* with params or defaults */
  $('#forms').append('<hr><h1>form 3</h1><form id="form3"></form>')
  var el = $('#form3')
  var defaults = {
    condition: {
      'ticket.title': {
        operator: 'contains',
        value: 'some title',
      },
      'ticket.priority_id': {
        operator: 'is',
        value: [1,2,3],
      },
      'ticket.created_at': {
        operator: 'before (absolute)',
        value: '2015-09-20T03:41:00.000Z',
      },
      'ticket.updated_at': {
        operator: 'within last (relative)',
        range: 'year',
        value: 2,
      },
      'ticket.organization_id': {
        operator: 'is not',
        pre_condition: 'specific',
        value: 12,
      },
      'ticket.owner_id': {
        operator: 'is',
        pre_condition: 'specific',
        value: 47,
      },
      'ticket.created_by_id': {
        operator: 'is',
        pre_condition: 'current_user.id',
        value: '',
      },
    },
    executions: {
      'ticket.title': {
        value: 'some title new',
      },
      'ticket.priority_id': {
        value: 3,
      },
      'ticket.owner_id': {
        pre_condition: 'specific',
        value: 47,
      },
      'ticket.tags': {
        operator: 'remove',
        value: 'tag1, tag2',
      },
      'notification.email': {
        recipient: 'ticket_customer',
        subject: 'some subject',
        body: "some<br>\nbody",
      },
    },
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'ticket_selector', null: true },
        { name: 'executions', display: 'Executions', tag: 'ticket_perform_action', null: true, notification: true },
      ]
    },
    params: defaults,
    autofocus: true
  })
  var params = App.ControllerForm.params(el)
  var test_params = {
    condition: {
      'ticket.title': {
        operator: 'contains',
        value: 'some title',
      },
      'ticket.priority_id': {
        operator: 'is',
        value: ['1', '2', '3'], // show also invalid proirity, because it's selected
      },
      'ticket.created_at': {
        operator: 'before (absolute)',
        value: '2015-09-20T03:41:00.000Z',
      },
      'ticket.updated_at': {
        operator: 'within last (relative)',
        range: 'year',
        value: '2',
      },
      'ticket.organization_id': {
        operator: 'is not',
        pre_condition: 'specific',
        value: '12',
      },
      'ticket.owner_id': {
        operator: 'is',
        pre_condition: 'specific',
        value: '47',
        value_completion: 'Bob Smith <bod@example.com>',
      },
      'ticket.created_by_id': {
        operator: 'is',
        pre_condition: 'current_user.id',
        value: '',
        value_completion: ''
      },
    },
    executions: {
      'ticket.title': {
        value: 'some title new',
      },
      'ticket.owner_id': {
        pre_condition: 'specific',
        value: '47',
        value_completion: 'Bob Smith <bod@example.com>'
      },
      'ticket.priority_id': {
        value: '3',
      },
      'ticket.tags': {
        operator: 'remove',
        value: 'tag1, tag2',
      },
      'notification.email': {
        recipient: 'ticket_customer',
        subject: 'some subject',
        body: "some<br>\nbody",
      },
    },
  }
  deepEqual(params, test_params, 'form param check')

  // change selector
  el.find('[name="condition::ticket.priority_id::value"]').closest('.js-filterElement').find('.js-remove').click()
  el.find('[name="executions::ticket.title::value"]').closest('.js-filterElement').find('.js-remove').click()

  var params = App.ControllerForm.params(el)
  var test_params = {
    condition: {
      'ticket.title': {
        operator: 'contains',
        value: 'some title',
      },
      'ticket.created_at': {
        operator: 'before (absolute)',
        value: '2015-09-20T03:41:00.000Z',
      },
      'ticket.updated_at': {
        operator: 'within last (relative)',
        range: 'year',
        value: '2',
      },
      'ticket.organization_id': {
        operator: 'is not',
        pre_condition: 'specific',
        value: '12',
      },
      'ticket.owner_id': {
        operator: 'is',
        pre_condition: 'specific',
        value: '47',
        value_completion: 'Bob Smith <bod@example.com>',
      },
      'ticket.created_by_id': {
        operator: 'is',
        pre_condition: 'current_user.id',
        value: '',
        value_completion: ''
      },
    },
    executions: {
      'ticket.priority_id': {
        value: '3',
      },
      'ticket.owner_id': {
        pre_condition: 'specific',
        value: '47',
        value_completion: 'Bob Smith <bod@example.com>'
      },
      'ticket.tags': {
        operator: 'remove',
        value: 'tag1, tag2',
      },
      'notification.email': {
        recipient: 'ticket_customer',
        subject: 'some subject',
        body: "some<br>\nbody",
      },
    },
  }
  deepEqual(params, test_params, 'form param check')

  // change selector
  el.find('[name="executions::notification.email::subject"]').closest('.js-filterElement').find('.js-remove').click()

  var params = App.ControllerForm.params(el)
  var test_params = {
    condition: {
      'ticket.title': {
        operator: 'contains',
        value: 'some title',
      },
      'ticket.created_at': {
        operator: 'before (absolute)',
        value: '2015-09-20T03:41:00.000Z',
      },
      'ticket.updated_at': {
        operator: 'within last (relative)',
        range: 'year',
        value: '2',
      },
      'ticket.organization_id': {
        operator: 'is not',
        pre_condition: 'specific',
        value: '12',
      },
      'ticket.owner_id': {
        operator: 'is',
        pre_condition: 'specific',
        value: '47',
        value_completion: 'Bob Smith <bod@example.com>',
      },
      'ticket.created_by_id': {
        operator: 'is',
        pre_condition: 'current_user.id',
        value: '',
        value_completion: ''
      },
    },
    executions: {
      'ticket.priority_id': {
        value: '3',
      },
      'ticket.owner_id': {
        pre_condition: 'specific',
        value: '47',
        value_completion: 'Bob Smith <bod@example.com>'
      },
      'ticket.tags': {
        operator: 'remove',
        value: 'tag1, tag2',
      },
    },
  }
  deepEqual(params, test_params, 'form param check')

  // change selector
  el.find('.js-attributeSelector').last().find('select').val('notification.email').trigger('change')
  el.find('[name="executions::notification.email::subject"]').val('some subject')
  el.find('[data-name="executions::notification.email::body"]').html('lala')
  el.find('[data-name="executions::notification.email::recipient"] .js-select.js-option[data-value="ticket_owner"]').click()

  var params = App.ControllerForm.params(el)
  var test_params = {
    condition: {
      'ticket.title': {
        operator: 'contains',
        value: 'some title',
      },
      'ticket.created_at': {
        operator: 'before (absolute)',
        value: '2015-09-20T03:41:00.000Z',
      },
      'ticket.updated_at': {
        operator: 'within last (relative)',
        range: 'year',
        value: '2',
      },
      'ticket.organization_id': {
        operator: 'is not',
        pre_condition: 'specific',
        value: '12',
      },
      'ticket.owner_id': {
        operator: 'is',
        pre_condition: 'specific',
        value: '47',
        value_completion: 'Bob Smith <bod@example.com>',
      },
      'ticket.created_by_id': {
        operator: 'is',
        pre_condition: 'current_user.id',
        value: '',
        value_completion: ''
      },
    },
    executions: {
      'ticket.priority_id': {
        value: '3',
      },
      'ticket.owner_id': {
        pre_condition: 'specific',
        value: '47',
        value_completion: 'Bob Smith <bod@example.com>'
      },
      'notification.email': {
        recipient: 'ticket_owner',
        subject: 'some subject',
        body: 'lala',
      },
    },
  }
  deepEqual(params, test_params, 'form param check')

  /* with params or defaults */
  $('#forms').append('<hr><h1>form 4</h1><form id="form4"></form>')
  var el = $('#form4')
  var defaults = {
    condition: {
      'ticket.title': {
        operator: 'contains',
        value: 'some title',
      },
    },
    executions: {
      'notification.email': {
        recipient: 'ticket_customer',
        subject: 'some subject',
        body: "some<br>\nbody",
      },
    },
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'condition',  display: 'Conditions', tag: 'ticket_selector', null: true },
        { name: 'executions', display: 'Executions', tag: 'ticket_perform_action', null: true, notification: true },
      ]
    },
    params: defaults,
    autofocus: true
  })
  var params = App.ControllerForm.params(el)
  var test_params = {
    condition: {
      'ticket.title': {
        operator: 'contains',
        value: 'some title',
      },
    },
    executions: {

      'notification.email': {
        recipient: 'ticket_customer',
        subject: 'some subject',
        body: "some<br>\nbody",
      },
    },
  }
  deepEqual(params, test_params, 'form param check')

});