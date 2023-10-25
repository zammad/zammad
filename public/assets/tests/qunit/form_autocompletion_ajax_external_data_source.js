QUnit.test( "autocompletion_ajax_external_data_source check", assert => {
  var testOptions = [
    {
      value: 1,
      label: 'A',
    },
    {
      value: 2,
      label: 'B',
    },
    {
      value: 3,
      label: 'C',
    },
  ]

  App.ExternalDataSourceAjaxSelect.TEST_SEARCH_RESULT_CACHE = {
    'Ticket+external_data_source2+*': {
      result: testOptions,
    },
    'Ticket+external_data_source2+a': {
      result: testOptions.filter((option) => option.label === 'A'),
    },
    'Ticket+external_data_source2+c': {
      result: testOptions.filter((option) => option.label === 'C'),
    },
    'Ticket+external_data_source4+*': {
      result: testOptions,
    },
  }

  $('#forms').append('<hr><h1>autocompletion_ajax_external_data_source check</h1><form id="form1"></form>')
  var el = $('#form1')
  var defaults = {
    external_data_source1: testOptions.find((option) => option.label === 'B'),
    external_data_source3: testOptions.filter((option) => option.label !== 'B'),
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      className: 'Ticket',
      configure_attributes: [
        {
          name:    'external_data_source1',
          display: 'ExternalDataSource1',
          tag:     'autocompletion_ajax_external_data_source',
          null:    true,
          default: defaults['external_data_source1'],
        },
        {
          name:    'external_data_source2',
          display: 'ExternalDataSource2',
          tag:     'autocompletion_ajax_external_data_source',
          null:    true,
        },
        {
          name:     'external_data_source3',
          display:  'ExternalDataSource3',
          tag:      'autocompletion_ajax_external_data_source',
          null:     true,
          multiple: true,
          default:  defaults['external_data_source3'],
        },
        {
          name:     'external_data_source4',
          display:  'ExternalDataSource4',
          tag:      'autocompletion_ajax_external_data_source',
          null:     true,
          multiple: true,
        },
      ],
    },
    autofocus: true,
  })

  var params = App.ControllerForm.params(el)
  var test_params = {
    external_data_source1: testOptions.find((option) => option.label === 'B'),
    external_data_source2: {},
    external_data_source3: testOptions.filter((option) => option.label !== 'B'),
    external_data_source3_completion: '',
    external_data_source4: [],
    external_data_source4_completion: '',
  }
  assert.deepEqual(params, test_params, 'form param check')

  // Check field state.
  assert.deepEqual(JSON.parse(el.find('[data-name="external_data_source1"] .js-shadow').val()), defaults['external_data_source1'], 'verify shadow value')
  assert.deepEqual(el.find('[data-name="external_data_source1"] .js-input').val(), defaults['external_data_source1'].label, 'verify selected option')
  assert.deepEqual(JSON.parse(el.find('[data-name="external_data_source3"] .js-shadow').val()), defaults['external_data_source3'], 'verify shadow value (multi select)')
  assert.deepEqual(el.find('[data-name="external_data_source3"] .token').length, defaults['external_data_source3'].length, 'verify selected options (multi select)')

  // Check autocomplete search with multiple results.
  var $input = $('[data-name="external_data_source2"] .js-input')
  $input.trigger('focus').val('*').trigger('input')
  var $element = $('[data-name="external_data_source2"]').closest('.searchableSelect').find('.js-optionsList')
  var entries = $element.find('li:not(.is-hidden)').length
  assert.equal(entries, 3, 'dropdown count')

  // Check autocomplete search a single result.
  $input.trigger('focus').val('a').trigger('input')
  entries = $element.find('li:not(.is-hidden)').length
  assert.equal(entries, 1, 'dropdown count')

  // Select option.
  $element.find('li:not(.is-hidden)').first().trigger('click')

  params = App.ControllerForm.params(el)
  test_params = {
    external_data_source1: testOptions.find((option) => option.label === 'B'),
    external_data_source2: testOptions.find((option) => option.label === 'A'),
    external_data_source3: testOptions.filter((option) => option.label !== 'B'),
    external_data_source3_completion: '',
    external_data_source4: [],
    external_data_source4_completion: '',
  }
  assert.deepEqual(params, test_params, 'form param check')

  // Check field state.
  assert.deepEqual(JSON.parse(el.find('[data-name="external_data_source2"] .js-shadow').val()), testOptions.find((option) => option.label === 'A'), 'verify shadow value')
  assert.deepEqual(el.find('[data-name="external_data_source2"] .js-input').val(), 'A', 'verify selected option')

  // Change selection.
  $input.trigger('focus').val('c').trigger('input')
  entries = $element.find('li:not(.is-hidden)').length
  assert.equal(entries, 1, 'dropdown count')
  $element.find('li:not(.is-hidden)').first().trigger('click')

  params = App.ControllerForm.params(el)
  test_params = {
    external_data_source1: testOptions.find((option) => option.label === 'B'),
    external_data_source2: testOptions.find((option) => option.label === 'C'),
    external_data_source3: testOptions.filter((option) => option.label !== 'B'),
    external_data_source3_completion: '',
    external_data_source4: [],
    external_data_source4_completion: '',
  }
  assert.deepEqual(params, test_params, 'form param check')

  // Check field state.
  assert.deepEqual(JSON.parse(el.find('[data-name="external_data_source2"] .js-shadow').val()), testOptions.find((option) => option.label === 'C'), 'verify shadow value')
  assert.deepEqual(el.find('[data-name="external_data_source2"] .js-input').val(), 'C', 'verify selected option')

  // Remove multi selection.
  $('[data-name="external_data_source3"] .token[title="A"] .js-remove').trigger('click')

  params = App.ControllerForm.params(el)
  test_params = {
    external_data_source1: testOptions.find((option) => option.label === 'B'),
    external_data_source2: testOptions.find((option) => option.label === 'C'),
    external_data_source3: testOptions.filter((option) => option.label === 'C'),
    external_data_source3_completion: '',
    external_data_source4: [],
    external_data_source4_completion: '',
  }
  assert.deepEqual(params, test_params, 'form param check')

  // Check field state.
  assert.deepEqual(JSON.parse(el.find('[data-name="external_data_source3"] .js-shadow').val()), testOptions.filter((option) => option.label === 'C'), 'verify shadow value (multi select)')
  assert.deepEqual(el.find('[data-name="external_data_source3"] .token').length, 1, 'verify selected options (multi select)')

  // Set multi selection.
  $input = $('[data-name="external_data_source4"] .js-input')
  $input.trigger('focus').val('*').trigger('input')
  $element = $('[data-name="external_data_source4"]').closest('.searchableSelect').find('.js-optionsList')
  $element.find('li:not(.is-hidden)').trigger('click')

  params = App.ControllerForm.params(el)
  test_params = {
    external_data_source1: testOptions.find((option) => option.label === 'B'),
    external_data_source2: testOptions.find((option) => option.label === 'C'),
    external_data_source3: testOptions.filter((option) => option.label === 'C'),
    external_data_source3_completion: '',
    external_data_source4: testOptions,
    external_data_source4_completion: '',
  }
  assert.deepEqual(params, test_params, 'form param check')

  // Check field state.
  assert.deepEqual(JSON.parse(el.find('[data-name="external_data_source4"] .js-shadow').val()), testOptions, 'verify shadow value (multi select)')
  assert.deepEqual(el.find('[data-name="external_data_source4"] .token').length, testOptions.length, 'verify selected options (multi select)')
})
