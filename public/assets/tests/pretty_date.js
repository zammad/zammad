let freeze_at = new Date(0)
freeze_at.setFullYear(1999)
freeze_at.setMonth(3)
freeze_at.setDate(22)
freeze_at.setHours(21)

test('App.PrettyDate#humanTime as timestamp', function() {
  clock = sinon.useFakeTimers({now: freeze_at})

  let type = 'timestamp'

  let offset = 60 * 60 * 24 * 7 * 1000
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() - offset), false, true, type), '04/15/1999 21:00', 'before')
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() + offset), false, true, type), '04/29/1999 21:00', 'after')

  offset = 50 * 1000
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() - offset), false, true, type), 'just now', 'close before')
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() - offset), false, true, type), 'just now', 'close after')

  clock.restore()
});

test('App.PrettyDate#humanTime as absolute', function() {
  clock = sinon.useFakeTimers({now: freeze_at})

  let type = 'absolute'

  let offset = 60 * 60 * 24 * 3 * 1000
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() - offset), false, true, type), 'Monday 21:00', 'less than a week before')
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() + offset), false, true, type), 'Sunday 21:00', 'less than a week after')

  offset = 60 * 30 * 1000
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() - offset), false, true, type), 'Thursday 20:30', 'less than an hour before')
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() + offset), false, true, type), 'Thursday 21:30', 'less than an hour after')

  offset = 60 * 60 * 24 * 90 * 1000
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() - offset), false, true, type), 'Friday 22. Jan 20:00', 'in same year and before')
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() + offset), false, true, type), 'Wednesday 21. Jul 21:00', 'in same year and after')

  offset = 60 * 60 * 24 * 300 * 1000
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() - offset), false, true, type), 'Friday 06/26/1998 21:00', 'long before')

  offset = 60 * 60 * 24 * 900 * 1000
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() + offset), false, true, type), 'Monday 10/08/2001 21:00', 'long after')

  offset = 50 * 1000
  equal(App.PrettyDate.humanTime(new Date(), false, true, type), 'just now', 'close before')
  equal(App.PrettyDate.humanTime(new Date(), false, true, type), 'just now', 'close after')

  clock.restore()
});

test('App.PrettyDate#humanTime as relative', function() {
  clock = sinon.useFakeTimers({now: freeze_at})

  let type = 'relative'

  let offset = 60 * 5 * 1000
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() - offset), false, true, type), '5 minutes ago', 'minutes before')
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() + offset), false, true, type), 'in 5 minutes', 'minutes after')

  offset = 60 * 60 * 4 * 1000 + 60 * 5 * 1000
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() - offset), false, true, type), '4 hours 5 minutes ago', 'hours before')
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() + offset), false, true, type), 'in 4 hours 5 minutes', 'hours after')

  offset = 60 * 60 * 4 * 1000
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() - offset), false, true, type), '4 hours ago', 'exactly hours before')
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() + offset), false, true, type), 'in 4 hours', 'exactly hours after')

  offset = 60 * 60 * 24 * 3 * 1000 + 60 * 60 * 4 * 1000 + 60 * 5 * 1000
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() - offset), false, true, type), '3 days 4 hours ago', 'days before')
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() + offset), false, true, type), 'in 3 days 4 hours', 'days after')

  offset = 60 * 60 * 24 * 3 * 1000
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() - offset), false, true, type), '3 days ago', 'days before')
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() + offset), false, true, type), 'in 3 days', 'days after')

  offset = 60 * 60 * 24 * 14 * 1000 + 60 * 60 * 24 * 3 * 1000 + 60 * 60 * 4 * 1000 + 60 * 5 * 1000
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() - offset), false, true, type), '04/05/1999', 'over a week before')
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() + offset), false, true, type), 'in 17 days', 'over a week after')

  offset = 50 * 1000
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() - offset), false, true, type), 'just now', 'close before')
  equal(App.PrettyDate.humanTime(new Date(freeze_at.getTime() + offset), false, true, type), 'just now', 'close after')

  clock.restore()
});
