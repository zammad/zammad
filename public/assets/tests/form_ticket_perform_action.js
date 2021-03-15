// ticket_perform_action
test( "ticket_perform_action check", function(assert) {

  App.TicketPriority.refresh([
    {
      id:         2,
      name:       '2 normal',
      active:     false,
    },
    {
      id:         1,
      name:       '1 low',
      active:     true,
    },
  ])

  App.TicketState.refresh([
    {
      id:         1,
      name:       'new',
      active:     true,
    },
    {
      id:         2,
      name:       'open',
      active:     true,
    },
    {
      id:         3,
      name:       'closed',
      active:     false,
    },
  ])

  $('#forms').append('<hr><h1>ticket_perform_action check</h1><form id="form1"></form>')
  var el = $('#form1')
  var defaults = {
    ticket_perform_action1: {
      'ticket.state_id': {
        value: '2'
      }
    },
    ticket_perform_action2: {
      'ticket.state_id': {
        value: '1'
      },
      'ticket.priority_id': {
        value: '2'
      },
      'notification.email': {
        body: 'some body',
        internal: 'false',
        recipient: ['ticket_owner', 'ticket_customer'],
        subject: 'some subject'
      },
    },
    ticket_perform_action3: {
      'ticket.state_id': {
        value: '3'
      },

    }
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        {
          name:    'ticket_perform_action1',
          display: 'TicketPerformAction1',
          tag:     'ticket_perform_action',
          null:    true,
        },
        {
          name:         'ticket_perform_action2',
          display:      'TicketPerformAction2',
          tag:          'ticket_perform_action',
          null:         false,
          notification: true,
        },
        {
          name:         'ticket_perform_action3',
          display:      'TicketPerformAction3',
          tag:          'ticket_perform_action',
          null:         true,
          notification: true,
        },
      ]
    },
    params: defaults,
    autofocus: true
  })

  var params = App.ControllerForm.params(el)
  var test_params = {
    ticket_perform_action1: {
      'ticket.state_id': {
        value: '2'
      }
    },
    ticket_perform_action2: {
      'notification.email': {
        body: 'some body',
        internal: 'false',
        recipient: ['ticket_owner', 'ticket_customer'],
        subject: 'some subject'
      },
      'ticket.priority_id': {
        value: '2'
      },
      'ticket.state_id': {
        value: '1'
      },
    },
    ticket_perform_action3: {
      'ticket.state_id': {
        value: '3'
      }
    }
  }
  deepEqual(params, test_params, 'form param check')

  // add email notification
  $('[data-attribute-name="ticket_perform_action3"] .js-add').click()
  $('[data-attribute-name="ticket_perform_action3"] .js-attributeSelector .form-control').last().val('notification.email').trigger('change')
  $('[data-attribute-name="ticket_perform_action3"] .js-setNotification [name="ticket_perform_action3::notification.email::subject"]').val('some subject').trigger('change')
  $('[data-attribute-name="ticket_perform_action3"] .js-setNotification [data-name="ticket_perform_action3::notification.email::body"]').html('some body').trigger('change')
  $('[data-attribute-name="ticket_perform_action3"] .js-setNotification .js-recipient .js-option[data-value="ticket_owner"]').click()

  params = App.ControllerForm.params(el)
  test_params = {
    ticket_perform_action1: {
      'ticket.state_id': {
        value: '2'
      }
    },
    ticket_perform_action2: {
      'notification.email': {
        body: 'some body',
        internal: 'false',
        recipient: ['ticket_owner', 'ticket_customer'],
        subject: 'some subject'
      },
      'ticket.priority_id': {
        value: '2'
      },
      'ticket.state_id': {
        value: '1'
      },
    },
    ticket_perform_action3: {
      'notification.email': {
        body: 'some body',
        internal: 'false',
        recipient: 'ticket_owner',
        subject: 'some subject'
      },
      'ticket.state_id': {
        value: '3'
      }
    }
  }
  deepEqual(params, test_params, 'form param check')

  // remove recipient
  $('[data-attribute-name="ticket_perform_action2"] .js-setNotification .js-recipient .js-remove.js-option[data-value="ticket_owner"]').click()

  params = App.ControllerForm.params(el)
  test_params = {
    ticket_perform_action1: {
      'ticket.state_id': {
        value: '2'
      }
    },
    ticket_perform_action2: {
      'notification.email': {
        body: 'some body',
        internal: 'false',
        recipient: 'ticket_customer',
        subject: 'some subject'
      },
      'ticket.priority_id': {
        value: '2'
      },
      'ticket.state_id': {
        value: '1'
      },
    },
    ticket_perform_action3: {
      'notification.email': {
        body: 'some body',
        internal: 'false',
        recipient: 'ticket_owner',
        subject: 'some subject'
      },
      'ticket.state_id': {
        value: '3'
      }
    }
  }
  deepEqual(params, test_params, 'form param check')

  // set notification to internal
  $('[data-attribute-name="ticket_perform_action2"] .js-internal select').val('true').trigger('change')

  params = App.ControllerForm.params(el)
  test_params = {
    ticket_perform_action1: {
      'ticket.state_id': {
        value: '2'
      }
    },
    ticket_perform_action2: {
      'notification.email': {
        body: 'some body',
        internal: 'true',
        recipient: 'ticket_customer',
        subject: 'some subject'
      },
      'ticket.priority_id': {
        value: '2'
      },
      'ticket.state_id': {
        value: '1'
      },
    },
    ticket_perform_action3: {
      'notification.email': {
        body: 'some body',
        internal: 'false',
        recipient: 'ticket_owner',
        subject: 'some subject'
      },
      'ticket.state_id': {
        value: '3'
      }
    }
  }
  deepEqual(params, test_params, 'form param check')

  // add pending time
  $('[data-attribute-name="ticket_perform_action3"] .js-add').last().click()

  var row = $('[data-attribute-name="ticket_perform_action3"] .js-filterElement').last()

  var date_string = '2010-07-15T12:00:00.000Z'
  var date_parsed = new Date(date_string) // make sure it works regardless of browser locale

  row.find('.js-attributeSelector .form-control').last().val('ticket.pending_time').trigger('change')
  row.find('.js-datepicker').val(date_parsed.toLocaleDateString()).trigger('blur')
  row.find('.js-datepicker').datepicker('setDate')
  row.find('.js-timepicker').val(date_parsed.getHours() + ':' + date_parsed.getMinutes()).trigger('blur')

  test_params = {
    ticket_perform_action1: {
      'ticket.state_id': {
        value: '2'
      }
    },
    ticket_perform_action2: {
      'notification.email': {
        body: 'some body',
        internal: 'true',
        recipient: 'ticket_customer',
        subject: 'some subject'
      },
      'ticket.priority_id': {
        value: '2'
      },
      'ticket.state_id': {
        value: '1'
      },
    },
    ticket_perform_action3: {
      'notification.email': {
        body: 'some body',
        internal: 'false',
        recipient: 'ticket_owner',
        subject: 'some subject'
      },
      'ticket.pending_time': {
        operator: 'static',
        value: date_string
      },
      'ticket.state_id': {
        value: '3'
      }
    }
  }

  var done = assert.async()

  setTimeout(function(){
    params = App.ControllerForm.params(el)
    deepEqual(params, test_params, 'form param check')
    done()
  }, 0);

  // switch pending time to relative

  row.find('.js-operator select').val('relative').trigger('change')
  row.find('.js-range').val('day').trigger('change')
  row.find('.js-value').val('10').trigger('change')

  params = App.ControllerForm.params(el)
  test_params = {
    ticket_perform_action1: {
      'ticket.state_id': {
        value: '2'
      }
    },
    ticket_perform_action2: {
      'notification.email': {
        body: 'some body',
        internal: 'true',
        recipient: 'ticket_customer',
        subject: 'some subject'
      },
      'ticket.priority_id': {
        value: '2'
      },
      'ticket.state_id': {
        value: '1'
      },
    },
    ticket_perform_action3: {
      'notification.email': {
        body: 'some body',
        internal: 'false',
        recipient: 'ticket_owner',
        subject: 'some subject'
      },
      'ticket.pending_time': {
        operator: 'relative',
        range: 'day',
        value: '10'
      },
      'ticket.state_id': {
        value: '3'
      }
    }
  }
  deepEqual(params, test_params, 'form param check')
});

// Test for backwards compatibility after issue is fixed https://github.com/zammad/zammad/issues/2782
test( "ticket_perform_action backwards check after issue #2782", function() {
  $('#forms').append('<hr><h1>ticket_perform_action check</h1><form id="form2"></form>')

  var el = $('#form2')

  var defaults = {
    ticket_perform_action5: {
      'notification.email': {
        body: 'some body',
        recipient: ['ticket_owner', 'ticket_customer'],
        subject: 'some subject'
      },
    },
  }

  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        {
          name:    'ticket_perform_action5',
          display: 'TicketPerformAction5',
          tag:     'ticket_perform_action',
          null:    true,
        },
      ]
    },
    params: defaults,
    autofocus: true
  })

  var params = App.ControllerForm.params(el)
  var test_params = {
    ticket_perform_action5: {
      'notification.email': {
        body: 'some body',
        internal: 'false',
        recipient: ['ticket_owner', 'ticket_customer'],
        subject: 'some subject'
      },
    }
  }

  deepEqual(params, test_params, 'form param check')
});

test( "ticket_perform_action rows manipulation", function() {
  App.TicketPriority.refresh([
    {
      id:         2,
      name:       '2 normal',
      active:     false,
    },
    {
      id:         1,
      name:       '1 low',
      active:     true,
    },
  ])

  App.TicketState.refresh([
    {
      id:         1,
      name:       'new',
      active:     true,
    },
    {
      id:         2,
      name:       'open',
      active:     true,
    },
    {
      id:         3,
      name:       'closed',
      active:     false,
    },
  ])

  $('#forms').append('<hr><h1>ticket_perform_action rows manipulation</h1><form id="form99"></form>')
  var el = $('#form99')
  var defaults = {
    ticket_perform_action1: {
      'ticket.state_id': {
        value: '2'
      }
    }
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        {
          name:    'ticket_perform_action99',
          display: 'TicketPerformAction99',
          tag:     'ticket_perform_action',
          null:    true,
        },
      ]
    },
    params: defaults,
    autofocus: true
  })

  equal(true, true)

  var selector = '[data-attribute-name="ticket_perform_action99"] '

  $(selector + '.js-remove').click()

  equal($(selector + '.js-filterElement').length, 1, 'prevents removing single initial row')

  $(selector + '.js-add').click()

  equal($(selector + '.js-filterElement').length, 2, 'adds 2nd row')

  $(selector + ' .js-remove:last').click()

  equal($(selector + '.js-filterElement').length, 1, 'removes 2nd row')

  $(selector + '.js-remove:last').click()

  equal($(selector + ' .js-filterElement').length, 1, 'prevents removing last row')
});

// Test for backwards compatibility after PR https://github.com/zammad/zammad/pull/2862
test( "ticket_perform_action backwards check after PR#2862", function() {
  $('#forms').append('<hr><h1>ticket_perform_action check</h1><form id="form3"></form>')

  var el = $('#form3')

  var defaults = {
    ticket_perform_action4: {
      'ticket.pending_time': {
        value: '2010-07-15T05:00:00.000Z'
      }
    }
  }

  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        {
          name:    'ticket_perform_action4',
          display: 'TicketPerformAction4',
          tag:     'ticket_perform_action',
          null:    true,
        },
      ]
    },
    params: defaults,
    autofocus: true
  })

  var params = App.ControllerForm.params(el)
  var test_params = {
    ticket_perform_action4: {
      'ticket.pending_time': {
        operator: 'static',
        value: '2010-07-15T05:00:00.000Z'
      }
    }
  }

  deepEqual(params, test_params, 'form param check')
});

test( "ticket_perform_action orphan time fields", function() {
  $('#forms').append('<hr><h1>ticket_perform_action orphan time fields</h1><form id="form4"></form>')

  var el = $('#form4')

  var defaults = {
    ticket_perform_action4: {
      'ticket.pending_time': {
        operator: 'relative',
        value: '1'
      }
    }
  }

  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        {
          name:    'ticket_perform_action4',
          display: 'TicketPerformAction4',
          tag:     'ticket_perform_action',
          null:    true,
        },
      ]
    },
    params: defaults,
    autofocus: true
  })

  // change to another attribute
  el.find('select:first').val('ticket.tags').trigger('change')

  equal(el.find('.js-valueRangeSelector').length, 0)
});

test( "ticket_perform_action check possible owner selection", function() {
  $('#forms').append('<hr><h1>ticket_perform_action check possible owner selection</h1><form id="form5"></form>')

  var el = $('#form5')

  var defaults = {
    ticket_perform_action5: {
      'ticket.owner_id': {
        pre_condition: 'not_set',
      }
    }
  }

  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        {
          name:    'ticket_perform_action5',
          display: 'TicketPerformAction5',
          tag:     'ticket_perform_action',
          null:    true,
        },
      ]
    },
    params: defaults,
    autofocus: true
  })

  var params = App.ControllerForm.params(el)
  var test_params = {
    ticket_perform_action5: {
      'ticket.owner_id': {
        pre_condition: 'not_set',
        value: '',
        value_completion: ''
      }
    }
  }

  deepEqual(params, test_params, 'form param check')

  el.find('[name="ticket_perform_action5::ticket.owner_id::pre_condition"]').val('specific').trigger('change')

  params = App.ControllerForm.params(el)
  test_params = {
    ticket_perform_action5: {
      'ticket.owner_id': {
        pre_condition: 'specific',
        value: '',
        value_completion: ''
      }
    }
  }

  deepEqual(params, test_params, 'form param check')

});

test( "ticket_perform_action check when there's no available webhook", function() {

  $('#forms').append('<hr><h1>ticket_perform_action check when there\'s no available webhook</h1><form id="form6"></form>')
  var el = $('#form6')
  var defaults = {
    ticket_perform_action6: {
      'notification.webhook': {
        value: undefined
      }
    }
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        {
          name:         'ticket_perform_action6',
          display:      'TicketPerformAction6',
          tag:          'ticket_perform_action',
          null:         true,
          notification: true,
        },
      ]
    },
    params: defaults,
    autofocus: true
  })

  var params = App.ControllerForm.params(el)
  deepEqual(params, {}, 'form param check')

  var testNoticeMessage = 'No available webhook, please create a new one or activate an existing one at "Manage > Webhook"'
  var noticeMessage = el.find('.controls.js-webhooks div').text()
  equal(noticeMessage, testNoticeMessage, 'form shows message when webhook is not available')
});

test( "ticket_perform_action check when there's an available webhook", function() {

  $('#forms').append('<hr><h1>ticket_perform_action check when there\'s an available webhook</h1><form id="form7"></form>')
  var el = $('#form7')
  var defaults = {
    ticket_perform_action7: {
      'notification.webhook': {
        webhook_id: 'c-1'
      }
    }
  }

  App.Webhook.refresh([
    {
      name:     'Webhook test',
      endpoint: 'https://target.example.com/webhook',
      active:   true,
      id:       'c-1'
    }
  ], { clear: true })

  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        {
          name:         'ticket_perform_action7',
          display:      'TicketPerformAction7',
          tag:          'ticket_perform_action',
          null:         true,
          notification: true,
        },
      ]
    },
    params: defaults,
    autofocus: true
  })

  var params = App.ControllerForm.params(el)
  var test_params = {
    'ticket_perform_action7': {
      'notification.webhook': {
        'webhook_id': 'c-1'
      }
    }
  }
  deepEqual(params, test_params, 'form param check')

  var testNoticeMessage = 'No available webhook, please create a new one or activate an existing one at "Manage > Webhook"'
  var noticeMessage = el.find('.controls.js-webhooks').text()
  notEqual(noticeMessage, testNoticeMessage, 'form does not show notice message when webhook is available')

  var noticeMessage = el.find('.controls.js-webhooks select option').eq(1).text()
  equal(noticeMessage, 'Webhook test (https://target.example.com/webhook)', 'form shows available webhook when webhook is available')
});
