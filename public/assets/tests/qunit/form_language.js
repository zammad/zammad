QUnit.test('form language checks', (assert) => {
  App.Config.set('locale_default', 'de-de')

  $('#forms').append('<hr><h1>form language #1</h1><form id="form1"></form>')

  var el = $('#form1')
  new App.ControllerForm({
    el: el,
    model: {
      configure_attributes: [
        { name: 'language', display: 'Language', tag: 'language', null: false }
      ]
    },
  });

  var params = App.ControllerForm.params(el)

  assert.deepEqual(params, { language: 'de-de' }, 'default/fallback param check')
})

QUnit.test('initial value', (assert) => {
  App.Config.set('locale_default', 'de-de')

  $('#forms').append('<hr><h1>form language #1</h1><form id="form2"></form>')

  var el = $('#form2')
  new App.ControllerForm({
    el: el,
    model: {
      configure_attributes: [
        { name: 'language', display: 'Language', tag: 'language', null: false, value: 'en-us' }
      ]
    },
  });

  var params = App.ControllerForm.params(el)

  assert.deepEqual(params, { language: 'en-us' }, 'initial param check')
})
