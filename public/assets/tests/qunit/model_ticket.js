window.onload = function() {

  App.Ticket.refresh([{
    id: 1,
    title: 'ticket1',
    state_id: 1,
    customer_id: 33,
    organization_id: 1,
    owner_id: 1,
  },
  {
    id: 2,
    title: 'ticket2',
    state_id: 1,
    customer_id: 44,
    organization_id: 1,
    owner_id: 1,
  },
  {
    id: 3,
    title: 'ticket3',
    state_id: 1,
    customer_id: 55,
    organization_id: undefined,
    owner_id: 1,
  },
  {
    id: 4,
    title: 'ticket4',
    state_id: 1,
    customer_id: 66,
    organization_id: undefined,
    owner_id: 1,
    group_id: 1,
  },
  {
    id: 5,
    title: 'ticket5',
    state_id: 1,
    customer_id: 66,
    organization_id: 123,
    owner_id: 1,
    group_id: 1,
  }])

  App.User.refresh([{
    id: 33,
    login: 'hh@1example.com',
    firstname: 'Harald',
    lastname: 'Habebe',
    email: 'hh1@example.com',
    organization_id: 1,
    role_ids: [3],
    active: true,
  },
  {
    id: 44,
    login: 'hh2@example.com',
    firstname: 'Harald',
    lastname: 'Habebe',
    email: 'hh2@example.com',
    organization_id: 2,
    role_ids: [3],
    active: true,
  },
  {
    id: 55,
    login: 'hh3example.com',
    firstname: 'Harald',
    lastname: 'Habebe',
    email: 'hh3@example.com',
    organization_id: undefined,
    organization_ids: [123], // secondary organization
    role_ids: [3],
    active: true,
  }])

  App.Role.refresh([
    {
      "name":"Agent",
      "permission_ids":[
        48,
      ],
      "group_ids":{},
      "default_at_signup":false,
      "note":"To work on Tickets.",
      "active":true,
      "updated_at":"2020-07-29T14:57:27.304Z",
      "id":2
    },
    {
      "name":"Customer",
      "permission_ids":[
        49
      ],
      "group_ids":{},
      "default_at_signup":true,
      "note":"People who create Tickets ask for help.",
      "active":true,
      "updated_at":"2020-07-29T14:57:27.314Z",
      "id":3
    }
  ])

  App.Permission.refresh([
    {
      "name":"ticket.agent",
      "note":"Access to Agent Tickets based on Group Access",
      "active":true,
      "id":48
    },
    {
      "name":"ticket.customer",
      "note":"Access to Customer Tickets based on current_user and organization",
      "active":true,
      "id":49
    },
  ])

  QUnit.test('ticket.editabe customer user #1', assert => {
    App.Session.set(33)
    ticket1 = App.Ticket.find(1);
    assert.ok(ticket1.editable(), 'access via customer_id');
    ticket2 = App.Ticket.find(2);
    assert.ok(ticket2.editable(), 'access via organization_id');
    ticket3 = App.Ticket.find(3);
    assert.ok(!ticket3.editable(), 'no access');
    ticket4 = App.Ticket.find(4);
    assert.ok(!ticket4.editable(), 'no access');
    ticket5 = App.Ticket.find(5);
    assert.ok(!ticket5.editable(), 'no access');
  });

  QUnit.test('ticket.editabe customer user #2', assert => {
    App.Session.set(44)
    ticket1 = App.Ticket.find(1);
    assert.ok(!ticket1.editable(), 'no access');
    ticket2 = App.Ticket.find(2);
    assert.ok(ticket2.editable(), 'access via customer_id');
    ticket3 = App.Ticket.find(3);
    assert.ok(!ticket3.editable(), 'no access');
    ticket4 = App.Ticket.find(4);
    assert.ok(!ticket4.editable(), 'no access');
    ticket5 = App.Ticket.find(5);
    assert.ok(!ticket5.editable(), 'no access');
  });

  QUnit.test('ticket.editabe customer user #3', assert => {
    App.Session.set(55)
    ticket1 = App.Ticket.find(1);
    assert.ok(!ticket1.editable(), 'no access');
    ticket2 = App.Ticket.find(2);
    assert.ok(!ticket2.editable(), 'no access');
    ticket3 = App.Ticket.find(3);
    assert.ok(ticket3.editable(), 'access via customer_id');
    ticket4 = App.Ticket.find(4);
    assert.ok(!ticket4.editable(), 'no access');
    ticket5 = App.Ticket.find(5);
    assert.ok(ticket5.editable(), 'access via secondary organization');
  });

}
