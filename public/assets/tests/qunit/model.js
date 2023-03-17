window.onload = function() {

// TicketPriority search
QUnit.test( "TicketPriority search tests", assert => {

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
      created_at: '2014-06-10T10:17:33.000Z',
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
  priorities = App.TicketPriority.search({sortBy:'created_at', order: 'ASC'})
  assert.equal('2 normal', priorities[0].name, 'check 1 entry')
  assert.equal('3 high', priorities[1].name, 'check 2 entry')
  assert.equal('4 very high', priorities[2].name, 'check 3 entry')
  assert.equal('1 low', priorities[3].name, 'check 4 entry')
  assert.equal(undefined, priorities[4], 'check 5 entry')

  priorities = App.TicketPriority.search({sortBy:'created_at', order: 'DESC'})
  assert.equal('1 low', priorities[0].name, 'check 4 entry')
  assert.equal('4 very high', priorities[1].name, 'check 3 entry')
  assert.equal('3 high', priorities[2].name, 'check 2 entry')
  assert.equal('2 normal', priorities[3].name, 'check 1 entry')
  assert.equal(undefined, priorities[4], 'check 5 entry')

  priorities = App.TicketPriority.search({filter: { name: '4 very high' }, sortBy:'name', order: 'ASC'})
  assert.equal('4 very high', priorities[0].name, 'check name filter')
  assert.equal(undefined, priorities[1], 'check name filter is undefined')
});

// PublicLink search
QUnit.test( "PublicLink search tests", assert => {

  App.PublicLink.refresh( [
    {
      id:           1,
      link:         'https://zammad.org',
      title:        'Zammad Community',
      description:  'Zammad is a very cool application',
      screen:       ['login'],
      prio:         1,
    },
    {
      id:           2,
      link:         'https://zammad.com',
      title:        'Zammad <3',
      description:  'Zammad is a very cool application',
      screen:       ['login', 'password_reset', 'signup'],
      prio:         2,
    },
    {
      id:           3,
      link:         'https://zammad.biz',
      title:        'Zammad BIZ',
      description:  'Zammad is a very cool application',
      screen:       ['login', 'signup'],
      prio:         3,
    },
  ] )

  public_links = App.PublicLink.search({filter: { screen: ['login'] }, sortBy:'prio', order: 'ASC'})
  assert.equal('Zammad Community', public_links[0].title, 'check link 1 ASC')
  assert.equal('Zammad <3', public_links[1].title, 'check link 2 ASC')
  assert.equal('Zammad BIZ', public_links[2].title, 'check link 3 ASC')

  public_links = App.PublicLink.search({filter: { screen: ['login'] }, sortBy:'prio', order: 'DESC'})
  assert.equal('Zammad BIZ', public_links[0].title, 'check link 1 DESC')
  assert.equal('Zammad <3', public_links[1].title, 'check link 2 DESC')
  assert.equal('Zammad Community', public_links[2].title, 'check link 3 DESC')

  public_links = App.PublicLink.search({filter: { screen: ['signup', 'password_reset'] }, sortBy:'prio', order: 'ASC'})
  assert.equal('Zammad <3', public_links[0].title, 'check signup link 1 ASC')
  assert.equal('Zammad BIZ', public_links[1].title, 'check signup link 2 ASC')
  assert.equal(undefined, public_links[2], 'check signup links')

  public_links = App.PublicLink.search({filter: { screen: ['password_reset'] }, sortBy:'prio', order: 'ASC'})
  assert.equal('Zammad <3', public_links[0].title, 'check password_reset link 1 ASC')
  assert.equal(undefined, public_links[1], 'check password_reset links')
});

// model
QUnit.test( "model loadAssets tests - 1", assert => {
  window.refreshCounter1 = 0
  var callback1 = function(state, triggerType) {
    window.refreshCounter1 = window.refreshCounter1 + 1
    assert.equal(state.id, 9999, 'id check')
    if (window.refreshCounter1 == 1) {
      assert.equal('full', triggerType, 'trigger type check')
    }
    else {
      assert.equal('refresh', triggerType, 'trigger type check')
    }

    if ( window.refreshCounter1 == 1 ) {
      App.Collection.loadAssets({
        TicketState: {
          9999: {
            name: 'some some name', id: 9999, updated_at: "2014-11-07T23:43:08.000Z"
          }
        }
      })

    }
    if ( window.refreshCounter1 == 2 ) {
      App.Collection.loadAssets({
        TicketState: {
          9999: {
            name: 'some some name', id: 9999, updated_at: "2014-11-07T23:43:08.000Z"
          }
        }
      })
    }
  }
  App.Collection.loadAssets({
    TicketState: {
      9999: {
        name: 'some some name', id: 9999, updated_at: "2014-11-06T23:43:08.000Z"
      }
    }
  })

  // do not force, but bild on every change/loadAssets
  App.TicketState.full(9999, callback1, false, true)

});

App.Delay.set( function() {
    QUnit.test( "model loadAssets tests - 1 / check refresh counter", assert => {
      assert.equal(window.refreshCounter1, 2, 'check refresh counter')
    });
  },
  1000
);

QUnit.test( "model loadAssets tests - 2", assert => {
  window.refreshCounter2 = 0
  var callback2 = function(state, triggerType) {
    window.refreshCounter2 = window.refreshCounter2 + 1
    assert.equal(state.id, 10000, 'id check')
    if (window.refreshCounter2 == 1) {
      assert.equal('full', triggerType, 'trigger type check')
    }
    else {
      assert.equal('refresh', triggerType, 'trigger type check')
    }
    if ( window.refreshCounter2 == 1 ) {
      App.Collection.loadAssets({
        TicketState: {
          10000: {
            name: 'some some name', id: 10000, updated_at: "2014-11-07T23:43:08.000Z"
          }
        }
      })
    }
    if ( window.refreshCounter2 == 2 ) {
      App.Collection.loadAssets({
        TicketState: {
          10000: {
            name: 'some some name', id: 10000, updated_at: "2014-11-05T23:43:08.000Z"
          }
        }
      })
    }
  }
  App.Collection.loadAssets({
    TicketState: {
      10000: {
        name: 'some some name', id: 10000, updated_at: "2014-11-06T23:43:08.000Z"
      }
    }
  })

  // do not force, but bild on every change/loadAssets
  App.TicketState.full(10000, callback2, false, true)

});

App.Delay.set( function() {
    QUnit.test( "model loadAssets tests - 2 / check refresh counter", assert => {
      assert.equal(window.refreshCounter2, 2, 'check refresh counter')
    });
  },
  1200
);

QUnit.test( "model loadAssets tests - 3", assert => {
  window.refreshCounter3 = 0
  var callback3 = function(state, triggerType) {
    window.refreshCounter3 = window.refreshCounter3 + 1
    assert.equal(state.id, 10001, 'id check')
    if (window.refreshCounter3 == 1) {
      assert.equal('full', triggerType, 'trigger type check')
    }
    else {
      assert.equal('refresh', triggerType, 'trigger type check')
    }

    if ( window.refreshCounter3 == 1 ) {
      App.Collection.loadAssets({
        TicketState: {
          10001: {
            name: 'some some name', id: 10001, updated_at: "2014-11-07T23:43:08.000Z"
          }
        }
      })
    }
    if ( window.refreshCounter3 == 2 ) {
      App.Collection.loadAssets({
        TicketState: {
          10001: {
            name: 'some some name', id: 10001, updated_at: "2014-11-08T23:43:08.000Z"
          }
        }
      })
    }
  }
  App.Collection.loadAssets({
    TicketState: {
      10001: {
        name: 'some some name', id: 10001, updated_at: "2014-11-06T23:43:08.000Z"
      }
    }
  })

  // do not force, but bild on every change/loadAssets
  App.TicketState.full(10001, callback3, false, true)

});

App.Delay.set( function() {
    QUnit.test( "model loadAssets tests - 3 / check refresh counter", assert => {
      assert.equal(window.refreshCounter3, 3, 'check refresh counter')
    });
  },
  1400
);

QUnit.test("updateAttributes will change existing attributes and add new ones", assert => {
  App.Ticket.resetAttributes();

  var attributesBefore = _.clone(App.Ticket.configure_attributes);
  var updateAttribute  = _.clone(attributesBefore[0]);

  updateAttribute['new_option_1239393'] = 1;

  App.Ticket.updateAttributes([
    updateAttribute,
    {
      name: 'new_attribute_1010101',
      display: 'New Attribute',
      tag: 'input',
      readonly: 1,
    },
  ]);

  var attributesAfterUpdate = _.clone(App.Ticket.configure_attributes);

  assert.equal(attributesAfterUpdate.length, attributesBefore.length + 1, 'new attributes list contains 1 more elements')
  assert.equal(attributesAfterUpdate[0]['new_option_1239393'], 1, 'first element of the new attributes is number')
  assert.equal(attributesAfterUpdate[0]['name'], 'number', 'first element of the new attributes got updated with the new option')
  assert.equal(attributesAfterUpdate[1]['name'], 'new_attribute_1010101', 'new attributes list contains the new element')

  App.Ticket.resetAttributes();
  var attributesAfterReset = _.clone(App.Ticket.configure_attributes);

  assert.equal(attributesAfterReset.length, attributesBefore.length, 'new attributes list has the same elements after reset')
  assert.equal(attributesAfterReset[0]['new_option_1239393'], undefined, 'first element of the new attributes has no attribute new_option_1239393')
});

}
