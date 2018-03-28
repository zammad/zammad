window.onload = function() {

// model
test( "model basic tests", function() {

  // define model
  var configure_attributes_org = _.clone( App.Ticket.configure_attributes )
  var attribute1 = {
    name: 'test1', display: 'Test 1',  tag: 'input',  type: 'text', limit: 200, 'null': false
  };
  App.Ticket.configure_attributes.push( attribute1 )
  var attribute2 = {
    name: 'test2', display: 'Test 2',  tag: 'input',  type: 'text', limit: 200, 'null': true
  };
  App.Ticket.configure_attributes.push( attribute2 )
  var attribute3 = {
    name: 'pending_time1', display: 'Pending till1',  tag: 'input',  type: 'text', limit: 200, 'null': false, required_if: { state_id: [3] },
  };
  App.Ticket.configure_attributes.push( attribute3 )
  var attribute4 = {
    name: 'pending_time2', display: 'Pending till2',  tag: 'input',  type: 'text', limit: 200, 'null': true, required_if: { state_id: [3] },
  };
  App.Ticket.configure_attributes.push( attribute4 )

  // check validation

  console.log('TEST 1')
  var ticket = new App.Ticket()
  ticket.load({title: 'some title'})

  var error = ticket.validate()
  ok( error['group_id'], 'group_id is required')
  ok( !error['title'], 'title is required')
  ok( error['state_id'], 'state_id is required')
  ok( error['test1'], 'test1 is required')
  ok( !error['test2'], 'test2 is not required')
  ok( !error['pending_time1'], 'pending_time1 is not required')
  ok( !error['pending_time2'], 'pending_time2 is not required')


  console.log('TEST 2')
  ticket.title = 'some new title'
  ticket.state_id = [2,3]
  ticket.test2 = 123
  error = ticket.validate()
  ok( error['group_id'], 'group_id is required')
  ok( !error['title'], 'title exists')
  ok( !error['state_id'], 'state_id is')
  ok( error['test1'], 'test1 is required')
  ok( !error['test2'], 'test2 is not required')
  ok( error['pending_time1'], 'pending_time1 is required')
  ok( error['pending_time2'], 'pending_time2 is required')

  console.log('TEST 3')
  ticket.title = 'some new title'
  ticket.state_id = [2,1]
  ticket.test2 = 123
  error = ticket.validate()
  ok( error['group_id'], 'group_id is required')
  ok( !error['title'], 'title exists')
  ok( !error['state_id'], 'state_id is')
  ok( error['test1'], 'test1 is required')
  ok( !error['test2'], 'test2 is not required')
  ok( !error['pending_time1'], 'pending_time1 is required')
  ok( !error['pending_time2'], 'pending_time2 is required')

  console.log('TEST 4')
  ticket.title = 'some new title'
  ticket.state_id = [2,3]
  ticket.test2 = 123
  error = ticket.validate()
  ok( error['group_id'], 'group_id is required')
  ok( !error['title'], 'title exists')
  ok( !error['state_id'], 'state_id is')
  ok( error['test1'], 'test1 is required')
  ok( !error['test2'], 'test2 is not required')
  ok( error['pending_time1'], 'pending_time1 is required')
  ok( error['pending_time2'], 'pending_time2 is required')

  console.log('TEST 5')
  ticket.title = 'some new title'
  ticket.state_id = [2,3]
  ticket.test2 = 123
  ticket.pending_time1 = '2014-10-10 09:00'
  error = ticket.validate()
  ok( error['group_id'], 'group_id is required')
  ok( !error['title'], 'title exists')
  ok( !error['state_id'], 'state_id is')
  ok( error['test1'], 'test1 is required')
  ok( !error['test2'], 'test2 is not required')
  ok( !error['pending_time1'], 'pending_time1 is required')
  ok( error['pending_time2'], 'pending_time2 is required')


  // define model with screen
  App.Ticket.configure_attributes = configure_attributes_org
  var attribute1 = {
    name: 'test1', display: 'Test 1',  tag: 'input',  type: 'text', limit: 200, 'null': false, screen: { some_screen: { required_if: { state_id: [3] } } },
  };
  App.Ticket.configure_attributes.push( attribute1 )
  var attribute2 = {
    name: 'test2', display: 'Test 2',  tag: 'input',  type: 'text', limit: 200, 'null': true, screen: { some_screen: { required_if: { state_id: [3] } } },
  };
  App.Ticket.configure_attributes.push( attribute2 )
  var attribute3 = {
    name: 'group_id', display: 'Group', tag: 'select', multiple: false, null: false, relation: 'Group', screen: { some_screen: { null: false } },
  };
  App.Ticket.configure_attributes.push( attribute3 )
  var attribute4 = {
    name: 'owner_id', display: 'Owner', tag: 'select', multiple: false, null: false, relation: 'User', screen: { some_screen: { null: false } },
  };
  App.Ticket.configure_attributes.push( attribute4 )
  var attribute5 = {
    name: 'state_id', display: 'State', tag: 'select', multiple: false, null: false, relation: 'TicketState', screen: { some_screen: { null: false } },
  };
  App.Ticket.configure_attributes.push( attribute5 )

  // check validation with screen
  console.log('TEST 6')
  ticket = new App.Ticket()
  ticket.load({title: 'some title'})

  error = ticket.validate()
  ok( error['group_id'], 'group_id is required')
  ok( !error['title'], 'title is required')
  ok( error['state_id'], 'state_id is required')
  ok( error['test1'], 'test1 is required')
  ok( !error['test2'], 'test2 is not required')

  console.log('TEST 7')
  ticket.state_id = 3
  error = ticket.validate()
  ok( error['group_id'], 'group_id is required')
  ok( !error['title'], 'title is required')
  ok( !error['state_id'], 'state_id is required')
  ok( error['test1'], 'test1 is required')
  ok( !error['test2'], 'test2 is not required')

  console.log('TEST 8')
  ticket.state_id = 2
  error = ticket.validate()
  ok( error['group_id'], 'group_id is required')
  ok( !error['title'], 'title is required')
  ok( !error['state_id'], 'state_id is required')
  ok( error['test1'], 'test1 is required')
  ok( !error['test2'], 'test2 is not required')

  console.log('TEST 9')
  ticket.state_id = undefined
  error = ticket.validate({screen: 'some_screen'})
  ok( error['group_id'], 'group_id is required')
  ok( !error['title'], 'title is required')
  ok( error['state_id'], 'state_id is required')
  ok( !error['test1'], 'test1 is required')
  ok( !error['test2'], 'test2 is required')

  console.log('TEST 10')
  ticket.state_id = 2
  error = ticket.validate({screen: 'some_screen'})
  ok( error['group_id'], 'group_id is required')
  ok( !error['title'], 'title is required')
  ok( !error['state_id'], 'state_id is required')
  ok( !error['test1'], 'test1 is required')
  ok( !error['test2'], 'test2 is not required')

  console.log('TEST 11')
  ticket.state_id = 3
  error = ticket.validate({screen: 'some_screen'})
  ok( error['group_id'], 'group_id is required')
  ok( !error['title'], 'title is required')
  ok( !error['state_id'], 'state_id is required')
  ok( error['test1'], 'test1 is required')
  ok( error['test2'], 'test2 is required')

  console.log('TEST 12')
  ticket.state_id = 2
  error = ticket.validate()
  ok( error['group_id'], 'group_id is required')
  ok( !error['title'], 'title is required')
  ok( !error['state_id'], 'state_id is required')
  ok( error['test1'], 'test1 is required')
  ok( !error['test2'], 'test2 is not required')

  console.log('TEST 13')
  ticket.state_id = 3
  error = ticket.validate()
  ok( error['group_id'], 'group_id is required')
  ok( !error['title'], 'title is required')
  ok( !error['state_id'], 'state_id is required')
  ok( error['test1'], 'test1 is required')
  ok( !error['test2'], 'test2 is required')

  console.log('TEST 14')
  ticket.state_id = 2
  error = ticket.validate()
  ok( error['group_id'], 'group_id is required')
  ok( !error['title'], 'title is required')
  ok( !error['state_id'], 'state_id is required')
  ok( error['test1'], 'test1 is required')
  ok( !error['test2'], 'test2 is not required')

});

// search
test( "model search tests", function() {

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
  equal('2 normal', priorities[0].name, 'check 1 entry')
  equal('3 high', priorities[1].name, 'check 2 entry')
  equal('4 very high', priorities[2].name, 'check 3 entry')
  equal('1 low', priorities[3].name, 'check 4 entry')
  equal(undefined, priorities[4], 'check 5 entry')

  priorities = App.TicketPriority.search({sortBy:'created_at', order: 'DESC'})
  equal('1 low', priorities[0].name, 'check 4 entry')
  equal('4 very high', priorities[1].name, 'check 3 entry')
  equal('3 high', priorities[2].name, 'check 2 entry')
  equal('2 normal', priorities[3].name, 'check 1 entry')
  equal(undefined, priorities[4], 'check 5 entry')

});

// model
test( "model loadAssets tests - 1", function() {
  window.refreshCounter1 = 0
  var callback1 = function(state, triggerType) {
    window.refreshCounter1 = window.refreshCounter1 + 1
    equal(state.id, 9999, 'id check')
    if (window.refreshCounter1 == 1) {
      equal('full', triggerType, 'trigger type check')
    }
    else {
      equal('refresh', triggerType, 'trigger type check')
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
    test( "model loadAssets tests - 1 / check refresh counter", function() {
      equal(window.refreshCounter1, 2, 'check refresh counter')
    });
  },
  1000
);

test( "model loadAssets tests - 2", function() {
  window.refreshCounter2 = 0
  var callback2 = function(state, triggerType) {
    window.refreshCounter2 = window.refreshCounter2 + 1
    equal(state.id, 10000, 'id check')
    if (window.refreshCounter2 == 1) {
      equal('full', triggerType, 'trigger type check')
    }
    else {
      equal('refresh', triggerType, 'trigger type check')
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
    test( "model loadAssets tests - 2 / check refresh counter", function() {
      equal(window.refreshCounter2, 2, 'check refresh counter')
    });
  },
  1200
);

test( "model loadAssets tests - 3", function() {
  window.refreshCounter3 = 0
  var callback3 = function(state, triggerType) {
    window.refreshCounter3 = window.refreshCounter3 + 1
    equal(state.id, 10001, 'id check')
    if (window.refreshCounter3 == 1) {
      equal('full', triggerType, 'trigger type check')
    }
    else {
      equal('refresh', triggerType, 'trigger type check')
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
    test( "model loadAssets tests - 3 / check refresh counter", function() {
      equal(window.refreshCounter3, 3, 'check refresh counter')
    });
  },
  1400
);

test("updateAttributes will change existing attributes and add new ones", function() {
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

  equal(attributesAfterUpdate.length, attributesBefore.length + 1, 'new attributes list contains 1 more elements')
  equal(attributesAfterUpdate[attributesAfterUpdate.length - 1]['name'], 'new_attribute_1010101', 'new attributes list contains the new element')
  equal(attributesAfterUpdate[0]['new_option_1239393'], 1, 'first element of the new attributes got updated with the new option')

  App.Ticket.resetAttributes();
  var attributesAfterReset = _.clone(App.Ticket.configure_attributes);

  equal(attributesAfterReset.length, attributesBefore.length, 'new attributes list has the same elements after reset')
  equal(attributesAfterReset[0]['new_option_1239393'], undefined, 'first element of the new attributes has no attribute new_option_1239393')
});

}
