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

QUnit.test('relative_time - setMonth() sanity check', assert => {
  let func = App.ViewHelpers.relative_time

  clock = sinon.useFakeTimers({ now: new Date('2023-01-01T12:00:00.000Z') })

  assert.equal(func(1, 'month'), '2023-02-01T12:00:00.000Z', '1st of the month - 1 month')
  assert.equal(func(2, 'month'), '2023-03-01T12:00:00.000Z', '1st of the month - 2 months')
  assert.equal(func(3, 'month'), '2023-04-01T11:00:00.000Z', '1st of the month - 3 months')
  assert.equal(func(4, 'month'), '2023-05-01T11:00:00.000Z', '1st of the month - 4 months')
  assert.equal(func(5, 'month'), '2023-06-01T11:00:00.000Z', '1st of the month - 5 months')
  assert.equal(func(6, 'month'), '2023-07-01T11:00:00.000Z', '1st of the month - 6 months')
  assert.equal(func(7, 'month'), '2023-08-01T11:00:00.000Z', '1st of the month - 7 months')
  assert.equal(func(8, 'month'), '2023-09-01T11:00:00.000Z', '1st of the month - 8 months')
  assert.equal(func(9, 'month'), '2023-10-01T11:00:00.000Z', '1st of the month - 9 months')
  assert.equal(func(10, 'month'), '2023-11-01T12:00:00.000Z', '1st of the month - 10 months')
  assert.equal(func(11, 'month'), '2023-12-01T12:00:00.000Z', '1st of the month - 11 months')
  assert.equal(func(12, 'month'), '2024-01-01T12:00:00.000Z', '1st of the month - 12 months')

  clock = sinon.useFakeTimers({ now: new Date('2023-01-28T12:00:00.000Z') })

  assert.equal(func(1, 'month'), '2023-02-28T12:00:00.000Z', '28th of the month - 1 month')
  assert.equal(func(2, 'month'), '2023-03-28T11:00:00.000Z', '28th of the month - 2 months')
  assert.equal(func(3, 'month'), '2023-04-28T11:00:00.000Z', '28th of the month - 3 months')
  assert.equal(func(4, 'month'), '2023-05-28T11:00:00.000Z', '28th of the month - 4 months')
  assert.equal(func(5, 'month'), '2023-06-28T11:00:00.000Z', '28th of the month - 5 months')
  assert.equal(func(6, 'month'), '2023-07-28T11:00:00.000Z', '28th of the month - 6 months')
  assert.equal(func(7, 'month'), '2023-08-28T11:00:00.000Z', '28th of the month - 7 months')
  assert.equal(func(8, 'month'), '2023-09-28T11:00:00.000Z', '28th of the month - 8 months')
  assert.equal(func(9, 'month'), '2023-10-28T11:00:00.000Z', '28th of the month - 9 months')
  assert.equal(func(10, 'month'), '2023-11-28T12:00:00.000Z', '28th of the month - 10 months')
  assert.equal(func(11, 'month'), '2023-12-28T12:00:00.000Z', '28th of the month - 11 months')
  assert.equal(func(12, 'month'), '2024-01-28T12:00:00.000Z', '28th of the month - 12 months')

  clock = sinon.useFakeTimers({ now: new Date('2023-01-29T12:00:00.000Z') })

  assert.equal(func(1, 'month'), '2023-03-01T12:00:00.000Z', '29th of the month - 1 month')
  assert.equal(func(2, 'month'), '2023-03-29T11:00:00.000Z', '29th of the month - 2 months')
  assert.equal(func(3, 'month'), '2023-04-29T11:00:00.000Z', '29th of the month - 3 months')
  assert.equal(func(4, 'month'), '2023-05-29T11:00:00.000Z', '29th of the month - 4 months')
  assert.equal(func(5, 'month'), '2023-06-29T11:00:00.000Z', '29th of the month - 5 months')
  assert.equal(func(6, 'month'), '2023-07-29T11:00:00.000Z', '29th of the month - 6 months')
  assert.equal(func(7, 'month'), '2023-08-29T11:00:00.000Z', '29th of the month - 7 months')
  assert.equal(func(8, 'month'), '2023-09-29T11:00:00.000Z', '29th of the month - 8 months')
  assert.equal(func(9, 'month'), '2023-10-29T12:00:00.000Z', '29th of the month - 9 months')
  assert.equal(func(10, 'month'), '2023-11-29T12:00:00.000Z', '29th of the month - 10 months')
  assert.equal(func(11, 'month'), '2023-12-29T12:00:00.000Z', '29th of the month - 11 months')
  assert.equal(func(12, 'month'), '2024-01-29T12:00:00.000Z', '29th of the month - 12 months')

  clock = sinon.useFakeTimers({ now: new Date('2023-01-30T12:00:00.000Z') })

  assert.equal(func(1, 'month'), '2023-03-02T12:00:00.000Z', '30th of the month - 1 month')
  assert.equal(func(2, 'month'), '2023-03-30T11:00:00.000Z', '30th of the month - 2 months')
  assert.equal(func(3, 'month'), '2023-04-30T11:00:00.000Z', '30th of the month - 3 months')
  assert.equal(func(4, 'month'), '2023-05-30T11:00:00.000Z', '30th of the month - 4 months')
  assert.equal(func(5, 'month'), '2023-06-30T11:00:00.000Z', '30th of the month - 5 months')
  assert.equal(func(6, 'month'), '2023-07-30T11:00:00.000Z', '30th of the month - 6 months')
  assert.equal(func(7, 'month'), '2023-08-30T11:00:00.000Z', '30th of the month - 7 months')
  assert.equal(func(8, 'month'), '2023-09-30T11:00:00.000Z', '30th of the month - 8 months')
  assert.equal(func(9, 'month'), '2023-10-30T12:00:00.000Z', '30th of the month - 9 months')
  assert.equal(func(10, 'month'), '2023-11-30T12:00:00.000Z', '30th of the month - 10 months')
  assert.equal(func(11, 'month'), '2023-12-30T12:00:00.000Z', '30th of the month - 11 months')
  assert.equal(func(12, 'month'), '2024-01-30T12:00:00.000Z', '30th of the month - 12 months')

  clock = sinon.useFakeTimers({ now: new Date('2023-01-31T12:00:00.000Z') })

  assert.equal(func(1, 'month'), '2023-03-03T12:00:00.000Z', '31st of the month - 1 month')
  assert.equal(func(2, 'month'), '2023-03-31T11:00:00.000Z', '31st of the month - 2 months')
  assert.equal(func(3, 'month'), '2023-05-01T11:00:00.000Z', '31st of the month - 3 months')
  assert.equal(func(4, 'month'), '2023-05-31T11:00:00.000Z', '31st of the month - 4 months')
  assert.equal(func(5, 'month'), '2023-07-01T11:00:00.000Z', '31st of the month - 5 months')
  assert.equal(func(6, 'month'), '2023-07-31T11:00:00.000Z', '31st of the month - 6 months')
  assert.equal(func(7, 'month'), '2023-08-31T11:00:00.000Z', '31st of the month - 7 months')
  assert.equal(func(8, 'month'), '2023-10-01T11:00:00.000Z', '31st of the month - 8 months')
  assert.equal(func(9, 'month'), '2023-10-31T12:00:00.000Z', '31st of the month - 9 months')
  assert.equal(func(10, 'month'), '2023-12-01T12:00:00.000Z', '31st of the month - 10 months')
  assert.equal(func(11, 'month'), '2023-12-31T12:00:00.000Z', '31st of the month - 11 months')
  assert.equal(func(12, 'month'), '2024-01-31T12:00:00.000Z', '31st of the month - 12 months')

  clock.restore()
})
