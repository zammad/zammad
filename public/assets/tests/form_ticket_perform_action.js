// ticket_perform_action
test( "ticket_perform_action check", function() {

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
        recipient: 'ticket_owner',
        subject: 'some subject'
      },
      'ticket.state_id': {
        value: '3'
      }
    }
  }
  deepEqual(params, test_params, 'form param check')

});
