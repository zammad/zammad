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
        "from": "Test Admin Agent",
        "to": "agent1@example.com",
        "cc": "agent1+cc@example.com",
        "body": "asdfasdfasdf<br><br><div data-signature=\"true\" data-signature-id=\"1\">  Test Admin Agent<br><br>--<br> Super Support - Waterford Business Park<br> 5201 Blue Lagoon Drive - 8th Floor &amp; 9th Floor - Miami, 33126 USA<br> Email: hot@example.com - Web: http://www.example.com/<br>--</div>",
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
    "organization_ids": [7,8],
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

  var testContains = function (assert, key, value, ticket) {
    setting = {
      "condition": {
        [key]: {
          "operator": "contains",
          "value": value
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    assert.equal(result, true, result);

    setting = {
      "condition": {
        [key]: {
          "operator": "contains not",
          "value": value
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    assert.equal(result, false, result);
  };

  var testIs = function (assert, key, value, ticket) {
    setting = {
      "condition": {
        [key]: {
          "operator": "is",
          "value": value
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    assert.equal(result, true, result);

    setting = {
      "condition": {
        [key]: {
          "operator": "is not",
          "value": value
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    assert.equal(result, false, result);
  };

  var testIsNull = function (assert, key, value, ticket) {
    setting = {
      "condition": {
        [key]: {
          "operator": "is",
          "value": null
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    assert.equal(result, false, result);

    setting = {
      "condition": {
        [key]: {
          "operator": "is not",
          "value": null
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    assert.equal(result, true, result);
  };

  var testIsUndefined = function (assert, key, value, ticket) {
    setting = {
      "condition": {
        [key]: {
          "operator": "is",
          "value": undefined
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    assert.equal(result, false, result);

    setting = {
      "condition": {
        [key]: {
          "operator": "is not",
          "value": undefined
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    assert.equal(result, true, result);
  };

  var testSelectorUndefined = function (assert, ticket) {
    result = App.Ticket.selector(ticket, undefined);
    assert.equal(result, true, result);
  };

  var testSelectorNull = function (assert, ticket) {
    result = App.Ticket.selector(ticket, null);
    assert.equal(result, true, result);
  };


  var testPreConditionUser = function (assert, key, specificValue, ticket, session) {
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
    assert.equal(result, true, result);

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
    assert.equal(result, false, result);

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
    assert.equal(result, true, result);

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
    assert.equal(result, false, result);

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
    assert.equal(result, false, result);

    setting = {
      "condition": {
        [key]: {
          "operator": "is",
          "pre_condition": "not_set",
        }
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    assert.equal(result, false, result);

    setting = {
      "condition": {
        [key]: {
          "operator": "is not",
          "pre_condition": "not_set",
        }
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    assert.equal(result, true, result);
  };

  var testPreConditionOrganization = function (assert, key, specificValue, ticket, session) {
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
    assert.equal(result, true, result);

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
    assert.equal(result, false, result);

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
    assert.equal(result, true, result);

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
    assert.equal(result, false, result);

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
    assert.equal(result, false, result);

    setting = {
      "condition": {
        [key]: {
          "operator": "is",
          "pre_condition": "not_set",
        }
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    assert.equal(result, false, result);

    setting = {
      "condition": {
        [key]: {
          "operator": "is not",
          "pre_condition": "not_set",
        }
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    assert.equal(result, true, result);
  };

  var testPreConditionTags = function (assert, key, ticket) {
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
    assert.equal(result, true, result);

    setting = {
      "condition": {
        "ticket.tags": {
          "operator": "contains one",
          "value": "tag aa",
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    assert.equal(result, false, result);

    setting = {
      "condition": {
        "ticket.tags": {
          "operator": "contains all",
          "value": "tag a",
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    assert.equal(result, true, result);

    setting = {
      "condition": {
        "ticket.tags": {
          "operator": "contains all",
          "value": "tag a, not existing",
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    assert.equal(result, false, result);

    setting = {
      "condition": {
        "ticket.tags": {
          "operator": "contains all not",
          "value": "tag a",
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    assert.equal(result, false, result);

    setting = {
      "condition": {
        "ticket.tags": {
          "operator": "contains all not",
          "value": "tag a, tag b",
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    assert.equal(result, false, result);

    setting = {
      "condition": {
        "ticket.tags": {
          "operator": "contains all not",
          "value": "tag a, tag b, tag c",
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    assert.equal(result, false, result);

    setting = {
      "condition": {
        "ticket.tags": {
          "operator": "contains all not",
          "value": "tag c, tag d",
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    assert.equal(result, true, result);

    setting = {
      "condition": {
        "ticket.tags": {
          "operator": "contains one not",
          "value": "tag a",
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    assert.equal(result, true, result);

    setting = {
      "condition": {
        "ticket.tags": {
          "operator": "contains one not",
          "value": "tag a, tag b",
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    assert.equal(result, false, result);

    setting = {
      "condition": {
        "ticket.tags": {
          "operator": "contains one not",
          "value": "tag a, tag c",
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    assert.equal(result, true, result);

    setting = {
      "condition": {
        "ticket.tags": {
          "operator": "contains one not",
          "value": "tag c",
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    assert.equal(result, true, result);

  };

  var testTime = function (assert, key, value, ticket) {
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
    assert.equal(result, true, result);

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
    assert.equal(result, false, result);

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
    assert.equal(result, false, result);

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
    assert.equal(result, true, result);

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
    assert.equal(result, true, result);
  };

  var testTimeToday = function (assert, key, expectedResult, ticket) {
    setting = {
      "condition": {
        [key]: {
          "operator": "today",
        },
      }
    };
    result = App.Ticket.selector(ticket, setting['condition']);
    assert.equal(result, expectedResult, result);
  };

  var testTimeBeforeRelative = function (assert, key, value, range, expectedResult, ticket) {
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
    assert.equal(result, expectedResult, result);
  };

  var testTimeAfterRelative = function (assert, key, value, range, expectedResult, ticket) {
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
    assert.equal(result, expectedResult, result);
  };

  var testTimeWithinNextRelative = function (assert, key, value, range, expectedResult, ticket) {
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
    assert.equal(result, expectedResult, result);
  };

  var testTimeWithinLastRelative = function (assert, key, value, range, expectedResult, ticket) {
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
    assert.equal(result, expectedResult, result);
  };

  /*
   * ------------------------------------------------------------------------
   * Field tests
   * ------------------------------------------------------------------------
   */

  QUnit.test("selector is undefined", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testSelectorUndefined(assert, ticket);
  });

  QUnit.test("selector is null", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testSelectorNull(assert, ticket);
  });

  QUnit.test("ticket number", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains(assert, 'ticket.number', '72', ticket);
  });

  QUnit.test("ticket title", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains(assert, 'ticket.title', 'asd', ticket);
  });

  QUnit.test("ticket customer_id", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    App.Session.set(6);

    testPreConditionUser(assert, 'ticket.customer_id', '6', ticket, sessionData);
  });

  QUnit.test("ticket organization_id", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testPreConditionUser(assert, 'ticket.organization_id', '6', ticket, sessionData);
  });

  QUnit.test("ticket group_id", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testIs(assert, 'ticket.group_id', ['1'], ticket, sessionData);
  });

  QUnit.test("ticket owner_id", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    App.Session.set(6);

    testPreConditionUser(assert, 'ticket.owner_id', '6', ticket, sessionData);
  });

  QUnit.test("ticket state_id", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testIs(assert, 'ticket.state_id', ['4'], ticket, sessionData);
  });

  QUnit.test("ticket state_id -> null", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testIsNull(assert, 'ticket.state_id', null, ticket, sessionData);
  });

  QUnit.test("ticket state_id -> undefined", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testIsNull(assert, 'ticket.state_id', undefined, ticket, sessionData);
  });

  QUnit.test("ticket pending_time", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testTime(assert, 'ticket.pending_time', ticket.pending_time, ticket);

    // -------------------------
    // TODAY
    // -------------------------

    ticket.pending_time = new Date().toISOString();
    testTimeToday(assert, 'ticket.pending_time', true, ticket);

    compareDate = new Date();
    compareDate.setTime( compareDate.getTime() - 60 * 60 * 48 * 1000);
    ticket.pending_time = compareDate.toISOString();
    testTimeToday(assert, 'ticket.pending_time', false, ticket);

    compareDate = new Date();
    compareDate.setTime( compareDate.getTime() + 60 * 60 * 48 * 1000);
    ticket.pending_time = compareDate.toISOString();
    testTimeToday(assert, 'ticket.pending_time', false, ticket);

    // -------------------------
    // BEFORE TIME
    // -------------------------

    // hour
    ticket.pending_time = new Date().toISOString();
    testTimeBeforeRelative(assert, 'ticket.pending_time', 1, 'hour', false, ticket);

    compareDate = new Date();
    compareDate.setTime( compareDate.getTime() - 60 * 60 * 2 * 1000);
    ticket.pending_time = compareDate.toISOString();
    testTimeBeforeRelative(assert, 'ticket.pending_time', 1, 'hour', true, ticket);

    // day
    ticket.pending_time = new Date().toISOString();
    testTimeBeforeRelative(assert, 'ticket.pending_time', 1, 'day', false, ticket);

    compareDate = new Date();
    compareDate.setTime( compareDate.getTime() - 60 * 60 * 48 * 1000);
    ticket.pending_time = compareDate.toISOString();
    testTimeBeforeRelative(assert, 'ticket.pending_time', 1, 'day', true, ticket);

    // year
    ticket.pending_time = new Date().toISOString();
    testTimeBeforeRelative(assert, 'ticket.pending_time', 1, 'year', false, ticket);

    compareDate = new Date();
    compareDate.setTime( compareDate.getTime() - 60 * 60 * 365 * 2 * 1000);
    ticket.pending_time = compareDate.toISOString();
    testTimeBeforeRelative(assert, 'ticket.pending_time', 1, 'year', true, ticket);

    // -------------------------
    // AFTER TIME
    // -------------------------

    // hour
    ticket.pending_time = new Date().toISOString();
    testTimeAfterRelative(assert, 'ticket.pending_time', 1, 'hour', false, ticket);

    compareDate = new Date();
    compareDate.setTime( compareDate.getTime() + 60 * 60 * 2 * 1000);
    ticket.pending_time = compareDate.toISOString();
    testTimeAfterRelative(assert, 'ticket.pending_time', 1, 'hour', true, ticket);

    // day
    ticket.pending_time = new Date().toISOString();
    testTimeAfterRelative(assert, 'ticket.pending_time', 1, 'day', false, ticket);

    compareDate = new Date();
    compareDate.setTime( compareDate.getTime() + 60 * 60 * 48 * 1000);
    ticket.pending_time = compareDate.toISOString();
    testTimeAfterRelative(assert, 'ticket.pending_time', 1, 'day', true, ticket);

    // year
    ticket.pending_time = new Date().toISOString();
    testTimeAfterRelative(assert, 'ticket.pending_time', 1, 'year', false, ticket);

    compareDate = new Date();
    compareDate.setTime( compareDate.getTime() + 60 * 60 * 365 * 2 * 1000);
    ticket.pending_time = compareDate.toISOString();
    testTimeAfterRelative(assert, 'ticket.pending_time', 1, 'year', true, ticket);


    // -------------------------
    // WITHIN LAST TIME
    // -------------------------

    // hour
    compareDate = new Date();
    compareDate.setTime( compareDate.getTime() - 60 * 60 * 0.5 * 1000);
    ticket.pending_time = compareDate.toISOString();
    testTimeWithinLastRelative(assert, 'ticket.pending_time', 1, 'hour', true, ticket);

    compareDate = new Date();
    compareDate.setTime( compareDate.getTime() - 60 * 60 * 2 * 1000);
    ticket.pending_time = compareDate.toISOString();
    testTimeWithinLastRelative(assert, 'ticket.pending_time', 1, 'hour', false, ticket);

    // -------------------------
    // WITHIN NEXT TIME
    // -------------------------

    // hour
    compareDate = new Date();
    compareDate.setTime( compareDate.getTime() + 60 * 60 * 0.5 * 1000);
    ticket.pending_time = compareDate.toISOString();
    testTimeWithinNextRelative(assert, 'ticket.pending_time', 1, 'hour', true, ticket);

    compareDate = new Date();
    compareDate.setTime( compareDate.getTime() + 60 * 60 * 2 * 1000);
    ticket.pending_time = compareDate.toISOString();
    testTimeWithinNextRelative(assert, 'ticket.pending_time', 1, 'hour', false, ticket);
  });

  QUnit.test("ticket priority_id", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testIs(assert, 'ticket.priority_id', ['2'], ticket, sessionData);
  });

  QUnit.test("ticket escalation_at", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testTime(assert, 'ticket.escalation_at', ticket.escalation_at, ticket);
  });

  QUnit.test("ticket last_contact_agent_at", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testTime(assert, 'ticket.last_contact_agent_at', ticket.last_contact_agent_at, ticket);
  });

  QUnit.test("ticket last_contact_at", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testTime(assert, 'ticket.last_contact_at', ticket.last_contact_at, ticket);
  });

  QUnit.test("ticket last_contact_customer_at", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testTime(assert, 'ticket.last_contact_customer_at', ticket.last_contact_customer_at, ticket);
  });

  QUnit.test("ticket first_response_at", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testTime(assert, 'ticket.first_response_at', ticket.first_response_at, ticket);
  });

  QUnit.test("ticket close_at", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testTime(assert, 'ticket.close_at', ticket.close_at, ticket);
  });

  QUnit.test("ticket created_by_id", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    App.Session.set(6);

    testPreConditionUser(assert, 'ticket.created_by_id', '6', ticket, sessionData);
  });

  QUnit.test("ticket created_at", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testTime(assert, 'ticket.created_at', ticket.created_at, ticket);
  });

  QUnit.test("ticket updated_at", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testTime(assert, 'ticket.updated_at', ticket.updated_at, ticket);
  });

  QUnit.test("ticket updated_by_id", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    App.Session.set(6);

    testPreConditionUser(assert, 'ticket.updated_by_id', '6', ticket, sessionData);
  });

  QUnit.test("ticket tags", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testPreConditionTags(assert, 'ticket.tags', ticket);
  });

  QUnit.test("article from", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains(assert, 'article.from', 'Admin', ticket);
  });

  QUnit.test("article to", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains(assert, 'article.to', 'agent1', ticket);
  });

  QUnit.test("article cc", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains(assert, 'article.cc', 'agent1+cc', ticket);
  });

  QUnit.test("article subject", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains(assert, 'article.subject', 'asdf', ticket);
  });

  QUnit.test("article type_id", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testIs(assert, 'article.type_id', ['1'], ticket);
  });

  QUnit.test("article sender_id", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testIs(assert, 'article.sender_id', ['1'], ticket);
  });

  QUnit.test("article internal", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testIs(assert, 'article.internal', ['false'], ticket);
  });

  QUnit.test("article created_by_id", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testPreConditionUser(assert, 'article.created_by_id', '6', ticket, sessionData);
  });

  QUnit.test("customer login", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains(assert, 'customer.login', 'hc', ticket);
  });

  QUnit.test("customer firstname", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains(assert, 'customer.firstname', 'Harald', ticket);
  });

  QUnit.test("customer lastname", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains(assert, 'customer.lastname', 'Customer', ticket);
  });

  QUnit.test("customer email", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains(assert, 'customer.email', 'hc', ticket);
  });

  QUnit.test("customer organization_id", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testPreConditionOrganization(assert, 'customer.organization_id', '6', ticket, sessionData);
  });

  QUnit.test("customer created_by_id", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testPreConditionUser(assert, 'customer.created_by_id', '6', ticket, sessionData);
  });

  QUnit.test("customer created_at", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testTime(assert, 'customer.created_at', ticket.customer.created_at, ticket);
  });

  QUnit.test("customer updated_by_id", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testPreConditionUser(assert, 'customer.updated_by_id', '6', ticket, sessionData);
  });

  QUnit.test("customer missing_field", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains(assert, 'customer.missing_field', '', ticket);
  });

  QUnit.test("customer web", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains(assert, 'customer.web', 'cool', ticket);
  });

  QUnit.test("organization name", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains(assert, 'organization.name', 'gmbh', ticket);
  });

  QUnit.test("organization shared", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testIs(assert, 'organization.shared', true, ticket);
  });

  QUnit.test("organization created_by_id", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testPreConditionUser(assert, 'organization.created_by_id', 6, ticket);
  });

  QUnit.test("organization updated_by_id", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testPreConditionUser(assert, 'organization.updated_by_id', 6, ticket);
  });

  QUnit.test("organization created_at", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testTime(assert, 'organization.created_at', ticket.organization.created_at, ticket);
  });

  QUnit.test("organization updated_at", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testTime(assert, 'organization.updated_at', ticket.organization.updated_at, ticket);
  });

  QUnit.test("organization domain_assignment", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testIs(assert, 'organization.domain_assignment', false, ticket);
  });

  QUnit.test("organization domain", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testContains(assert, 'organization.domain', 'cool', ticket);
  });

  QUnit.test("ticket mention user_id", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);

    testPreConditionUser(assert, 'ticket.mention_user_ids', '6', ticket, sessionData);
  });

  QUnit.test("test multi organization support for current_user.organization_id", assert => {
    ticket = new App.Ticket();
    ticket.load(ticketData);
    testPreConditionOrganization(assert, 'ticket.organization_id', '6', ticket, sessionData);

    ticket.organization_id = 7;
    testPreConditionOrganization(assert, 'ticket.organization_id', '7', ticket, sessionData);
  });
}
