// searchable_select
test( "searchable_select check", function() {

  $('#forms').append('<hr><h1>searchable_select check</h1><form id="form1"></form>')
  var el = $('#form1')
  var defaults = {
    searchable_select2: 'bbb',
  }
  var options = {
    'aaa': 'aaa display',
    'bbb': 'bbb display',
    'ccc': 'ccc display',
  }
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
      ]
    },
    autofocus: true
  })

  var params = App.ControllerForm.params(el)
  var test_params = {
    searchable_select1: '',
    searchable_select2: 'bbb',
    searchable_select3: '',
  }
  deepEqual(params, test_params, 'form param check')

  // change selection
  $('[name="searchable_select1"].js-shadow + .js-input').focus().val('').trigger('input')
  var $element = $('[name="searchable_select1"]').closest('.searchableSelect').find('.js-optionsList')
  var entries = $element.find('li:not(.is-hidden)').length
  equal(entries, 3, 'dropdown count')
  $('[name="searchable_select1"].js-shadow + .js-input').focus().val('ccc display').trigger('input')
  var entries = $element.find('li:not(.is-hidden)').length
  equal(entries, 1, 'dropdown count')
  $element.find('li:not(.is-hidden)').first().click()
  params = App.ControllerForm.params(el)
  test_params = {
    searchable_select1: 'ccc',
    searchable_select2: 'bbb',
    searchable_select3: '',
  }
  deepEqual(params, test_params, 'form param check')

  $('[name="searchable_select2"].js-shadow + .js-input').focus().val('').trigger('input')
  var $element = $('[name="searchable_select2"]').closest('.searchableSelect').find('.js-optionsList')
  var entries = $element.find('li:not(.is-hidden)').length
  equal(entries, 3, 'dropdown count')
  $('[name="searchable_select2"].js-shadow + .js-input').focus().val('ccc display').trigger('input')
  var entries = $element.find('li:not(.is-hidden)').length
  equal(entries, 1, 'dropdown count')
  $element.find('li:not(.is-hidden)').first().click()

  params = App.ControllerForm.params(el)
  test_params = {
    searchable_select1: 'ccc',
    searchable_select2: 'ccc',
    searchable_select3: '',
  }
  deepEqual(params, test_params, 'form param check')

  $('[name="searchable_select3"].js-shadow + .js-input').focus().val('').trigger('input')
  var $element = $('[name="searchable_select3"]').closest('.searchableSelect').find('.js-optionsList')
  var entries = $element.find('li:not(.is-hidden)').length
  equal(entries, 3, 'dropdown count')
  $('[name="searchable_select3"].js-shadow + .js-input').focus().val('ccc display').trigger('input')
  var entries = $element.find('li:not(.is-hidden)').length
  equal(entries, 1, 'dropdown count')
  $('[name="searchable_select3"].js-shadow + .js-input').focus().val('unknown value').trigger('input')
  var entries = $element.find('li:not(.is-hidden)').length
  equal(entries, 3, 'dropdown count')
  var entries = $element.find('li.is-active').length
  equal(entries, 0, 'active count')

  var e = $.Event('keydown')
  e.which = 13 //enter
  e.keyCode = 13
  $('[name="searchable_select3"].js-shadow + .js-input').trigger(e)

  params = App.ControllerForm.params(el)
  test_params = {
    searchable_select1: 'ccc',
    searchable_select2: 'ccc',
    searchable_select3: 'unknown value',
  }
  deepEqual(params, test_params, 'form param check')

});
