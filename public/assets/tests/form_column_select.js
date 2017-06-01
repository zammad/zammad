
// column_select
test( "column_select check", function(assert) {
  $('#forms').append('<hr><h1>column_select check</h1><form id="form1"></form>')
  var el = $('#form1')
  var defaults = {
    column_select2: ['aaa', 'bbb'],
    column_select3: [1, '2'],
  }
  var options = {
    'aaa': 'aaa display',
    'bbb': 'bbb display',
    'ccc': 'ccc display',
    1: '1 display',
    '2': '2 display',
  }
  new App.ControllerForm({
    el: el,
    model: {
      configure_attributes: [
        { name: 'column_select1', display: 'ColumnSelect1', tag: 'column_select', options: options, null: true, default: defaults['column_select1'] },
        { name: 'column_select2', display: 'ColumnSelect2', tag: 'column_select', options: options, null: false, default: defaults['column_select2'] },
        { name: 'column_select3', display: 'ColumnSelect3', tag: 'column_select', options: options, null: false, default: defaults['column_select3'] },
      ]
    },
    autofocus: true
  })

  var params = App.ControllerForm.params(el)
  var test_params = {
    column_select1: null,
    column_select2: ['aaa', 'bbb'],
    column_select3: ['1', '2'],
  }
  deepEqual(params, test_params, 'form param check')

  // add and remove selections
  $('[data-name="column_select1"] .js-pool .js-option[data-value="bbb"]').click()

  params = App.ControllerForm.params(el)
  test_params = {
    column_select1: 'bbb',
    column_select2: ['aaa', 'bbb'],
    column_select3: ['1', '2'],
  }
  deepEqual(params, test_params, 'form param check')

  var done = assert.async();
  setTimeout(function() {
    $('[data-name="column_select1"] .js-pool .js-option[data-value="aaa"]').click()
    $('[data-name="column_select2"] .js-pool .js-option[data-value="1"]').click()
    $('[data-name="column_select2"].js-selected .js-option[data-value="aaa"]').click()
    $('[data-name="column_select3"] .js-pool .js-option[data-value="aaa"]').click()

    params = App.ControllerForm.params(el)
    test_params = {
      column_select1: ['aaa', 'bbb'],
      column_select2: ['1', 'bbb'],
      column_select3: ['1', '2', 'aaa'],
    }
    deepEqual(params, test_params, 'form param check')
    done();
  }, 400);

});
