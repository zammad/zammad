QUnit.test( "controller observer tests - observe", assert => {

  App.Ticket.refresh([{
    id: 1,
    title: 'ticket',
    state_id: 1,
    customer_id: 33,
    organization_id: 1,
    owner_id: 1,
    preferences: { a: 1, b: 2 },
  }])

  var observer1 = new App.ControllerObserver({
    object_id: 1,
    template: 'version',
    observe: {
      title: true,
      preferences: true,
    },
  })

  var ticket = App.Ticket.find(1)

  assert.equal(false, observer1.hasChanged(ticket))

  // track title changes
  ticket.title = 'title 2'

  assert.equal(true, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  ticket.title = undefined

  assert.equal(true, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  ticket.title = 'title 3'

  assert.equal(true, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  // track no owner_id changes
  ticket.owner_id = 2

  assert.equal(false, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  // track preferences changes
  ticket.preferences['a'] = 3

  assert.equal(true, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  ticket.preferences['c'] = 3
  assert.equal(true, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  // track no new_attribute1 changes
  ticket.new_attribute1 = 'na 3'

  assert.equal(false, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  ticket.new_attribute2 = function() { console.log(1) }

  assert.equal(false, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  ticket.new_attribute2 = function() { console.log(2) }

  assert.equal(false, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  // track title changes
  ticket.title = function() { console.log(1) }

  assert.equal(true, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  ticket.title = function() { console.log(2) }

  assert.equal(false, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  ticket.title = 1

  assert.equal(true, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

});

QUnit.test( "controller observer tests - observeNot", assert => {

  App.Ticket.refresh([{
    id: 2,
    title: 'ticket',
    state_id: 1,
    customer_id: 33,
    organization_id: 1,
    owner_id: 1,
    preferences: { a: 1, b: 2 },
  }])

  var observer1 = new App.ControllerObserver({
    object_id: 2,
    template: 'version',
    observeNot: {
      title: true,
      preferences: true,
    },
  })

  var ticket = App.Ticket.find(2)

  assert.equal(false, observer1.hasChanged(ticket))

  // track no title changes
  ticket.title = 'title 2'

  assert.equal(false, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  // track owner_id changes
  ticket.owner_id = 2

  assert.equal(true, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  ticket.owner_id = undefined

  assert.equal(true, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  ticket.owner_id = 3

  assert.equal(true, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  // track no preferences changes
  ticket.preferences['a'] = 3

  assert.equal(false, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  ticket.preferences['c'] = 3
  assert.equal(false, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  // track preferences2 changes
  ticket.preferences2 = {}

  assert.equal(true, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  ticket.preferences2['a'] = 3

  assert.equal(true, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  ticket.preferences2['a'] = 2

  assert.equal(true, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  ticket.preferences2['c'] = 3
  assert.equal(true, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  // track new_attribute1 changes
  ticket.new_attribute1 = 'na 3'

  assert.equal(true, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  // track no new_attribute2 changes (because of function content)
  ticket.new_attribute2 = function() { console.log(1) }

  assert.equal(false, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  ticket.new_attribute2 = function() { console.log(2) }

  assert.equal(false, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  // track owner_id changes (pnly if content has no function content)
  ticket.owner_id = function() { console.log(1) }

  assert.equal(true, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  ticket.owner_id = function() { console.log(2) }

  assert.equal(false, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

  ticket.owner_id = 1

  assert.equal(true, observer1.hasChanged(ticket))
  assert.equal(false, observer1.hasChanged(ticket))

});
