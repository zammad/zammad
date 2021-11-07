QUnit.test("time_duration_hh_mm", assert => {
  let func = App.ViewHelpers.time_duration_hh_mm
  assert.equal(func(1), '00:01')

  assert.equal(func(61), '01:01')

  assert.equal(func(3600), '60:00')

  assert.equal(func(7200), '120:00')
})

QUnit.test("time_duration", assert => {
  let func = App.ViewHelpers.time_duration
  assert.equal(func(1), '00:01')

  assert.equal(func(61), '01:01')

  assert.equal(func(3600), '1:00:00')

  assert.equal(func(7200), '2:00:00')

  assert.equal(func(36000), '10:00:00')

  assert.equal(func(360101), '100:01:41')
})
