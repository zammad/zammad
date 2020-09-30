function check_ajax_field(field, value, count, callback, waitTotal = 30000, wait = 0) {
  $elementInput = $('[name="' + field + '"].js-shadow + .js-input')
  if ($elementInput.val() != value) {
    $elementInput.focus().val(value).trigger('input')
  }

  var $element = $('[name="' + field + '"]').closest('.searchableSelect').find('.js-optionsList')
  var entries  = $element.find('li:not(.is-hidden)').length
  var match    = entries == count

  if (match || wait >= waitTotal) {
    equal(entries, count, 'search result found for email address ' + value)
    callback()
    return
  }

  wait += 100
  if (wait % 3000 == 0)  {
    ok(true, 'check_ajax_field for ' + field + ' waiting ' + wait)
  }

  setTimeout(function() {
    check_ajax_field(field, value, count, callback, waitTotal, wait)
  }, 100)
}

test( "autocompletion_ajax check", function(assert) {
  var done = assert.async(1)

  $('#forms').append('<hr><h1>autocompletion_ajax check</h1><form id="form1"></form>')
  var el = $('#form1')

  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        {
          name:     'autocompletion_ajax1',
          display:  'AutocompletionAjax1',
          tag:      'autocompletion_ajax',
          relation: 'User'
        },
      ]
    },
    autofocus: true
  })

  new Promise( (resolve, reject) => {
    App.Auth.login({
      data: {
        username: 'master@example.com',
        password: 'test',
      },
      success: resolve,
      error: resolve
    });
  })
  .then( function() {
    return new Promise( (resolve, reject) => {
      notEqual(App.Session.get(), undefined, 'User is logged in so the api requests will work')

      check_ajax_field('autocompletion_ajax1', 'master@example.com', 1, resolve)
    })
  })
  .then( function() {
    return new Promise( (resolve, reject) => {
      check_ajax_field('autocompletion_ajax1', 'xxx@example.com', 0, resolve)
    })
  })
  .finally(done)
})
