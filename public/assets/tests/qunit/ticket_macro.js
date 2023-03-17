QUnit.module("ticket macro pending time check", hooks => {
  hooks.beforeEach( () => {
    this.offset = new Date(0).getTimezoneOffset()
    this.clock = sinon.useFakeTimers()
  })

  hooks.afterEach(() => {
    this.clock.restore()
  })

  var calculate_travel_on_ticket_diff = (rules) => {
    var new_date = travel_on_ticket_date(rules)
    return new Date(new_date) - new Date()
  }

  var travel_on_ticket_date = (rules) => {
    var ticket = new App.Ticket()

    App.Ticket.macro({
      ticket: ticket,
      macro: {
        "ticket.pending_time": rules
      }
    })

    return ticket.pending_time
  }

  QUnit.test("5 days", assert => {
    var rules = {
      operator: "relative",
      range: "day",
      value: 5
    }

    assert.equal(calculate_travel_on_ticket_diff(rules), 60 * 60 * 24 * 5 * 1000)
  })

  QUnit.test("5 minutes", assert => {
    var rules = {
      operator: "relative",
      range: "minute",
      value: 3
    }

    assert.equal(calculate_travel_on_ticket_diff(rules), 60 * 3 * 1000)
  });

  QUnit.test("10 hours", assert => {
    var rules = {
      operator: "relative",
      range: "hour",
      value: 10
    }

    assert.equal(calculate_travel_on_ticket_diff(rules), 60 * 60 * 10 * 1000)
  });

  QUnit.test("10 months", assert => {
    var rules = {
      operator: "relative",
      range: "month",
      value: 10
    }

    var new_date = new Date(travel_on_ticket_date(rules))
    var target_date = new Date("1970-11-01T00:00:00.000Z")

    assert.equal(new_date.getTime(), target_date.getTime())
  });

  QUnit.test("10 years", assert => {
    var rules = {
      operator: "relative",
      range: "year",
      value: 1
    }

    var new_date = new Date(travel_on_ticket_date(rules))
    var target_date = new Date("1971-01-01T00:00:00.000Z")

    assert.equal(new_date.getTime(), target_date.getTime())
  });
})
