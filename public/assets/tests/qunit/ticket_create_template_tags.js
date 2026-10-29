QUnit.module('ticket create template tags', () => {
  var applyTemplateTags = (tags, templateTags, dirty) => {
    var params = tags === undefined ? {} : { tags: tags }

    App.TicketCreate.applyTemplateTags(params, templateTags, dirty)

    return params
  }

  QUnit.test('add operator', assert => {
    var templateTags = { value: 'foo, bar', operator: 'add' }

    assert.deepEqual(applyTemplateTags(undefined, templateTags, false), { tags: 'foo, bar' }, 'replaces tags in a clean form')
    assert.deepEqual(applyTemplateTags('baz, qux, foo', templateTags, true), { tags: 'baz, qux, foo, bar' }, 'merges with existing tags in a dirty form')
  })

  QUnit.test('remove operator', assert => {
    var templateTags = { value: 'foo, bar', operator: 'remove' }

    assert.deepEqual(applyTemplateTags(undefined, templateTags, false), {}, 'does nothing in a clean form')
    assert.deepEqual(applyTemplateTags('foo, bar, baz, qux', templateTags, true), { tags: 'baz, qux' }, 'removes existing tags in a dirty form')
  })

  QUnit.test('without operator (legacy)', assert => {
    var templateTags = { value: 'foo, bar' }

    assert.deepEqual(applyTemplateTags(undefined, templateTags, false), { tags: 'foo, bar' }, 'replaces tags in a clean form')
    assert.deepEqual(applyTemplateTags('baz, qux, foo', templateTags, true), { tags: 'baz, qux, foo, bar' }, 'merges with existing tags in a dirty form')
  })

  QUnit.test('without template tags', assert => {
    assert.deepEqual(applyTemplateTags('baz', null, false), { tags: undefined }, 'resets the tags in a clean form')
    assert.deepEqual(applyTemplateTags('baz', null, true), { tags: 'baz' }, 'keeps the tags in a dirty form')
  })
})
