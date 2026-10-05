// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

QUnit.test('App.ClipBoard.getSelectedObject before any selection was recorded', assert => {
  let selection = App.ClipBoard.getSelectedObject()

  assert.strictEqual(selection, window.getSelection(), 'falls back to the live browser selection')
  assert.equal(typeof selection.rangeCount, 'number', 'exposes the range count')
})

QUnit.test('App.ClipBoard.getSelectedObject after a selection was recorded', assert => {
  let recordedSelection = window.getSelection()

  App.ClipBoard.manuallyUpdateSelection()

  let stub = sinon.stub(window, 'getSelection').returns({ rangeCount: 0 })

  try {
    assert.strictEqual(App.ClipBoard.getSelectedObject(), recordedSelection, 'prefers the recorded selection over the fallback')
  } finally {
    stub.restore()
  }
})
