
// form
test( "form simple checks", function() {

  App.TicketPriority.refresh( [
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
  ] )

  // timeplan
  $('#forms').append('<hr><h1>form time check</h1><form id="form1"></form>')

  var el = $('#form1')
  var defaults = {
    times: {
      days:  ['mon', 'wed'],
      hours: [2],
    },
    conditions: {
      'tickets.title':       'some title',
      'tickets.priority_id': [1,2,3],
    },
    executions: {
      'tickets.title':       'some title new',
      'tickets.priority_id': 3,
    },
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'times', display: 'Times', tag: 'timeplan', null: true, default: defaults['times'] },
        { name: 'conditions', display: 'Conditions', tag: 'ticket_attribute_selection', null: true, default: defaults['conditions'] },
        { name: 'executions', display: 'Executions', tag: 'ticket_attribute_set', null: true, default: defaults['executions'] },
      ]
    },
    autofocus: true
  });
  deepEqual( el.find('[name="times::days"]').val(), ['mon', 'wed'], 'check times::days value')
  equal( el.find('[name="times::hours"]').val(), 2, 'check times::hours value')
  equal( el.find('[name="times::minutes"]').val(), null, 'check times::minutes value')

  var params = App.ControllerForm.params( el )
  var test_params = {
    times: {
      days:  ['mon', 'wed'],
      hours: '2',
    },
    conditions: {
      'tickets.title':       'some title',
      'tickets.priority_id': ['1','3'],
    },
    executions: {
      'tickets.title':       'some title new',
      'tickets.priority_id': '3',
    },
  }
  deepEqual( params, test_params, 'form param check' );


});