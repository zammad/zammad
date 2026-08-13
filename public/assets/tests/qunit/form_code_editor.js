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
  var updateDelay = 1000
  var hintsTimeout = 15000

  // Wait until the replacements list is shown (or hidden), since its rendering depends on
  //   several asynchronous mechanisms: CodeMirror reads typed text via DOM polling, the hint
  //   function is promise-based and the replacements are initially fetched via AJAX.
  //   Reject after a timeout, so the test fails with a meaningful message.
  var waitForHints = (shown) => new Promise((resolve, reject) => {
    var startTime = Date.now()
    var check = () => {
      if (Boolean($('.CodeMirror-hints li').length) === shown) {
        resolve()
        return
      }
      if (Date.now() - startTime > hintsTimeout) {
        reject(new Error('Timed out waiting for the replacements list to be ' + (shown ? 'shown' : 'hidden')))
        return
      }
      setTimeout(check, 50)
    }
    check()
  })

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
      .then(() => waitForHints(true))
      .then(() => {
        assert.ok($('.CodeMirror-hints li').length, 'shows full replacements list triggered by ::')
      })
      .then(() => new Promise((resolve) => {
        syn.click(editor[0]).type('ticket.id')
        setTimeout(() => { resolve() }, updateDelay)
      }))
      // Choose the replacement only after the filtered list has been shown,
      //   otherwise the enter key inserts a line break instead.
      .then(() => waitForHints(true))
      .then(() => new Promise((resolve) => {
        syn.type(editor[0], '[enter]')
        setTimeout(() => { resolve() }, updateDelay)
      }))
      .then(() => waitForHints(false))
      .then(() => {
        assert.notOk($('.CodeMirror-hints').length, 'hides replacements list after choosing')
      })
      .then(() => new Promise((resolve) => {
        syn.click(editor[0]).type('[right],[enter]"title[right]:[space]"#{')
        setTimeout(() => { resolve() }, updateDelay)
      }))
      .then(() => waitForHints(true))
      .then(() => {
        assert.ok($('.CodeMirror-hints li').length, 'shows full replacements list triggered by #{')
      })
      .then(() => new Promise((resolve) => {
        syn.click(editor[0]).type('ticket.titl')
        setTimeout(() => { resolve() }, updateDelay)
      }))
      // Choose the replacement only after the filtered list has been shown,
      //   otherwise the enter key inserts a line break instead.
      .then(() => waitForHints(true))
      .then(() => new Promise((resolve) => {
        syn.type(editor[0], '[enter]')
        setTimeout(() => { resolve() }, updateDelay)
      }))
      .then(() => waitForHints(false))
      .then(() => {
        assert.notOk($('.CodeMirror-hints').length, 'hides replacements list after choosing')
      })
      .then(() => new Promise((resolve) => {
        syn.click(editor[0]).type('[right],[enter]"escalation[right]:[space]"#{')
        setTimeout(() => { resolve() }, updateDelay)
      }))
      .then(() => waitForHints(true))
      .then(() => {
        assert.ok($('.CodeMirror-hints li').length, 'shows full replacements list triggered by #{')
      })
      .then(() => new Promise((resolve) => {
        syn.click(editor[0]).type('ticket.escalation_at')
        setTimeout(() => { resolve() }, updateDelay)
      }))
      .then(() => waitForHints(false))
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
      .catch((error) => {
        assert.ok(false, error.message)
      })
      .finally(done)

  }, initDelay)
});
