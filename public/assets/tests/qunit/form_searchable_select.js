// searchable_select
QUnit.test( "searchable_select check", assert => {

  $('#forms').append('<hr><h1>searchable_select check</h1><form id="form1"></form>')
  var el = $('#form1')
  var defaults = {
    searchable_select2: 'bbb',
    searchable_select4: 'ccc',
  }
  var options = {
    'aaa': 'aaa display',
    'bbb': 'bbb display',
    'ccc': 'ccc display',
  }
  var options_4_tree = [
    { value: 'aaa', name: 'aaa display' },
    { value: 'bbb', name: 'bbb display' },
    { value: 'ccc', name: 'ccc display', children: [
      { value: 'ccc::aaa', name: 'aaa display' },
      { value: 'ccc::bbb', name: 'bbb display' },
    ] },
  ]
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        {
          name:    'searchable_select1',
          display: 'SearchableSelect1',
          tag:     'searchable_select',
          options: options,
          null:    true,
          default: defaults['searchable_select1']
        },
        {
          name:    'searchable_select2',
          display: 'SearchableSelect2',
          tag:     'searchable_select',
          options: options,
          null:    false,
          default: defaults['searchable_select2']
        },
        {
          name:    'searchable_select3',
          display: 'SearchableSelect3',
          tag:     'searchable_select',
          options: options,
          default: defaults['searchable_select3'],
          null:    true,
          unknown: true
        },
        {
          name:    'searchable_select4',
          display: 'SearchableSelect4',
          tag:     'searchable_select',
          options: options_4_tree,
          default: defaults['searchable_select4'],
          null:    true,
          unknown: true
        },
      ]
    },
    autofocus: true
  })

  var params = App.ControllerForm.params(el)
  var test_params = {
    searchable_select1: '',
    searchable_select2: 'bbb',
    searchable_select3: '',
    searchable_select4: 'ccc',
  }
  assert.deepEqual(params, test_params, 'form param check')

  // change selection
  $('[name="searchable_select1"].js-shadow + .js-input').trigger('focus').val('').trigger('input')
  var $element = $('[name="searchable_select1"]').closest('.searchableSelect').find('.js-optionsList')
  var entries = $element.find('li:not(.is-hidden)').length
  assert.equal(entries, 3, 'dropdown count')
  $('[name="searchable_select1"].js-shadow + .js-input').trigger('focus').val('ccc display').trigger('input')
  var entries = $element.find('li:not(.is-hidden)').length
  assert.equal(entries, 1, 'dropdown count')
  $element.find('li:not(.is-hidden)').first().trigger('click')
  params = App.ControllerForm.params(el)
  test_params = {
    searchable_select1: 'ccc',
    searchable_select2: 'bbb',
    searchable_select3: '',
    searchable_select4: 'ccc',
  }
  assert.deepEqual(params, test_params, 'form param check')

  $('[name="searchable_select2"].js-shadow + .js-input').trigger('focus').val('').trigger('input')
  var $element = $('[name="searchable_select2"]').closest('.searchableSelect').find('.js-optionsList')
  var entries = $element.find('li:not(.is-hidden)').length
  assert.equal(entries, 3, 'dropdown count')
  $('[name="searchable_select2"].js-shadow + .js-input').trigger('focus').val('ccc display').trigger('input')
  var entries = $element.find('li:not(.is-hidden)').length
  assert.equal(entries, 1, 'dropdown count')
  $element.find('li:not(.is-hidden)').first().trigger('click')

  params = App.ControllerForm.params(el)
  test_params = {
    searchable_select1: 'ccc',
    searchable_select2: 'ccc',
    searchable_select3: '',
    searchable_select4: 'ccc',
  }
  assert.deepEqual(params, test_params, 'form param check')

  $('[name="searchable_select3"].js-shadow + .js-input').trigger('focus').val('').trigger('input')
  var $element = $('[name="searchable_select3"]').closest('.searchableSelect').find('.js-optionsList')
  var entries = $element.find('li:not(.is-hidden)').length
  assert.equal(entries, 3, 'dropdown count')
  $('[name="searchable_select3"].js-shadow + .js-input').trigger('focus').val('ccc display').trigger('input')
  var entries = $element.find('li:not(.is-hidden)').length
  assert.equal(entries, 1, 'dropdown count')
  $('[name="searchable_select3"].js-shadow + .js-input').trigger('focus').val('unknown value').trigger('input')
  var entries = $element.find('li:not(.is-hidden)').length
  assert.equal(entries, 3, 'dropdown count')
  var entries = $element.find('li.is-active').length
  assert.equal(entries, 0, 'active count')

  var e = $.Event('keydown')
  e.which = 13 //enter
  e.keyCode = 13
  $('[name="searchable_select3"].js-shadow + .js-input').trigger(e)

  params = App.ControllerForm.params(el)
  test_params = {
    searchable_select1: 'ccc',
    searchable_select2: 'ccc',
    searchable_select3: 'unknown value',
    searchable_select4: 'ccc',
  }
  assert.deepEqual(params, test_params, 'form param check')

  $('#forms').append('<hr><h1>searchable_select check for .js-input field values</h1><form id="form2"></form>')
  var el = $('#form2')
  var defaults = {
    searchable_select1: 'ccc::aaa',
    searchable_select2: 'ccc::ccc',
  }
  var options = [
    { value: 'aaa', name: 'aaa display' },
    { value: 'bbb', name: 'bbb display' },
    { value: 'ccc', name: 'ccc display', children: [
      { value: 'ccc::aaa', name: 'aaa display L2' },
      { value: 'ccc::bbb', name: 'bbb display L2' },
      { value: 'ccc::ccc', name: 'ccc display L2' },
    ] },
  ]
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        {
          name:    'searchable_select1',
          display: 'SearchableSelect1',
          tag:     'searchable_select',
          options: options,
          default: defaults['searchable_select1'],
          null:    true,
        },
        {
          name:    'searchable_select2',
          display: 'SearchableSelect2',
          tag:     'searchable_select',
          options: options,
          default: defaults['searchable_select2'],
          null:    true,
        },
      ]
    },
  })

  var params = App.ControllerForm.params(el)
  var test_params = {
    searchable_select1: 'ccc::aaa',
    searchable_select2: 'ccc::ccc',
  }
  assert.deepEqual(params, test_params, 'form param check')
  assert.equal(el.find('[name="searchable_select1"].js-shadow + .js-input').val(), 'aaa display L2', 'verify shown input')
  assert.equal(el.find('[name="searchable_select2"].js-shadow + .js-input').val(), 'ccc display L2', 'verify shown input')

});

QUnit.test("searchable_select submenu and option list check", assert => {
  var done = assert.async()

  $('#forms').append('<hr><h1>searchable_select check for special charaters values</h1><form id="form3"></form>')
  var el = $('#form3')
  var defaults = {
    searchable_select1: 'aaa',
  }
  var options = [
    { value: 'aaa', name: 'aaa display' },
    { value: 'bbb', name: 'bbb display' },
    { value: 'c\\cc', name: 'ccc display', children: [
      { value: 'c\\cc::aaa', name: 'aaa display L2' },
      { value: 'c\\cc::bbb', name: 'bbb display L2' },
      { value: 'c\\cc::ccc', name: 'ccc display L2' },
    ] },
  ]
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        {
          name:    'searchable_select1',
          display: 'SearchableSelect1',
          tag:     'searchable_select',
          options: options,
          default: defaults['searchable_select1'],
          null:    true,
        },
        {
          name:    'searchable_select2',
          display: 'SearchableSelect2',
          tag:     'searchable_select',
          options: options,
          default: defaults['searchable_select1'],
          null:    true,
        },
      ]
    },
  })

  el.find("[name=\"searchable_select2\"].js-shadow + .js-input").trigger('click')
  el.find("div[data-attribute-name=searchable_select2] .js-optionsList [data-value=\"c\\\\cc\"] .searchableSelect-option-text").mouseenter().trigger('click')

  el.find("[name=\"searchable_select1\"].js-shadow + .js-input").trigger('click')
  el.find("div[data-attribute-name=searchable_select1] .js-optionsList [data-value=\"c\\\\cc\"] .searchableSelect-option-arrow").mouseenter().trigger('click')
  el.find("div[data-attribute-name=searchable_select1] .js-optionsSubmenu [data-value=\"c\\\\cc::bbb\"] .searchableSelect-option-text").mouseenter().trigger('click')
  el.find("[name=\"searchable_select1\"].js-shadow + .js-input").trigger('click')

  var params = App.ControllerForm.params(el)
  var test_params = {
    searchable_select1: 'c\\cc::bbb',
    searchable_select2: 'c\\cc',
  }

  var optionsSubmenu = el.find("div[data-attribute-name=searchable_select1] .searchableSelect .js-optionsSubmenu")
  var optionsList = el.find("div[data-attribute-name=searchable_select1] .searchableSelect .js-optionsList")

  setTimeout( () => {
    assert.deepEqual(params, test_params, 'form param check')
    assert.equal(optionsSubmenu.is('[hidden]'), false, 'options submenu menu not hidden')
    assert.equal(optionsList.is('[hidden]'), true, 'options list is hidden')
    done()
  }, 300)
});
