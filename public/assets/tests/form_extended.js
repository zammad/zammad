
// form
test( 'form checks', function() {

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note 1',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
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

  $('#forms').append('<hr><h1>form time check</h1><form id="form1"></form>')

  var el = $('#form1')
  var defaults = {
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
    conditions: {
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
    },
    executions: {
      'ticket.title': {
        value: 'some title new',
      },
      'ticket.priority_id': {
        value: 3,
      },
      'ticket.tags': {
        operator: 'remove',
        value: 'tag1, tag2',
      },
    },
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'escalation_times', display: 'Times', tag: 'sla_times', null: true },
        { name: 'working_hours',    display: 'Hours', tag: 'business_hours', null: true },
        { name: 'conditions',       display: 'Conditions', tag: 'ticket_selector', null: true },
        { name: 'executions',       display: 'Executions', tag: 'ticket_perform_action', null: true },
      ]
    },
    params: defaults,
    autofocus: true
  });

  var params = App.ControllerForm.params( el )
  var test_params = {
    first_response_time: '150',
    first_response_time_in_text: '02:30',
    solution_time: '',
    solution_time_in_text: '',
    update_time: '45',
    update_time_in_text: '00:45',
    conditions: {
      'ticket.title': {
        operator: 'contains',
        value: 'some title',
      },
      'ticket.priority_id': {
        operator: 'is',
        value: ['1', '3'],
      },
      'ticket.created_at': {
        operator: 'before (absolute)',
        value: '2015-09-20T03:41:00.000Z',
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
    },
    executions: {
      'ticket.title': {
        value: 'some title new',
      },
      'ticket.priority_id': {
        value: '3',
      },
      'ticket.tags': {
        operator: 'remove',
        value: 'tag1, tag2',
      },
    },
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
  deepEqual( params, test_params, 'form param check' );

  // change sla times
  el.find('[name="first_response_time_in_text"]').val('0:30').trigger('blur')
  el.find('#update_time').click()

  // change selector
  el.find('[name="conditions::ticket.priority_id::value"]').closest('.js-filterElement').find('.js-remove').click()
  el.find('[name="executions::ticket.title::value"]').closest('.js-filterElement').find('.js-remove').click()

  var params = App.ControllerForm.params( el )
  var test_params = {
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
    conditions: {
      'ticket.title': {
        operator: 'contains',
        value: 'some title',
      },
      'ticket.created_at': {
        operator: 'before (absolute)',
        value: '2015-09-20T03:41:00.000Z',
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
    },
    executions: {
      'ticket.priority_id': {
        value: '3',
      },
      'ticket.tags': {
        operator: 'remove',
        value: 'tag1, tag2',
      },
    },
  }
  deepEqual( params, test_params, 'form param check' );

  //deepEqual( el.find('[name="times::days"]').val(), ['mon', 'wed'], 'check times::days value')
  //equal( el.find('[name="times::hours"]').val(), 2, 'check times::hours value')
  //equal( el.find('[name="times::minutes"]').val(), null, 'check times::minutes value')

});