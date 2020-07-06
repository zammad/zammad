test( "ticket macro pending time check", function() {
  var test_relative = function(rules, target, description){
    var ticket = new App.Ticket()

    App.Ticket.macro({
      ticket: ticket,
      macro: {
        "ticket.pending_time": rules
      }
    })

    var compare_against = new Date()
    var travel = Math.abs( new Date(ticket.pending_time) - compare_against)

    var diff = Math.abs(target - travel)

    ok(diff < 1000, description)
  }

  var rules = {
    operator: "relative",
    range: "day",
    value: 5
  }

  test_relative(rules, 60 * 60 * 24 * 5 * 1000, '5 days')

  var rules = {
    operator: "relative",
    range: "minute",
    value: 3
  }

  test_relative(rules, 60 * 3 * 1000, '5 minutes')

  var rules = {
    operator: "relative",
    range: "hour",
    value: 10
  }

  test_relative(rules, 60 * 60 * 10 * 1000, '10 hours')
})
