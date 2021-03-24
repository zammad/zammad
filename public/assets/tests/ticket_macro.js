QUnit.module("ticket macro pending time check", hooks => {
  hooks.beforeEach( () => {
    this.clock = sinon.useFakeTimers()
  })

  hooks.afterEach(() => {
    this.clock.restore()
  })

  var calculate_travel_on_ticket = (rules) => {
    var ticket = new App.Ticket()

    App.Ticket.macro({
      ticket: ticket,
      macro: {
        "ticket.pending_time": rules
      }
    })

    return new Date(ticket.pending_time) - new Date()
  }

  test("5 days", assert => {
    var rules = {
      operator: "relative",
      range: "day",
      value: 5
    }

    assert.equal(calculate_travel_on_ticket(rules), 60 * 60 * 24 * 5 * 1000)
  })

  test("5 minutes", assert => {
    var rules = {
      operator: "relative",
      range: "minute",
      value: 3
    }

    assert.equal(calculate_travel_on_ticket(rules), 60 * 3 * 1000)
  });

  test("10 hours", assert => {
    var rules = {
      operator: "relative",
      range: "hour",
      value: 10
    }

    assert.equal(calculate_travel_on_ticket(rules), 60 * 60 * 10 * 1000)
  });
})
