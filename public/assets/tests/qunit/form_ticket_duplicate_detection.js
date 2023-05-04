QUnit.test('form ticket duplicate detection', (assert) => {
  var done = assert.async(1)

  App.Config.set('ticket_duplicate_detection_title', 'foo')
  App.Config.set('ticket_duplicate_detection_body', 'bar')

  $('#forms').append('<hr><h1>form ticket duplicate detection</h1><form id="form1"></form>')

  var el = $('#form1')
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'ticket_duplicate_detection', display: 'ticket_duplicate_detection', tag: 'ticket_duplicate_detection', null: true, label_class: 'hidden'  }
      ]
    },
  });

  var payload = {
    count: 1,
    items: [
      [1, '27001', 'Welcome to Zammad!'],
    ],
  };

  var fieldElement = el.find('.duplicate-ticket-detection')

  assert.equal(typeof fieldElement.data('handleValue'), 'function', 'implements handleValue interface')
  assert.ok(fieldElement.hasClass('hide'), 'hides itself initially')

  fieldElement.data('handleValue')(payload)

  assert.notOk(fieldElement.hasClass('hide'), 'shows itself on payload with results')
  assert.equal(fieldElement.find('h4').text(), 'foo', 'displays configured title')
  assert.equal(fieldElement.find('p').text(), 'bar', 'displays configured message')
  assert.equal(fieldElement.find('a[href="#ticket/zoom/1"]').text().trim(), '27001', 'contains ticket link with ticket number')
  assert.ok(fieldElement.find('li:contains(Welcome to Zammad!)'), 'contains ticket title')

  payload = {
    count: 0,
    items: [],
  }

  fieldElement.data('handleValue')(payload)

  assert.ok(fieldElement.hasClass('hide'), 'hides itself on empty payload')

  payload = {
    count: 50,
    items: [],
  }

  fieldElement.data('handleValue')(payload)

  assert.notOk(fieldElement.hasClass('hide'), 'shows itself on payload with results but without tickets')
  assert.equal(fieldElement.find('h4').text(), 'foo', 'displays configured title')
  assert.equal(fieldElement.find('p').text(), 'bar', 'displays configured message')
  assert.notOk(fieldElement.find('ul').length, 'hides ticket list')

  const collapseDelay = 350

  // Combine all test examples in the same promise chain due to asynchronous behavior.
  return new Promise((resolve) => {
      payload = {
        count: 3,
        items: [
          [2, '27002', 'A Test Ticket'],
          [3, '27003', 'Another Test Ticket'],
          [4, '27004', 'Overflown Ticket'],
        ],
      }

      fieldElement.data('handleValue')(payload)

      setTimeout(() => { resolve() }, collapseDelay)
    })
    .then(() => new Promise((resolve) => {
      assert.ok(fieldElement.find('li:contains(A Test Ticket):visible').length, 'shows first ticket')
      assert.ok(fieldElement.find('li:contains(Another Test Ticket):visible').length, 'shows second ticket')
      assert.notOk(fieldElement.find('li:contains(Overflown Ticket):visible').length, 'hides third ticket')
      assert.equal(fieldElement.find('.btn').text(), 'See more', 'shows see more button')

      fieldElement.find('.btn').click()

      setTimeout(() => { resolve() }, collapseDelay)
    }))
    .then(() => new Promise((resolve) => {
      assert.ok(fieldElement.find('li:contains(Overflown Ticket):visible').length, 'shows third ticket')
      assert.equal(fieldElement.find('.btn').text(), 'See less', 'shows see less button')

      fieldElement.find('.btn').click()

      setTimeout(() => { resolve() }, collapseDelay)
    }))
    .then(() => {
      assert.notOk(fieldElement.find('li:contains(Overflown Ticket):visible').length, 'hides third ticket')
      assert.equal(fieldElement.find('.btn').text(), 'See more', 'shows see more button')
    })
    .finally(done)
});
