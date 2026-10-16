// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

window.onload = function() {
  App.Config.set('ui_ticket_zoom_article_email_full_quote_header', true)
  App.Config.set('ticket_define_email_from', 'AgentNameSystemAddressName')
  App.Config.set('ticket_define_email_from_separator', 'via')
  App.Config.set('user_name_format', 'first_last')

  App.Role.refresh([
    { name: 'Agent',    permission_ids: [48], group_ids: {}, active: true, id: 2 },
    { name: 'Customer', permission_ids: [49], group_ids: {}, active: true, id: 3 },
  ])

  App.Permission.refresh([
    { name: 'ticket.agent',    active: true, id: 48 },
    { name: 'ticket.customer', active: true, id: 49 },
  ])

  App.User.refresh([
    { login: '-',                     firstname: '-',    lastname: '',    email: '',                      role_ids: [],  active: false, id: 1 },
    { login: 'jane.roe@example.org',  firstname: 'Jane', lastname: 'Roe', email: 'jane.roe@example.org',  role_ids: [3], active: true, id: 2 },
    { login: 'john.doe@example.com',  firstname: 'John', lastname: 'Doe', email: 'john.doe@example.com',  role_ids: [2], group_ids: { 1: ['full'] }, active: true, id: 3 },
    { login: 'edge.case@example.com', firstname: 'Edge', lastname: 'Case', email: 'edge.case@example.com', role_ids: [2], group_ids: { 1: ['full'] }, active: true, id: 4 },
    { login: 'nameless@example.org',  firstname: '',     lastname: '',     email: 'nameless@example.org',  role_ids: [3], active: true, id: 5 },
    { login: 'nameless.agent@example.com', firstname: '', lastname: '',    email: 'nameless.agent@example.com', role_ids: [2], group_ids: { 1: ['full'] }, active: true, id: 6 },
  ])

  App.Group.refresh([
    { name: 'Users',      email_address_id: 1,    active: true, id: 1 },
    { name: 'No Address', email_address_id: null, active: true, id: 2 },
    { name: 'Stale',      email_address_id: 999,  active: true, id: 3 },
    { name: 'Sales',      email_address_id: 2,    active: true, id: 4 },
  ])

  App.EmailAddress.refresh([
    { name: 'Zammad Helpdesk', email: 'zammad@localhost', channel_id: 1, active: true, id: 1 },
    { name: 'Support, Sales',  email: 'sales@localhost',  channel_id: 1, active: true, id: 2 },
  ])

  App.TicketArticleType.refresh([
    { name: 'email', active: true, id: 1 },
    { name: 'phone', active: true, id: 2 },
    { name: 'web',   active: true, id: 3 },
  ])

  App.TicketArticleSender.refresh([
    { name: 'Agent',    active: true, id: 1 },
    { name: 'Customer', active: true, id: 2 },
    { name: 'System',   active: true, id: 3 },
  ])

  App.Ticket.refresh([
    { id: 1, title: 'ticket1', group_id: 1, customer_id: 2, state_id: 1, owner_id: 3 },
    { id: 2, title: 'ticket in a group whose address is not loaded', group_id: 3, customer_id: 2, state_id: 1, owner_id: 3 },
  ])

  App.TicketArticle.refresh([
    {
      id: 1,
      ticket_id: 1,
      type_id: 1,
      sender_id: 2,
      created_by_id: 2,
      from: 'Jane Roe <jane.roe@example.org>',
      to: '"Doe, John" <john.doe@example.com>, other@example.org',
      cc: '"Roe, Jane" <jane.roe@example.org>, "Doe, Unknown" <unknown@example.org>',
    },
    {
      id: 2,
      ticket_id: 1,
      type_id: 1,
      sender_id: 2,
      created_by_id: 2,
      from: 'Jane Roe <jane.roe@example.org>',
      to: 'invalid sender, realname <john.doe@example.com>',
    },
    {
      id: 3,
      ticket_id: 1,
      type_id: 1,
      sender_id: 2,
      created_by_id: 2,
      from: 'Jane Roe <jane.roe@example.org>',
      to: 'Edge Case <Edge.Case@Example.com>',
    },
    {
      id: 4,
      ticket_id: 1,
      type_id: 1,
      sender_id: 2,
      created_by_id: 2,
      from: 'Jane Roe <jane.roe@example.org>',
      to: 'undisclosed-recipients:;',
    },
    { id: 5, ticket_id: 1, type_id: 2, sender_id: 2, created_by_id: 3, from: 'Jane Roe', to: 'Users' },
    { id: 6, ticket_id: 1, type_id: 2, sender_id: 2, created_by_id: 3, from: 'Jane Roe', to: 'Unknown Group' },
    { id: 7, ticket_id: 1, type_id: 2, sender_id: 2, created_by_id: 3, from: 'Jane Roe', to: 'No Address' },
    { id: 8, ticket_id: 1, type_id: 2, sender_id: 2, created_by_id: 3, from: 'Jane Roe', to: 'Stale' },
    { id: 13, ticket_id: 1, type_id: 2, sender_id: 2, created_by_id: 3, from: 'Jane Roe', to: 'Sales' },
    // Created by user 1 like every inbound mail; the header names the sender.
    { id: 9,  ticket_id: 1, type_id: 1, sender_id: 2, created_by_id: 1, from: 'Jane Roe <jane.roe@example.org>', to: 'zammad@localhost' },
    { id: 10, ticket_id: 1, type_id: 1, sender_id: 3, created_by_id: 1, from: 'Zammad Helpdesk <zammad@localhost>', to: 'jane.roe@example.org' },
    // Agent articles in a group whose email address cannot be resolved client side.
    { id: 11, ticket_id: 2, type_id: 3, sender_id: 1, created_by_id: 3,  from: 'John Private <john.private@example.com>', to: 'jane.roe@example.org' },
    { id: 12, ticket_id: 2, type_id: 3, sender_id: 1, created_by_id: 99, from: 'Unknown Author <unknown@example.org>',    to: 'jane.roe@example.org' },
    // Author not loaded, so the sender is resolved through the header address.
    { id: 14, ticket_id: 1, type_id: 1, sender_id: 1, created_by_id: 99, from: 'Edge Case <Edge.Case@Example.com>', to: 'jane.roe@example.org' },
  ])

  QUnit.module('App.FullQuoteHeader recipient lines')

  QUnit.test('keeps quoted display names with a comma intact', assert => {
    const article = App.TicketArticle.fullLocal(1)

    assert.equal(App.FullQuoteHeader.fullQuoteHeaderForwardTo(article), 'John Doe, other@example.org', 'agent recipient is rendered name only, without a stray fragment')
    assert.equal(App.FullQuoteHeader.fullQuoteHeaderForwardCC(article), 'Jane Roe <jane.roe@example.org>, "Doe, Unknown" <unknown@example.org>', 'customer keeps the address, unknown recipient keeps the mailbox')
  })

  QUnit.test('falls back to comma splitting for lists the parser rejects', assert => {
    const article = App.TicketArticle.fullLocal(2)

    assert.equal(App.FullQuoteHeader.fullQuoteHeaderForwardTo(article), 'invalid sender, John Doe')
  })

  QUnit.test('keeps an empty group without mailboxes as raw value', assert => {
    const article = App.TicketArticle.fullLocal(4)

    assert.equal(App.FullQuoteHeader.fullQuoteHeaderForwardTo(article), 'undisclosed-recipients:;')
  })

  QUnit.test('resolves users regardless of the address case', assert => {
    const article = App.TicketArticle.fullLocal(3)

    assert.equal(App.FullQuoteHeader.fullQuoteHeaderForwardTo(article), 'Edge Case')
  })

  QUnit.test('handles unusual recipient line shapes', assert => {
    const article = App.TicketArticle.fullLocal(1)
    const render  = (input) => App.FullQuoteHeader.fullQuoteHeaderEnsureMultiPrivacy(input, article)

    assert.equal(render('   '), '', 'whitespace only renders nothing')
    assert.equal(render('Nicole Braun'), 'Nicole Braun', 'name only keeps the raw value')
    assert.equal(render('Braun, Nicole'), 'Braun, Nicole', 'name with a comma only keeps the raw value')
    assert.equal(render('John Doe john.doe@example.com'), 'John Doe', 'address without angle brackets still resolves the agent')
    assert.equal(render('john.doe@example.com,'), 'John Doe', 'trailing separator renders no empty recipient')
    assert.equal(render('john.doe@example.com; other@example.org'), 'John Doe, other@example.org', 'semicolon separated recipients are scrubbed individually')
    assert.equal(render('Team: john.doe@example.com, other@example.org;'), 'John Doe, other@example.org', 'group members are rendered')
    assert.equal(render('Jörg Müller <unknown@example.org>'), '"Jörg Müller" <unknown@example.org>', 'non-ASCII display name of an unknown recipient is quoted')
    assert.equal(render('Jörg Müller <john.doe@example.com>'), 'John Doe', 'non-ASCII display name of an agent renders the name only')
  })

  QUnit.test('quotes the group email address for inbound phone articles', assert => {
    assert.equal(App.FullQuoteHeader.fullQuoteHeaderForwardTo(App.TicketArticle.fullLocal(5)), 'Zammad Helpdesk <zammad@localhost>', 'known group renders its email address')
    assert.equal(App.FullQuoteHeader.fullQuoteHeaderForwardTo(App.TicketArticle.fullLocal(6)), 'Unknown Group', 'unknown group keeps the raw value')
    assert.equal(App.FullQuoteHeader.fullQuoteHeaderForwardTo(App.TicketArticle.fullLocal(7)), 'No Address', 'group without an email address keeps the raw value')
    assert.equal(App.FullQuoteHeader.fullQuoteHeaderForwardTo(App.TicketArticle.fullLocal(8)), 'Stale', 'group with a stale email address reference keeps the raw value')
    assert.equal(App.FullQuoteHeader.fullQuoteHeaderForwardTo(App.TicketArticle.fullLocal(13)), '"Support, Sales" <sales@localhost>', 'display name with a comma is quoted like every other address')
  })

  QUnit.test('never renders the system user as sender', assert => {
    const inbound = App.TicketArticle.fullLocal(9)
    const system  = App.TicketArticle.fullLocal(10)

    assert.equal(App.FullQuoteHeader.fullQuoteHeaderForwardFrom(inbound), 'Jane Roe <jane.roe@example.org>', 'inbound mail created by user 1 resolves the customer through the header')
    assert.equal(App.FullQuoteHeader.fullQuoteHeaderForwardFrom(system), 'Zammad Helpdesk <zammad@localhost>', 'system mail keeps the raw header the server built')
    assert.strictEqual(App.FullQuoteHeader.fullQuoteHeaderEnsurePrivacy(App.User.find(1), inbound), undefined, 'user 1 is not resolvable as an object either')
  })

  QUnit.test('resolves the sender through the header regardless of the address case', assert => {
    const article = App.TicketArticle.fullLocal(14)

    assert.equal(App.FullQuoteHeader.fullQuoteHeaderForwardFrom(article), 'Edge Case via Zammad Helpdesk <zammad@localhost>', 'agent is resolved, so the raw header with the personal address is not used')
  })

  QUnit.module('App.User#recipientName')

  QUnit.test('orders customer names by the user name format', assert => {
    const ticket   = App.Ticket.find(1)
    const customer = App.User.fullLocal(2)
    const agent    = App.User.fullLocal(3)

    App.Config.set('user_name_format', 'last_first_comma')
    App.Config.set('ticket_define_email_from', 'AgentName')

    assert.equal(customer.recipientName(ticket), 'Roe, Jane', 'customer citation name follows the user name format')
    assert.equal(customer.recipientName(ticket, true), '"Roe, Jane" <jane.roe@example.org>', 'customer sender line follows the user name format')
    assert.equal(agent.recipientName(ticket), 'John Doe', 'agent citation name stays first-last like the outbound From header')
    assert.equal(agent.recipientName(ticket, true), 'John Doe <zammad@localhost>', 'agent sender line keeps the group address, never the personal one')
    assert.equal(App.TicketArticle.fullLocal(1).recipientName(), 'Roe, Jane', 'article citation name of a customer author')

    const nameless = App.User.fullLocal(5)
    assert.equal(nameless.recipientName(ticket), '', 'nameless customer citation name stays empty')
    assert.equal(nameless.recipientName(ticket, true), 'nameless@example.org', 'nameless customer sender line falls back to the bare address')

    App.Config.set('user_name_format', 'first_last')
    App.Config.set('ticket_define_email_from', 'AgentNameSystemAddressName')
  })

  QUnit.test('renders agents name only when the sender address cannot be resolved', assert => {
    const ticket   = App.Ticket.find(2)
    const agent    = App.User.fullLocal(3)
    const nameless = App.User.fullLocal(6)

    App.Config.set('ticket_define_email_from', 'AgentNameSystemAddressName')
    assert.equal(agent.recipientName(ticket), 'John Doe', 'citation name without the group address name')
    assert.equal(agent.recipientName(ticket, true), 'John Doe', 'sender line without any address')
    assert.equal(nameless.recipientName(ticket, true), 'Agent', 'nameless agent gets the translated label, never personal data')
    assert.equal(App.User.fullLocal(2).recipientName(ticket, true), 'Jane Roe <jane.roe@example.org>', 'customer sender line does not depend on the group address')

    App.Config.set('ticket_define_email_from', 'SystemAddressName')
    assert.equal(agent.recipientName(ticket, true), 'John Doe', 'the hidden-name format still shows the name rather than nothing')

    App.Config.set('ticket_define_email_from', 'AgentNameSystemAddressName')

    assert.equal(App.FullQuoteHeader.fullQuoteHeaderForwardFrom(App.TicketArticle.fullLocal(11)), 'John Doe', 'forwarded From line does not fall back to the raw header')
    assert.equal(App.TicketArticle.fullLocal(11).recipientName(), 'John Doe', 'article citation name')
    assert.strictEqual(App.TicketArticle.fullLocal(12).recipientName(), undefined, 'article citation name of an author that is not loaded')
    assert.equal(App.FullQuoteHeader.fullQuoteHeaderForwardFrom(App.TicketArticle.fullLocal(12)), 'Unknown Author <unknown@example.org>', 'unknown author keeps the raw header')
  })

  QUnit.module('App.FullQuoteHeader recipient lines')

  QUnit.test('orders agent recipient names by the user name format', assert => {
    App.Config.set('user_name_format', 'last_first_comma')
    const article = App.TicketArticle.fullLocal(1)

    assert.equal(App.FullQuoteHeader.fullQuoteHeaderForwardTo(article), 'Doe, John, other@example.org')
    App.Config.set('user_name_format', 'first_last')
  })
}
