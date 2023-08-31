QUnit.module('form tokenfield')

QUnit.test('initial value', (assert) => {
  var done = assert.async(1)

  $('#forms').append('<hr><h1>form tokenfield #1</h1><form id="form1"></form>')

  var el = $('#form1')
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: '{json}tokenfield', display: 'Tokens', tag: 'tokenfield', null: false, value: ['foo', 'bar'] }
      ]
    },
  });

  var params = App.ControllerForm.params(el)
  var test_params = {
    tokenfield: ['foo', 'bar']
  }

  assert.deepEqual(params, test_params, 'initial param check')

  var initDelay = 750

  setTimeout(() => {
    console.debug(el.find('.token-label').eq(0))
    assert.equal(el.find('.token-label').eq(0).text(), 'foo', 'first token label')
    assert.equal(el.find('.token-label').eq(1).text(), 'bar', 'second token label')
    done()
  }, initDelay)
})

QUnit.test('default value', (assert) => {
  $('#forms').append('<hr><h1>form tokenfield #2</h1><form id="form2"></form>')

  el = $('#form2')

  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: '{json}tokenfield', display: 'Tokens', tag: 'tokenfield', null: false, default: [] }
      ]
    },
  });

  params = App.ControllerForm.params(el)
  test_params = {
    tokenfield: []
  }

  assert.deepEqual(params, test_params, 'default param check')
})

QUnit.test('value update', (assert) => {
  var done = assert.async(1)

  $('#forms').append('<hr><h1>form tokenfield #3</h1><form id="form3"></form>')

  el = $('#form3')

  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: '{json}tokenfield', display: 'Tokens', tag: 'tokenfield', null: false, default: [] }
      ]
    },
  });

  params = App.ControllerForm.params(el)
  test_params = {
    tokenfield: []
  }

  assert.deepEqual(params, test_params, 'default param check')

  var initDelay = 750
  var updateDelay = 500

  setTimeout(() => {
    var tokenInput = el.find('.token-input')

    // Combine all test examples in the same promise chain due to asynchronous behavior.
    new Promise((resolve) => {
        syn.click(tokenInput[0]).type('one[tab]')
        setTimeout(() => { resolve() }, updateDelay)
      })
      .then(() => {
        var params = App.ControllerForm.params(el)
        var test_params = {
          tokenfield: ['one']
        }

        assert.deepEqual(params, test_params, 'value updated after token created (1)')
      })
      .then(() => new Promise((resolve) => {
        syn.click(tokenInput[0]).type('two[tab]')
        setTimeout(() => { resolve() }, updateDelay)
      }))
      .then(() => {
        var params = App.ControllerForm.params(el)
        var test_params = {
          tokenfield: ['one', 'two']
        }

        assert.deepEqual(params, test_params, 'value updated after token created (2)')
      })
      .then(() => new Promise((resolve) => {
        syn.click(tokenInput[0]).type('three[tab]')
        setTimeout(() => { resolve() }, updateDelay)
      }))
      .then(() => {
        var params = App.ControllerForm.params(el)
        var test_params = {
          tokenfield: ['one', 'two', 'three']
        }

        assert.deepEqual(params, test_params, 'value updated after token created (3)')
      })
      .then(() => new Promise((resolve) => {
        var firstToken = el.find('.token').eq(0)
        syn.click(firstToken.find('.close')[0])
        setTimeout(() => { resolve() }, updateDelay)
      }))
      .then(() => {
        var params = App.ControllerForm.params(el)
        var test_params = {
          tokenfield: ['two', 'three']
        }

        assert.deepEqual(params, test_params, 'value updated after token removed (1)')
      })
      .then(() => new Promise((resolve) => {
        var secondToken = el.find('.token').eq(0)
        syn.dblclick(secondToken.find('.token-label')[0])
        setTimeout(() => { resolve() }, updateDelay)
      }))
      .then(() => {
        var params = App.ControllerForm.params(el)
        var test_params = {
          tokenfield: ['three']
        }

        assert.deepEqual(params, test_params, 'value updated after token being edited (2)')
      })
      .then(() => new Promise((resolve) => {
        syn.type(tokenInput[0], 'twoedit[tab]')
        setTimeout(() => { resolve() }, updateDelay)
      }))
      .then(() => {
        var params = App.ControllerForm.params(el)
        var test_params = {
          tokenfield: ['twoedit', 'three']
        }

        assert.deepEqual(params, test_params, 'value updated after token edited (2)')
      })
      .finally(done)

  }, initDelay)
});

QUnit.test('compatibility layer for value type (#4709)', (assert) => {
  $('#forms').append('<hr><h1>form tokenfield #4</h1><form id="form4"></form>')

  var el = $('#form4')
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: '{json}tokenfield', display: 'Tokens', tag: 'tokenfield', null: false, value: 'foobar' }
      ]
    },
  });

  var params = App.ControllerForm.params(el)
  var test_params = {
    tokenfield: ['foobar']
  }

  assert.deepEqual(params, test_params, 'migrated value type')
})
