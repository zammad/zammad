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

QUnit.test('relative_time', assert => {
  let func = App.ViewHelpers.relative_time

  clock = sinon.useFakeTimers({ now: new Date('2022-11-15T10:00:00.000Z') })

  assert.equal(func(1, 'minute'), '2022-11-15T10:01:00.000Z')
  assert.equal(func(5, 'hour'), '2022-11-15T15:00:00.000Z')
  assert.equal(func(3, 'day'), '2022-11-18T10:00:00.000Z')
  assert.equal(func(4, 'week'), '2022-12-13T10:00:00.000Z')
  assert.equal(func(8, 'month'), '2023-07-15T09:00:00.000Z')
  assert.equal(func(2, 'year'), '2024-11-15T10:00:00.000Z')

  clock.restore()
})
