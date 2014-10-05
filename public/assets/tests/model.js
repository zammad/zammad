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
