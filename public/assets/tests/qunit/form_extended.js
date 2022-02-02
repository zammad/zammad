
// form
QUnit.test('form checks', assert => {

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
    priority4_id: '2',
    priority5_id: '1',
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
        { name: 'priority1_id', display: 'Priroity1 (with active selection)', tag: 'select', relation: 'TicketPriority', null: true, options: {} },
        { name: 'priority2_id', display: 'Priroity2 (with active and inactive selection)', tag: 'select', multiple: true, relation: 'TicketPriority', null: true, options: {} },
        { name: 'priority3_id', display: 'Priroity3 (with inactive selection)', tag: 'select', relation: 'TicketPriority', null: true, options: {} },
        { name: 'priority4_id', display: 'Priroity4 (with inactive selection)', tag: 'select', multiple: true, relation: 'TicketPriority', null: true, options: {} },
        { name: 'priority5_id', display: 'Priroity5 (with active selection)', tag: 'select', multiple: true, relation: 'TicketPriority', null: true, options: {} },
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
    priority4_id: '2',
    priority5_id: '1',
    first_response_time: '150',
    first_response_time_enabled: 'on',
    first_response_time_in_text: '02:30',
    response_time: '',
    response_time_in_text: '',
    solution_time: '',
    solution_time_enabled: undefined,
    solution_time_in_text: '',
    update_time: '45',
    update_time_enabled: 'on',
    update_time_in_text: '00:45',
    update_type: 'update',
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
  assert.deepEqual(params, test_params, 'form param check')

  // check possible options
  assert.equal(el.find('[name="priority1_id"] option').length, 3)
  assert.equal(el.find('[name="priority2_id"] option').length, 4)
  assert.equal(el.find('[name="priority3_id"] option').length, 4)
  assert.equal(el.find('[name="priority4_id"] option').length, 4)
  assert.equal(el.find('[name="priority5_id"] option').length, 3)

  // check priority1_id selection order
  assert.equal(el.find('[name="priority1_id"] option:nth-child(1)').text(), '1 low')
  assert.equal(el.find('[name="priority1_id"] option:nth-child(2)').text(), '3 high')
  assert.equal(el.find('[name="priority1_id"] option:nth-child(3)').text(), '4 very high')

  // check priority2_id selection order
  assert.equal(el.find('[name="priority2_id"] option:nth-child(1)').text(), '1 low')
  assert.equal(el.find('[name="priority2_id"] option:nth-child(2)').text(), '2 normal')
  assert.equal(el.find('[name="priority2_id"] option:nth-child(3)').text(), '3 high')
  assert.equal(el.find('[name="priority2_id"] option:nth-child(4)').text(), '4 very high')

  // check priority3_id selection order
  assert.equal(el.find('[name="priority3_id"] option:nth-child(1)').text(), '1 low')
  assert.equal(el.find('[name="priority3_id"] option:nth-child(2)').text(), '2 normal')
  assert.equal(el.find('[name="priority3_id"] option:nth-child(3)').text(), '3 high')
  assert.equal(el.find('[name="priority3_id"] option:nth-child(4)').text(), '4 very high')

  // check priority4_id selection order
  assert.equal(el.find('[name="priority4_id"] option:nth-child(1)').text(), '1 low')
  assert.equal(el.find('[name="priority4_id"] option:nth-child(2)').text(), '2 normal')
  assert.equal(el.find('[name="priority4_id"] option:nth-child(3)').text(), '3 high')
  assert.equal(el.find('[name="priority4_id"] option:nth-child(4)').text(), '4 very high')

  // check priority5_id selection order
  assert.equal(el.find('[name="priority5_id"] option:nth-child(1)').text(), '1 low')
  assert.equal(el.find('[name="priority5_id"] option:nth-child(2)').text(), '3 high')
  assert.equal(el.find('[name="priority5_id"] option:nth-child(3)').text(), '4 very high')

  // change sla times
  el.find('[name="first_response_time_in_text"]').val('0:30').trigger('blur')
  el.find('#update_time').trigger('click')

  var params = App.ControllerForm.params(el)
  var test_params = {
    priority1_id: '1',
    priority2_id: ['1', '2'],
    priority3_id: '2',
    priority4_id: '2',
    priority5_id: '1',
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
    first_response_time_enabled: 'on',
    first_response_time_in_text: '00:30',
    response_time: '',
    response_time_in_text: '',
    solution_time: '',
    solution_time_enabled: undefined,
    solution_time_in_text: '',
    update_time: '',
    update_time_enabled: undefined,
    update_time_in_text: '',
    update_type: undefined,
  }
  assert.deepEqual(params, test_params, 'form param check')

  // change sla times
  el.find('#update_time').attr('checked', false)
  el.find('[value=response]').trigger('click')
  el.find('[name="response_time_in_text"]').val('4:30').trigger('blur')

  var params = App.ControllerForm.params(el)
  var test_params = {
    priority1_id: '1',
    priority2_id: ['1', '2'],
    priority3_id: '2',
    priority4_id: '2',
    priority5_id: '1',
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
    first_response_time_enabled: 'on',
    first_response_time_in_text: '00:30',
    response_time: '270',
    response_time_in_text: '04:30',
    solution_time: '',
    solution_time_enabled: undefined,
    solution_time_in_text: '',
    update_time: '',
    update_time_enabled: 'on',
    update_time_in_text: '',
    update_type: 'response'
  }
  assert.deepEqual(params, test_params, 'form param check post response')

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
  assert.deepEqual(params, test_params, 'form param check');

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
        internal: 'false',
        include_attachments: 'false',
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
        value_completion: '',
      },
      'ticket.owner_id': {
        operator: 'is',
        pre_condition: 'specific',
        value: '47',
        value_completion: '',
      },
      'ticket.created_by_id': {
        operator: 'is',
        pre_condition: 'current_user.id',
        value: null,
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
        value_completion: ''
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
        internal: 'false',
        include_attachments: 'false',
      },
    },
  }
  assert.deepEqual(params, test_params, 'form param check')

  // change selector
  el.find('[name="condition::ticket.priority_id::value"]').closest('.js-filterElement').find('.js-remove').trigger('click')
  el.find('[name="executions::ticket.title::value"]').closest('.js-filterElement').find('.js-remove').trigger('click')

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
        value_completion: '',
      },
      'ticket.owner_id': {
        operator: 'is',
        pre_condition: 'specific',
        value: '47',
        value_completion: '',
      },
      'ticket.created_by_id': {
        operator: 'is',
        pre_condition: 'current_user.id',
        value: null,
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
        value_completion: ''
      },
      'ticket.tags': {
        operator: 'remove',
        value: 'tag1, tag2',
      },
      'notification.email': {
        recipient: 'ticket_customer',
        subject: 'some subject',
        body: "some<br>\nbody",
        internal: 'false',
        include_attachments: 'false',
      },
    },
  }
  assert.deepEqual(params, test_params, 'form param check')

  // change selector
  el.find('[name="executions::notification.email::subject"]').closest('.js-filterElement').find('.js-remove').trigger('click')

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
        value_completion: '',
      },
      'ticket.owner_id': {
        operator: 'is',
        pre_condition: 'specific',
        value: '47',
        value_completion: '',
      },
      'ticket.created_by_id': {
        operator: 'is',
        pre_condition: 'current_user.id',
        value: null,
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
        value_completion: ''
      },
      'ticket.tags': {
        operator: 'remove',
        value: 'tag1, tag2',
      },
    },
  }
  assert.deepEqual(params, test_params, 'form param check')

  // change selector
  el.find('.js-attributeSelector').last().find('select').val('notification.email').trigger('change')
  el.find('[name="executions::notification.email::subject"]').val('some subject')
  el.find('[data-name="executions::notification.email::body"]').html('lala')
  el.find('[data-name="executions::notification.email::recipient"] .js-select.js-option[data-value="ticket_owner"]').trigger('click')

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
        value_completion: '',
      },
      'ticket.owner_id': {
        operator: 'is',
        pre_condition: 'specific',
        value: '47',
        value_completion: '',
      },
      'ticket.created_by_id': {
        operator: 'is',
        pre_condition: 'current_user.id',
        value: null,
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
        value_completion: ''
      },
      'notification.email': {
        recipient: 'ticket_owner',
        subject: 'some subject',
        body: 'lala',
        internal: 'false',
        include_attachments: 'false',
      },
    },
  }
  assert.deepEqual(params, test_params, 'form param check')

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
        internal: 'false',
        include_attachments: 'false',
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
        internal: 'false',
        include_attachments: 'false',
      },
    },
  }
  assert.deepEqual(params, test_params, 'form param check')

  $('#forms').append('<hr><h1>form 5</h1><form id="form5"></form>')
  var el = $('#form5')
  var defaults = {
    condition: {
      'article.body': {
        operator: 'contains',
        value: 'some body',
      },
    },
    executions: {
      'notification.email': {
        recipient: 'ticket_customer',
        subject: 'some subject',
        body: "some<br>\nbody",
        internal: 'false',
        include_attachments: 'true',
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
      'article.body': {
        operator: 'contains',
        value: 'some body',
      },
    },
    executions: {
      'notification.email': {
        recipient: 'ticket_customer',
        subject: 'some subject',
        body: "some<br>\nbody",
        internal: 'false',
        include_attachments: 'true',
      },
    },
  }
  assert.deepEqual(params, test_params, 'form article body param check')

  App.User.refresh([
    {
      id:         44,
      login:      'bod@example.com',
      email:      'bod@example.com',
      firstname:  'Bob',
      lastname:   'Smith',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         45,
      login:      'john@example.com',
      email:      'john@example.com',
      firstname:  'John',
      lastname:   'Doe',
      active:     true,
      created_at: '2014-07-10T11:17:34.000Z',
    },
    {
      id:         46,
      login:      'sam@example.com',
      email:      'sam@example.com',
      firstname:  'Sam',
      lastname:   'Bond',
      active:     true,
      created_at: '2014-08-10T11:17:34.000Z',
    },
    {
      id:         30,
      login:      'clark@example.com',
      email:      'clark@example.com',
      firstname:  'Clark',
      lastname:   'Olsen',
      active:     true,
      created_at: '2016-02-10T11:17:34.000Z',
    },
    {
      id:         31,
      login:      'james@example.com',
      email:      'james@example.com',
      firstname:  'James',
      lastname:   'Puth',
      active:     true,
      created_at: '2016-03-10T11:17:34.000Z',
    },
    {
      id:         32,
      login:      'charles@example.com',
      email:      'charles@example.com',
      firstname:  'Charles',
      lastname:   'Kent',
      active:     true,
      created_at: '2016-04-10T11:17:34.000Z',
    },
  ])

  App.Organization.refresh([
    {
      id:         9,
      name:      'Org 1',
      active:     true,
      created_at: '2018-06-10T11:19:34.000Z',
    },
    {
      id:         10,
      name:      'Org 2',
      active:     true,
      created_at: '2018-06-10T11:19:34.000Z',
    },
    {
      id:         11,
      name:      'Org 3',
      active:     true,
      created_at: '2018-06-10T11:19:34.000Z',
    },
  ])

  /* with params or defaults */
  $('#forms').append('<hr><h1>form condition check for multiple user and organisation selection</h1><form id="form6"></form>')
  var el = $('#form6')
  var defaults = {
    condition: {
      'ticket.title': {
        operator: 'contains',
        value: 'some title',
      },
      'ticket.organization_id': {
        operator: 'is',
        pre_condition: 'specific',
        value: [9, 10, 11],
      },
      'ticket.owner_id': {
        operator: 'is not',
        pre_condition: 'specific',
        value: [44, 45, 46],
      },
      'ticket.customer_id': {
        operator: 'is',
        pre_condition: 'specific',
        value: [30, 31, 32],
      },
    },
    executions: {
      'ticket.title': {
        value: 'some title new',
      },
      'ticket.owner_id': {
        pre_condition: 'specific',
        value: [44, 46],
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
      'ticket.organization_id': {
        operator: 'is',
        pre_condition: 'specific',
        value: ['9', '10', '11'],
        value_completion: ''
      },
      'ticket.owner_id': {
        operator: 'is not',
        pre_condition: 'specific',
        value: ['44', '45', '46'],
        value_completion: ''
      },
      'ticket.customer_id': {
        operator: 'is',
        pre_condition: 'specific',
        value: ['30', '31', '32'],
        value_completion: ''
      },
    },
    executions: {
      'ticket.title': {
        value: 'some title new',
      },
      'ticket.owner_id': {
        pre_condition: 'specific',
        value: ['44', '46'],
        value_completion: ''
      },
    },
  }
  assert.deepEqual(params, test_params, 'form param condition check for multiple users and organisation')
});
