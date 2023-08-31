window.onload = function() {
  App.Role.refresh([
    {
      name: "Agent",
      permission_ids: [
        48,
      ],
      group_ids: {},
      default_at_signup: false,
      note: "To work on Tickets.",
      active: true,
      updated_at: "2020-07-29T14:57:27.304Z",
      id: 2
    },
    {
      name: "Customer",
      permission_ids: [
        49
      ],
      group_ids: {},
      default_at_signup: true,
      note: "People who create Tickets ask for help.",
      active: true,
      updated_at: "2020-07-29T14:57:27.314Z",
      id: 3
    }
  ])

  App.Permission.refresh([
    {
      name: "ticket.agent",
      note: "Access to Agent Tickets based on Group Access",
      active: true,
      id: 48
    },
    {
      name: "ticket.customer",
      note: "Access to Customer Tickets based on current_user and organization",
      active: true,
      id: 49
    },
  ])

  App.User.refresh([
    {
      login: "nicole.braun@zammad.org",
      firstname: "Nicole",
      lastname: "Braun",
      email: "nicole.braun@zammad.org",
      web: "",
      phone: "",
      fax: "",
      mobile: "",
      street: "",
      zip: "",
      city: "",
      country: "",
      organization_id: 1,
      department: "",
      note: "",
      role_ids: [
        3
      ],
      group_ids: {},
      active: true,
      updated_at: "2023-08-23T08:59:15.437Z",
      organization_ids: [],
      address: "",
      vip: false,
      id: 2
    },
    {
      login: "admin@example.com",
      firstname: "Test Admin",
      lastname: "Agent",
      email: "admin@example.com",
      web: "",
      phone: "",
      fax: "",
      mobile: "",
      street: "",
      zip: "",
      city: "",
      country: "",
      organization_id: null,
      department: null,
      note: "",
      role_ids: [
        2
      ],
      group_ids: {
        1: [
          "full"
        ],
        2: [
          "full"
        ]
      },
      active: true,
      updated_at: "2023-08-23T08:51:07.062Z",
      organization_ids: [],
      address: null,
      vip: false,
      id: 3
    }
  ])

  App.Group.refresh([
    {
      name: "Users",
      assignment_timeout: null,
      follow_up_possible: "yes",
      follow_up_assignment: true,
      email_address_id: 1,
      signature_id: 1,
      note: "Standard Group/Pool for Tickets.",
      active: true,
      shared_drafts: true,
      updated_at: "2023-08-23T08:31:24.665Z",
      reopen_time_in_days: null,
      id: 1
    }
  ])

  App.EmailAddress.refresh([
    {
      name: "Zammad Helpdesk",
      email: "zammad@localhost",
      channel_id: 1,
      note: null,
      active: true,
      updated_at: "2023-08-23T08:31:24.483Z",
      id: 1
    }
  ])

  App.Ticket.refresh([{
    id: 1,
    title: 'ticket1',
    state_id: 1,
    customer_id: 33,
    organization_id: 1,
    owner_id: 1,
    group_id: 1,
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

  App.TicketArticle.refresh([
    {
      from: "Nicole Braun <nicole.braun@zammad.org>",
      to: null,
      cc: null,
      subject: null,
      body: "from customer article",
      content_type: "text/plain",
      ticket_id: 1,
      type_id: 5,
      sender_id: 2,
      internal: false,
      in_reply_to: null,
      preferences: {},
      updated_at: "2023-08-23T08:31:12.483Z",
      id: 1,
      created_by_id: 2,
    },
    {
      from: "Test Admin Agent via Zammad Helpdesk <zammad@localhost>",
      to: "nicole.braun@zammad.org",
      cc: "",
      subject: "Welcome to Zammad!",
      body: "from agent article",
      content_type: "text/html",
      ticket_id: 1,
      type_id: 1,
      sender_id: 1,
      internal: false,
      in_reply_to: "",
      preferences: {},
      updated_at: "2023-08-23T08:59:21.632Z",
      id: 2,
      created_by_id: 3,
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

  QUnit.test('Agent name is unintentionally exposed when reply with quote of own agent article #4768', assert => {
    App.Config.set('ticket_define_email_from', 'AgentNameSystemAddressName')
    App.Config.set('ticket_define_email_from_separator', 'via')

    article1 = App.TicketArticle.find(1);
    console.log('article1', article1)
    assert.equal(article1.recipientName(), 'Nicole Braun');
    article2 = App.TicketArticle.find(2);
    assert.equal(article2.recipientName(), 'Test Admin Agent via Zammad Helpdesk');

    App.Config.set('ticket_define_email_from', 'SystemAddressName')
    App.Config.set('ticket_define_email_from_separator', 'via')

    article1 = App.TicketArticle.find(1);
    assert.equal(article1.recipientName(), 'Nicole Braun');
    article2 = App.TicketArticle.find(2);
    assert.equal(article2.recipientName(), 'Zammad Helpdesk');

    App.Config.set('ticket_define_email_from', 'AgentName')
    App.Config.set('ticket_define_email_from_separator', 'via')

    article1 = App.TicketArticle.find(1);
    assert.equal(article1.recipientName(), 'Nicole Braun');
    article2 = App.TicketArticle.find(2);
    assert.equal(article2.recipientName(), 'Test Admin Agent');
  });
}
