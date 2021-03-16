window.onload = function() {

  var ticketData = {
      "number": "72008",
      "title": "asdfasdf",
      "group_id": 1,
      "owner_id": 6,
      "updated_by_id": 6,
      "created_by_id": 6,
      "customer_id": 6,
      "state_id": 4,
      "priority_id": 2,
      "created_at": "2017-02-09T09:16:56.192Z",
      "updated_at": "2017-02-09T09:16:56.192Z",
      "pending_time": "2017-02-09T09:16:56.192Z",
      "aaaaa": "1234568791",
      "anrede": "Herr",
      "asdf": "",
      "organization_id": 6,
      "organization": {
        "name": "harald test gmbh",
        "domain": "www.harald-ist-cool.de",
        "shared": true,
        "note": "<div>harald test gmbh</div>",
        "member_ids": [
            6,
            2
        ],
        "active": true,
        "created_at": "2017-02-09T09:16:56.192Z",
        "updated_at": "2017-02-09T09:16:56.192Z",
        "domain_assignment": false,
        "updated_by_id": 6,
        "created_by_id": 6,
        "id": 6
      },
      "group": {
        "name": "Users",
        "assignment_timeout": null,
        "follow_up_possible": "reject",
        "follow_up_assignment": true,
        "email_address_id": 1,
        "signature_id": 1,
        "note": "Standard Group/Pool for Tickets.",
        "active": true,
        "updated_at": "2017-01-18T13:45:30.528Z",
        "id": 1
      },
      "owner": {
        "login": "-",
        "firstname": "-",
        "lastname": "",
        "email": "",
        "web": "",
        "password": "",
        "phone": "",
        "fax": "",
        "mobile": "",
        "street": "",
        "zip": "",
        "city": "",
        "country": "",
        "organization_id": null,
        "department": "",
        "note": "",
        "role_ids": [],
        "group_ids": [],
        "active": false,
        "updated_at": "2016-08-02T14:25:24.053Z",
        "address": "",
        "vip": false,
        "anrede": null,
        "asdf": null,
        "id": 1
      },
      "state": {
        "name": "closed",
        "note": null,
        "active": true,
        "id": 4
      },
      "priority": {
        "name": "2 normal",
        "note": null,
        "active": true,
        "updated_at": "2016-08-02T14:25:24.677Z",
        "id": 2
      },
      "article": {
        "from": "Test Master Agent",
        "to": "agent1@example.com",
        "cc": "agent1+cc@example.com",
        "body": "asdfasdfasdf<br><br><div data-signature=\"true\" data-signature-id=\"1\">  Test Master Agent<br><br>--<br> Super Support - Waterford Business Park<br> 5201 Blue Lagoon Drive - 8th Floor &amp; 9th Floor - Miami, 33126 USA<br> Email: hot@example.com - Web: http://www.example.com/<br>--</div>",
        "content_type": "text/html",
        "ticket_id": "2",
        "type_id": 1,
        "sender_id": 1,
        "internal": false,
        "in_reply_to": "<20170217100622.2.152971@zammad.example.com>",
        "form_id": "326044216"
      },
      "customer": {
        "login": "hc@zammad.com",
        "firstname": "Harald",
        "lastname": "Customer",
        "email": "hc@zammad.com",
        "web": "zammad.com",
        "password": "",
        "phone": "1234567894",
        "fax": "",
        "mobile": "",
        "street": "",
        "zip": "",
        "city": "",
        "country": "",
        "organization_id": 6,
        "created_by_id": 6,
        "updated_by_id": 6,
        "department": "",
        "note": "",
        "role_ids": [
          3
        ],
        "group_ids": [],
        "active": true,
        "created_at": "2017-02-09T09:16:56.192Z",
        "updated_at": "2017-02-09T09:16:56.192Z",
        "address": "Walter-Gropius-Straße 17, 80807 München, Germany",
        "web": "www.harald-ist-cool.de",
        "vip": false,
        "id": 434
      },
      "tags": ["tag a", "tag b"],
      "mention_user_ids": [1,3,5,6],
      "escalation_at": "2017-02-09T09:16:56.192Z",
      "last_contact_agent_at": "2017-02-09T09:16:56.192Z",
      "last_contact_agent_at": "2017-02-09T09:16:56.192Z",
      "last_contact_at": "2017-02-09T09:16:56.192Z",
      "last_contact_customer_at": "2017-02-09T09:16:56.192Z",
      "first_response_at": "2017-02-09T09:16:56.192Z",
      "close_at": "2017-02-09T09:16:56.192Z",
      "id": 8
  };

  App.User.refresh([{
    "login": "hh@zammad.com",
    "firstname": "Harald",
    "lastname": "Habebe",
    "email": "hh@zammad.com",
    "web": "",
    "password": "",
    "phone": "",
    "fax": "",
    "mobile": "",
    "street": "",
    "zip": "",
    "city": "",
    "country": "",
    "organization_id": 6,
    "department": "",
    "note": "",
    "role_ids": [
      1,
      2,
      5,
      6,
      4
    ],
    "group_ids": [
      1
    ],
    "active": true,
    "updated_at": "2017-02-09T09:17:04.770Z",
    "address": "",
    "vip": false,
    "anrede": "",
    "asdf": "",
    "id": 6
  }]);

  var sessionData = App.User.find(6);

  /*
   * ------------------------------------------------------------------------
   * Test functions
   * ------------------------------------------------------------------------
   */

  var testContains = function (key, value, ticket) {
    setting = {
      "condition": {
        [key]: {
          "operator": "contains",
          "value": value
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, true, result);

    setting = {
      "condition": {
        [key]: {
          "operator": "contains not",
          "value": value
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, false, result);
  };

  var testIs = function (key, value, ticket) {
    setting = {
      "condition": {
        [key]: {
          "operator": "is",
          "value": value
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, true, result);

    setting = {
      "condition": {
        [key]: {
          "operator": "is not",
          "value": value
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, false, result);
  };

  var testPreConditionUser = function (key, specificValue, ticket, session) {
    App.Session.set(6);

    setting = {
      "condition": {
        [key]: {
          "operator": "is",
          "pre_condition": "current_user.id",
          "value": "",
          "value_completion": ""
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, true, result);

    setting = {
      "condition": {
        [key]: {
          "operator": "is not",
          "pre_condition": "current_user.id",
          "value": "",
          "value_completion": ""
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, false, result);

    setting = {
      "condition": {
        [key]: {
          "operator": "is",
          "pre_condition": "specific",
          "value": specificValue,
          "value_completion": "Nicole Braun <nicole.braun@zammad.org>"
        }
      }
    };

    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, true, result);

    setting = {
      "condition": {
        [key]: {
          "operator": "is not",
          "pre_condition": "specific",
          "value": specificValue,
          "value_completion": "Nicole Braun <nicole.braun@zammad.org>"
        }
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, false, result);

    setting = {
      "condition": {
        [key]: {
          "operator": "is not",
          "pre_condition": "specific",
          "value": specificValue,
          "value_completion": "Nicole Braun <nicole.braun@zammad.org>"
        }
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, false, result);

    setting = {
      "condition": {
        [key]: {
          "operator": "is",
          "pre_condition": "not_set",
        }
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, false, result);

    setting = {
      "condition": {
        [key]: {
          "operator": "is not",
          "pre_condition": "not_set",
        }
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, true, result);
  };

  var testPreConditionOrganization = function (key, specificValue, ticket, session) {
    App.Session.set(6);

    setting = {
      "condition": {
        [key]: {
          "operator": "is",
          "pre_condition": "current_user.organization_id",
          "value": "",
          "value_completion": ""
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, true, result);

    setting = {
      "condition": {
        [key]: {
          "operator": "is not",
          "pre_condition": "current_user.organization_id",
          "value": "",
          "value_completion": ""
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, false, result);

    setting = {
      "condition": {
        [key]: {
          "operator": "is",
          "pre_condition": "specific",
          "value": specificValue,
          "value_completion": "Nicole Braun <nicole.braun@zammad.org>"
        }
      }
    };

    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, true, result);

    setting = {
      "condition": {
        [key]: {
          "operator": "is not",
          "pre_condition": "specific",
          "value": specificValue,
          "value_completion": "Nicole Braun <nicole.braun@zammad.org>"
        }
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, false, result);

    setting = {
      "condition": {
        [key]: {
          "operator": "is not",
          "pre_condition": "specific",
          "value": specificValue,
          "value_completion": "Nicole Braun <nicole.braun@zammad.org>"
        }
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, false, result);

    setting = {
      "condition": {
        [key]: {
          "operator": "is",
          "pre_condition": "not_set",
        }
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, false, result);

    setting = {
      "condition": {
        [key]: {
          "operator": "is not",
          "pre_condition": "not_set",
        }
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, true, result);
  };

  var testPreConditionTags = function (key, ticket) {
    App.Session.set(6);

    setting = {
      "condition": {
        "ticket.tags": {
          "operator": "contains one",
          "value": "tag a",
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, true, result);

    setting = {
      "condition": {
        "ticket.tags": {
          "operator": "contains one",
          "value": "tag aa",
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, false, result);

    setting = {
      "condition": {
        "ticket.tags": {
          "operator": "contains all",
          "value": "tag a",
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, true, result);

    setting = {
      "condition": {
        "ticket.tags": {
          "operator": "contains all",
          "value": "tag a, not existing",
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, false, result);

    setting = {
      "condition": {
        "ticket.tags": {
          "operator": "contains all not",
          "value": "tag a",
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, false, result);

    setting = {
      "condition": {
        "ticket.tags": {
          "operator": "contains all not",
          "value": "tag a, tag b",
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, false, result);

    setting = {
      "condition": {
        "ticket.tags": {
          "operator": "contains all not",
          "value": "tag a, tag b, tag c",
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, false, result);

    setting = {
      "condition": {
        "ticket.tags": {
          "operator": "contains all not",
          "value": "tag c, tag d",
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, true, result);

    setting = {
      "condition": {
        "ticket.tags": {
          "operator": "contains one not",
          "value": "tag a",
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, true, result);

    setting = {
      "condition": {
        "ticket.tags": {
          "operator": "contains one not",
          "value": "tag a, tag b",
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, false, result);

    setting = {
      "condition": {
        "ticket.tags": {
          "operator": "contains one not",
          "value": "tag a, tag c",
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, true, result);

    setting = {
      "condition": {
        "ticket.tags": {
          "operator": "contains one not",
          "value": "tag c",
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, true, result);

  };

  var testTime = function (key, value, ticket) {
    valueDate   = new Date(value);
    compareDate = new Date( valueDate.setHours( valueDate.getHours() - 1 ) ).toISOString();
    setting = {
      "condition": {
        [key]: {
          "operator": "after (absolute)",
          "value": compareDate
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, true, result);

    valueDate   = new Date(value);
    compareDate = new Date( valueDate.setHours( valueDate.getHours() + 1 ) ).toISOString();
    setting = {
      "condition": {
        [key]: {
          "operator": "after (absolute)",
          "value": compareDate
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, false, result);

    valueDate   = new Date(value);
    compareDate = new Date( valueDate.setHours( valueDate.getHours() - 1 ) ).toISOString();
    setting = {
      "condition": {
        [key]: {
          "operator": "before (absolute)",
          "value": compareDate
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, false, result);

    valueDate   = new Date(value);
    compareDate = new Date( valueDate.setHours( valueDate.getHours() + 1 ) ).toISOString();
    setting = {
      "condition": {
        [key]: {
          "operator": "before (absolute)",
          "value": compareDate
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, true, result);

    valueDate   = new Date(value);
    compareDate = new Date( valueDate.setHours( valueDate.getHours() + 2 ) ).toISOString();
    setting = {
      "condition": {
        [key]: {
          "operator": "before (relative)",
          "value": 1,
          "range": "hour"
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, true, result);
  };

  var testTimeBeforeRelative = function (key, value, range, expectedResult, ticket) {
    setting = {
      "condition": {
        [key]: {
          "operator": "before (relative)",
          "value": value,
          "range": range
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, expectedResult, result);
  };

  var testTimeAfterRelative = function (key, value, range, expectedResult, ticket) {
    setting = {
      "condition": {
        [key]: {
          "operator": "after (relative)",
          "value": value,
          "range": range
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, expectedResult, result);
  };

  var testTimeWithinNextRelative = function (key, value, range, expectedResult, ticket) {
    setting = {
      "condition": {
        [key]: {
          "operator": "within next (relative)",
          "value": value,
          "range": range
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, expectedResult, result);
  };

  var testTimeWithinLastRelative = function (key, value, range, expectedResult, ticket) {
    setting = {
      "condition": {
        [key]: {
          "operator": "within last (relative)",
          "value": value,
          "range": range
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    equal(result, expectedResult, result);
  };

  /*
   * ------------------------------------------------------------------------
   * Field tests
   * ------------------------------------------------------------------------
   */

  test("ticket number", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains('ticket.number', '72', ticket);
  });

  test("ticket title", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains('ticket.title', 'asd', ticket);
  });

  test("ticket customer_id", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    App.Session.set(6);

    testPreConditionUser('ticket.customer_id', '6', ticket, sessionData);
  });

  test("ticket organization_id", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testPreConditionUser('ticket.organization_id', '6', ticket, sessionData);
  });

  test("ticket group_id", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testIs('ticket.group_id', ['1'], ticket, sessionData);
  });

  test("ticket owner_id", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    App.Session.set(6);

    testPreConditionUser('ticket.owner_id', '6', ticket, sessionData);
  });

  test("ticket state_id", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testIs('ticket.state_id', ['4'], ticket, sessionData);
  });

  test("ticket pending_time", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testTime('ticket.pending_time', ticket.pending_time, ticket);

    // -------------------------
    // BEFORE TIME
    // -------------------------

    // hour
    ticket.pending_time = new Date().toISOString();
    testTimeBeforeRelative('ticket.pending_time', 1, 'hour', false, ticket);

    compareDate = new Date();
    compareDate.setTime( compareDate.getTime() - 60 * 60 * 2 * 1000);
    ticket.pending_time = compareDate.toISOString();
    testTimeBeforeRelative('ticket.pending_time', 1, 'hour', true, ticket);

    // day
    ticket.pending_time = new Date().toISOString();
    testTimeBeforeRelative('ticket.pending_time', 1, 'day', false, ticket);

    compareDate = new Date();
    compareDate.setTime( compareDate.getTime() - 60 * 60 * 48 * 1000);
    ticket.pending_time = compareDate.toISOString();
    testTimeBeforeRelative('ticket.pending_time', 1, 'day', true, ticket);

    // year
    ticket.pending_time = new Date().toISOString();
    testTimeBeforeRelative('ticket.pending_time', 1, 'year', false, ticket);

    compareDate = new Date();
    compareDate.setTime( compareDate.getTime() - 60 * 60 * 365 * 2 * 1000);
    ticket.pending_time = compareDate.toISOString();
    testTimeBeforeRelative('ticket.pending_time', 1, 'year', true, ticket);

    // -------------------------
    // AFTER TIME
    // -------------------------

    // hour
    ticket.pending_time = new Date().toISOString();
    testTimeAfterRelative('ticket.pending_time', 1, 'hour', false, ticket);

    compareDate = new Date();
    compareDate.setTime( compareDate.getTime() + 60 * 60 * 2 * 1000);
    ticket.pending_time = compareDate.toISOString();
    testTimeAfterRelative('ticket.pending_time', 1, 'hour', true, ticket);

    // day
    ticket.pending_time = new Date().toISOString();
    testTimeAfterRelative('ticket.pending_time', 1, 'day', false, ticket);

    compareDate = new Date();
    compareDate.setTime( compareDate.getTime() + 60 * 60 * 48 * 1000);
    ticket.pending_time = compareDate.toISOString();
    testTimeAfterRelative('ticket.pending_time', 1, 'day', true, ticket);

    // year
    ticket.pending_time = new Date().toISOString();
    testTimeAfterRelative('ticket.pending_time', 1, 'year', false, ticket);

    compareDate = new Date();
    compareDate.setTime( compareDate.getTime() + 60 * 60 * 365 * 2 * 1000);
    ticket.pending_time = compareDate.toISOString();
    testTimeAfterRelative('ticket.pending_time', 1, 'year', true, ticket);


    // -------------------------
    // WITHIN LAST TIME
    // -------------------------

    // hour
    compareDate = new Date();
    compareDate.setTime( compareDate.getTime() - 60 * 60 * 0.5 * 1000);
    ticket.pending_time = compareDate.toISOString();
    testTimeWithinLastRelative('ticket.pending_time', 1, 'hour', true, ticket);

    compareDate = new Date();
    compareDate.setTime( compareDate.getTime() - 60 * 60 * 2 * 1000);
    ticket.pending_time = compareDate.toISOString();
    testTimeWithinLastRelative('ticket.pending_time', 1, 'hour', false, ticket);

    // -------------------------
    // WITHIN NEXT TIME
    // -------------------------

    // hour
    compareDate = new Date();
    compareDate.setTime( compareDate.getTime() + 60 * 60 * 0.5 * 1000);
    ticket.pending_time = compareDate.toISOString();
    testTimeWithinNextRelative('ticket.pending_time', 1, 'hour', true, ticket);

    compareDate = new Date();
    compareDate.setTime( compareDate.getTime() + 60 * 60 * 2 * 1000);
    ticket.pending_time = compareDate.toISOString();
    testTimeWithinNextRelative('ticket.pending_time', 1, 'hour', false, ticket);
  });

  test("ticket priority_id", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testIs('ticket.priority_id', ['2'], ticket, sessionData);
  });

  test("ticket escalation_at", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testTime('ticket.escalation_at', ticket.escalation_at, ticket);
  });

  test("ticket last_contact_agent_at", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testTime('ticket.last_contact_agent_at', ticket.last_contact_agent_at, ticket);
  });

  test("ticket last_contact_at", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testTime('ticket.last_contact_at', ticket.last_contact_at, ticket);
  });

  test("ticket last_contact_customer_at", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testTime('ticket.last_contact_customer_at', ticket.last_contact_customer_at, ticket);
  });

  test("ticket first_response_at", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testTime('ticket.first_response_at', ticket.first_response_at, ticket);
  });

  test("ticket close_at", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testTime('ticket.close_at', ticket.close_at, ticket);
  });

  test("ticket created_by_id", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    App.Session.set(6);

    testPreConditionUser('ticket.created_by_id', '6', ticket, sessionData);
  });

  test("ticket created_at", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testTime('ticket.created_at', ticket.created_at, ticket);
  });

  test("ticket updated_at", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testTime('ticket.updated_at', ticket.updated_at, ticket);
  });

  test("ticket updated_by_id", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    App.Session.set(6);

    testPreConditionUser('ticket.updated_by_id', '6', ticket, sessionData);
  });

  test("ticket tags", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testPreConditionTags('ticket.tags', ticket);
  });

  test("article from", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains('article.from', 'Master', ticket);
  });

  test("article to", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains('article.to', 'agent1', ticket);
  });

  test("article cc", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains('article.cc', 'agent1+cc', ticket);
  });

  test("article subject", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains('article.subject', 'asdf', ticket);
  });

  test("article type_id", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testIs('article.type_id', ['1'], ticket);
  });

  test("article sender_id", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testIs('article.sender_id', ['1'], ticket);
  });

  test("article internal", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testIs('article.internal', ['false'], ticket);
  });

  test("article created_by_id", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testPreConditionUser('article.created_by_id', '6', ticket, sessionData);
  });

  test("customer login", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains('customer.login', 'hc', ticket);
  });

  test("customer firstname", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains('customer.firstname', 'Harald', ticket);
  });

  test("customer lastname", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains('customer.lastname', 'Customer', ticket);
  });

  test("customer email", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains('customer.email', 'hc', ticket);
  });

  test("customer organization_id", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testPreConditionOrganization('customer.organization_id', '6', ticket, sessionData);
  });

  test("customer created_by_id", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testPreConditionUser('customer.created_by_id', '6', ticket, sessionData);
  });

  test("customer created_at", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testTime('customer.created_at', ticket.customer.created_at, ticket);
  });

  test("customer updated_by_id", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testPreConditionUser('customer.updated_by_id', '6', ticket, sessionData);
  });

  test("customer missing_field", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains('customer.missing_field', '', ticket);
  });

  test("customer web", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains('customer.web', 'cool', ticket);
  });

  test("organization name", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains('organization.name', 'gmbh', ticket);
  });

  test("organization shared", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testIs('organization.shared', true, ticket);
  });

  test("organization created_by_id", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testPreConditionUser('organization.created_by_id', 6, ticket);
  });

  test("organization updated_by_id", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testPreConditionUser('organization.updated_by_id', 6, ticket);
  });

  test("organization created_at", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testTime('organization.created_at', ticket.organization.created_at, ticket);
  });

  test("organization updated_at", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testTime('organization.updated_at', ticket.organization.updated_at, ticket);
  });

  test("organization domain_assignment", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testIs('organization.domain_assignment', false, ticket);
  });

  test("organization domain", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains('organization.domain', 'cool', ticket);
  });

  test("ticket mention user_id", function() {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testPreConditionUser('ticket.mention_user_ids', '6', ticket, sessionData);
  });

}
