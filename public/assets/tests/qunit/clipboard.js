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

QUnit.test('App.ClipBoard.getSelected html of a selection drawn inside a preformatted block', assert => {
  let article = document.createElement('div')
  article.innerHTML = '<pre><code>One\nTwo\nThree\nFour</code></pre><p>After</p>'
  document.body.appendChild(article)

  let selectInside = (node, from, to) => {
    let range = document.createRange()
    range.setStart(node, from)
    range.setEnd(node, to)

    window.getSelection().removeAllRanges()
    window.getSelection().addRange(range)
    App.ClipBoard.manuallyUpdateSelection()
  }

  try {
    let text = article.querySelector('code').firstChild

    selectInside(text, 4, 13)
    assert.equal(App.ClipBoard.getSelected('html'), '<pre><code>Two\nThree</code></pre>', 'restores the block around the selection')
    assert.equal(App.ClipBoard.getSelected('text'), 'Two\nThree', 'keeps the plain text as it is')

    selectInside(article.querySelector('p').firstChild, 0, 5)
    assert.equal(App.ClipBoard.getSelected('html'), 'After', 'leaves a selection outside of a block untouched')
  } finally {
    window.getSelection().removeAllRanges()
    article.remove()
  }
})
