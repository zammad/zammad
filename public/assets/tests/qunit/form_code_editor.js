QUnit.test('form code editor', (assert) => {
  var done = assert.async(1)

  $('#forms').append('<hr><h1>form code editor</h1><form id="form1"></form>')

  var el = $('#form1')
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'code', display: 'Code', tag: 'code_editor', null: false, default: '[]' }
      ]
    },
  });

  var params = App.ControllerForm.params(el)
  var test_params = {
    code: '[]'
  }

  assert.deepEqual(params, test_params, 'default param check')

  var initDelay = 350
  var updateDelay = 500

  setTimeout(() => {

    var editor = el.find('.CodeMirror-code')

    // Combine all test examples in the same promise chain due to asynchronous behavior.
    new Promise((resolve) => {
        syn.click(editor[0]).type('[delete][delete]')
        setTimeout(() => { resolve() }, updateDelay)
      })
      .then(() => {
        var params = App.ControllerForm.params(el)
        var test_params = {
          code: ''
        }

        assert.deepEqual(params, test_params, 'code editor supports empty value')
      })
      .then(() => new Promise((resolve) => {
        syn.click(editor[0]).type('{}')
        setTimeout(() => { resolve() }, updateDelay)
      }))
      .then(() => {
        var params = App.ControllerForm.params(el)
        var test_params = {
          code: '{}'
        }

        assert.deepEqual(params, test_params, 'code editor value was updated')
      })
      .then(() => new Promise((resolve) => {
        App.Auth.login({
          data: {
            username: 'admin@example.com',
            password: 'test',
          },
          success: resolve,
          error: resolve
        })
      }))
      .then(() => new Promise((resolve) => {
        syn.click(editor[0]).type('[left][enter]"id[right]:[space]"::')
        setTimeout(() => { resolve() }, updateDelay)
      }))
      .then(() => {
        assert.ok($('.CodeMirror-hints'), 'shows full replacements list triggered by ::')
      })
      .then(() => new Promise((resolve) => {
        syn.click(editor[0]).type('ticket.id[enter]')
        setTimeout(() => { resolve() }, updateDelay)
      }))
      .then(() => {
        assert.notOk($('.CodeMirror-hints').length, 'hides replacements list after choosing')
      })
      .then(() => new Promise((resolve) => {
        syn.click(editor[0]).type('[right],[enter]"title[right]:[space]"#{')
        setTimeout(() => { resolve() }, updateDelay)
      }))
      .then(() => {
        assert.ok($('.CodeMirror-hints'), 'shows full replacements list triggered by #{')
      })
      .then(() => new Promise((resolve) => {
        syn.click(editor[0]).type('ticket.titl[enter]')
        setTimeout(() => { resolve() }, updateDelay)
      }))
      .then(() => {
        assert.notOk($('.CodeMirror-hints').length, 'hides replacements list after choosing')
      })
      .then(() => new Promise((resolve) => {
        syn.click(editor[0]).type('[right],[enter]"escalation[right]:[space]"#{')
        setTimeout(() => { resolve() }, updateDelay)
      }))
      .then(() => {
        assert.ok($('.CodeMirror-hints'), 'shows full replacements list triggered by #{')
      })
      .then(() => new Promise((resolve) => {
        syn.click(editor[0]).type('ticket.escalation_at')
        setTimeout(() => { resolve() }, updateDelay)
      }))
      .then(() => {
        assert.notOk($('.CodeMirror-hints').length, 'hides replacements list after only a single match remains')
      })
      .then(() => {
        var params = App.ControllerForm.params(el)
        var test_params = {
          code: '{\r\n  "id": "#{ticket.id}",\r\n  "title": "#{ticket.title}",\r\n  "escalation": "#{ticket.escalation_at}"\r\n}',
        }

        assert.deepEqual(params, test_params, 'code editor value contains replacements')
      })
      .finally(done)

  }, initDelay)
});
