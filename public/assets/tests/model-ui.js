window.onload = function() {

// model
test( "model ui basic tests", function() {

  // load ref object
  App.Collection.loadAssets({
    TicketState: {
      1: {
        name: 'new', id: 1, updated_at: "2014-11-07T23:43:08.000Z",
      },
      2: {
        name: 'open', id: 2, updated_at: "2014-11-07T23:43:08.000Z",
      },
      3: {
        name: 'closed <>&', id: 3, updated_at: "2014-11-07T23:43:08.000Z",
      },
    },
  })

  // create ticket
  var attribute1 = {
    name: 'date', display: 'date 1',  tag: 'date', null: true
  };
  App.Ticket.configure_attributes.push( attribute1 )
  var attribute2 = {
    name: 'textarea', display: 'textarea 1',  tag: 'textarea', null: true
  };
  App.Ticket.configure_attributes.push( attribute2 )

  var ticket = new App.Ticket()
  ticket.load({
    id:         1000,
    title:      'some title <>&',
    state_id:   2,
    updated_at: '2014-11-07T23:43:08.000Z',
    date:       '2015-02-07',
    textarea:   "some new\nline"
  })

  App.i18n.set('en-us')
  equal( App.viewPrint( ticket, 'id' ), 1000)
  equal( App.viewPrint( ticket, 'title' ), 'some title &lt;&gt;&amp;')
  equal( App.viewPrint( ticket, 'state' ), 'open')
  equal( App.viewPrint( ticket, 'state_id' ), 'open')
  equal( App.viewPrint( ticket, 'not_existing' ), '-')
  equal( App.viewPrint( ticket, 'updated_at' ), '<time class="humanTimeFromNow " data-time="2014-11-07T23:43:08.000Z" title="11/07/2014 23:43">11/07/2014</time>')
  equal( App.viewPrint( ticket, 'date' ), '02/07/2015')
  equal( App.viewPrint( ticket, 'textarea' ), '<div>some new</div><div>line</div>')


  App.i18n.set('de-de')
  equal( App.viewPrint( ticket, 'id' ), 1000)
  equal( App.viewPrint( ticket, 'title' ), 'some title &lt;&gt;&amp;')
  equal( App.viewPrint( ticket, 'state' ), 'offen')
  equal( App.viewPrint( ticket, 'state_id' ), 'offen')
  equal( App.viewPrint( ticket, 'not_existing' ), '-')
  equal( App.viewPrint( ticket, 'updated_at' ), '<time class="humanTimeFromNow " data-time="2014-11-07T23:43:08.000Z" title="07.11.2014 23:43">07.11.2014</time>')
  equal( App.viewPrint( ticket, 'date' ), '07.02.2015')
  equal( App.viewPrint( ticket, 'textarea' ), '<div>some new</div><div>line</div>')


  App.i18n.set('en-us')
  ticket.state_id = 3
  equal( App.viewPrint( ticket, 'state' ), 'closed &lt;&gt;&amp;')
  equal( App.viewPrint( ticket, 'state_id' ), 'closed &lt;&gt;&amp;')

  App.i18n.set('de')
  equal( App.viewPrint( ticket, 'state' ), 'closed &lt;&gt;&amp;')
  equal( App.viewPrint( ticket, 'state_id' ), 'closed &lt;&gt;&amp;')

  // normal string
  data = {
    a: 1,
    b: 'abc',
    c: {
      displayName: function() { return "my displayName <>&" }
    },
  }
  equal( App.viewPrint( data, 'a' ), 1)
  equal( App.viewPrint( data, 'b' ), 'abc')
  equal( App.viewPrint( data, 'c' ), 'my displayName &lt;&gt;&amp;')

});


}
