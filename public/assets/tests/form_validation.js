test('form validation check', function() {

  $('#forms').append('<hr><h1>form params check</h1><form id="form1"></form>')

  var el       = $('#form1')
  var defaults = {}
  var form     = new App.ControllerForm({
    el:    el,
    model: {
      configure_attributes: [
        { name: 'input1',           display: 'Input1',    tag: 'input', type: 'text', limit: 100, null: false },
        { name: 'password1',        display: 'Password1', tag: 'input', type: 'password', limit: 100, null: false },
        { name: 'textarea1',        display: 'Textarea1', tag: 'textarea', rows: 6, limit: 100, null: false, upload: true },
        { name: 'select1',          display: 'Select1',   tag: 'select', null: false, nulloption: true, options: { true: 'internal', false: 'public' } },
        { name: 'selectmulti1',     display: 'SelectMulti1', tag: 'select', null: false, nulloption: true, multiple: true, options: { true: 'internal', false: 'public' } },
        { name: 'autocompletion1',  display: 'AutoCompletion1', tag: 'autocompletion', null: false, options: { true: 'internal', false: 'public' }, source: [ { label: "Choice1", value: "value1", id: "id1" }, { label: "Choice2", value: "value2", id: "id2" }, ], minLength: 1 },
        { name: 'richtext1',        display: 'Richtext1', tag: 'richtext', maxlength: 100, null: false, type: 'richtext', multiline: true, upload: true, default: defaults['richtext1']  },
        { name: 'datetime1',        display: 'Datetime1', tag: 'datetime', null: false, default: defaults['datetime1']  },
        { name: 'date1',            display: 'Date1',     tag: 'date', null: false, default: defaults['date1']  },
        { name: 'active1',          display: 'Active1',   tag: 'active', default: defaults['active1'] },
      ],
    },
    params: defaults,
  });
  equal(el.find('[name="input1"]').val(), '', 'check input1 value')
  equal(el.find('[name="input1"]').prop('required'), true, 'check input1 required')
//  equal(el.find('[name="input1"]').is(":focus"), true, 'check input1 focus')

  equal(el.find('[name="password1"]').val(), '', 'check password1 value')
  equal(el.find('[name="password1_confirm"]').val(), '', 'check password1 value')
  equal(el.find('[name="password1"]').prop('required'), true, 'check password1 required')

  equal(el.find('[name="textarea1"]').val(), '', 'check textarea1 value')
  equal(el.find('[name="textarea1"]').prop('required'), true, 'check textarea1 required')

  equal(el.find('[name="select1"]').val(), '', 'check select1 value')
  equal(el.find('[name="select1"]').prop('required'), true, 'check select1 required')

  equal(el.find('[name="selectmulti1"]').val(), '', 'check selectmulti1 value')
  equal(el.find('[name="selectmulti1"]').prop('required'), true, 'check selectmulti1 required')

  equal(el.find('[name="autocompletion1"]').val(), '', 'check autocompletion1 value')
  equal(el.find('[name="autocompletion1"]').prop('required'), true, 'check autocompletion1 required')

  equal(el.find('[data-name="richtext1"]').val(), '', 'check richtext1 value')
  //equal(el.find('[data-name="richtext1"]').prop('required'), true, 'check richtext1 required')

  params = App.ControllerForm.params(el)
  errors = form.validate(params)

  test_errors = {
    input1:          'is required',
    password1:       'is required',
    textarea1:       'is required',
    select1:         'is required',
    selectmulti1:    'is required',
    autocompletion1: 'is required',
    richtext1:       'is required',
    datetime1:       'is required',
    date1:           'is required',
  }
  deepEqual(errors, test_errors, 'validation errors check')

  App.ControllerForm.validate({ errors: errors, form: el })

  equal(el.find('[name="input1"]').closest('.form-group').hasClass('has-error'), true, 'check input1 has-error')
  equal(el.find('[name="input1"]').closest('.form-group').find('.help-inline').text(), 'is required', 'check input1 error message')

  equal(el.find('[name="password1"]').closest('.form-group').hasClass('has-error'), true, 'check password1 has-error')
  equal(el.find('[name="password1"]').closest('.form-group').find('.help-inline').text(), 'is required', 'check password1 error message')

  equal(el.find('[name="textarea1"]').closest('.form-group').hasClass('has-error'), true, 'check textarea1 has-error')
  equal(el.find('[name="textarea1"]').closest('.form-group').find('.help-inline').text(), 'is required', 'check textarea1 error message')

  equal(el.find('[name="select1"]').closest('.form-group').hasClass('has-error'), true, 'check select1 has-error')
  equal(el.find('[name="select1"]').closest('.form-group').find('.help-inline').text(), 'is required', 'check select1 error message')

  equal(el.find('[name="selectmulti1"]').closest('.form-group').hasClass('has-error'), true, 'check selectmulti1 has-error')
  equal(el.find('[name="selectmulti1"]').closest('.form-group').find('.help-inline').text(), 'is required', 'check selectmulti1 error message')

  equal(el.find('[name="autocompletion1"]').closest('.form-group').hasClass('has-error'), true, 'check autocompletion1 has-error')
  equal(el.find('[name="autocompletion1"]').closest('.form-group').find('.help-inline').text(), 'is required', 'check autocompletion1 error message')

  equal(el.find('[data-name="richtext1"]').closest('.form-group').hasClass('has-error'), true, 'check richtext1 has-error')
  equal(el.find('[data-name="richtext1"]').closest('.form-group').find('.help-inline').text(), 'is required', 'check richtext1 error message')

  equal(el.find('[data-name="datetime1"]').closest('.form-group').hasClass('has-error'), true, 'check datetime1 has-error')
  equal(el.find('[data-name="datetime1"]').closest('.form-group').find('.help-inline').text(), 'is required', 'check datetime1 error message')

  equal(el.find('[data-name="date1"]').closest('.form-group').hasClass('has-error'), true, 'check date1 has-error')
  equal(el.find('[data-name="date1"]').closest('.form-group').find('.help-inline').text(), 'is required', 'check date1 error message')

});

test('datetime validation check', function() {

  $('#forms').append('<hr><h1>datetime validation check</h1><form id="form2"></form>')

  var el       = $('#form2')
  var defaults = {}
  var form     = new App.ControllerForm({
    el:    el,
    model: {
      configure_attributes: [
        { name: 'datetime1', display: 'Datetime1', tag: 'datetime', null: false, default: defaults['datetime1'] },
      ],
    },
    params: defaults,
  });

  // check params
  params = App.ControllerForm.params(el)
  test_params = {
    datetime1: null,
  }
  deepEqual(params, test_params, 'params check')

  errors = form.validate(params)
  test_errors = {
    datetime1: 'is required',
  }
  deepEqual(errors, test_errors, 'validation errors check')
  App.ControllerForm.validate({ errors: errors, form: el })

  equal(el.find('[data-name="datetime1"]').closest('.form-group').hasClass('has-error'), true, 'check datetime1 has-error')
  equal(el.find('[data-name="datetime1"]').closest('.form-group').find('.help-inline').text(), 'is required', 'check datetime1 error message')
  //equal(el.find('[data-name="datetime1"]').closest('.form-group').find('.help-inline').text(), '', 'check datetime1 error message')

  // set new values
  el.find('[data-name="datetime1"] [data-item="date"]').val('01/01/2015').trigger('blur')
  el.find('[data-name="datetime1"] [data-item="date"]').datepicker('setDate')
  el.find('[data-name="datetime1"] [data-item="time"]').val('12:42').trigger('blur')
  el.find('[data-name="datetime1"] [data-item="time"]').trigger('change')

  // check params
  timeStamp = new Date( Date.parse('2015-01-01T12:42:00.000Z') )
  timeStamp.setMinutes( timeStamp.getMinutes() + timeStamp.getTimezoneOffset() )
  params = App.ControllerForm.params(el)
  test_params = {
    datetime1: timeStamp.toISOString(),
  }
  deepEqual(params, test_params, 'params check')

  // check errors
  errors = form.validate(params)
  test_errors = undefined
  deepEqual(errors, test_errors, 'validation errors check')

  App.ControllerForm.validate({ errors: errors, form: el })
  equal(el.find('[data-name="datetime1"]').closest('.form-group').hasClass('has-error'), false, 'check datetime1 has-error')
  equal(el.find('[data-name="datetime1"]').closest('.form-group').find('.help-inline').text(), '', 'check datetime1 error message')

  el.find('[data-name="datetime1"] [data-item="date"]').val('').trigger('blur')
  el.find('[data-name="datetime1"] [data-item="date"]').datepicker('setDate')
  el.find('[data-name="datetime1"] [data-item="time"]').val('12:42').trigger('blur')
  el.find('[data-name="datetime1"] [data-item="time"]').trigger('change')

  equal(el.find('[data-name="datetime1"]').closest('.form-group').hasClass('has-error'), true )

  params = App.ControllerForm.params(el)
  errors = form.validate(params)
  test_errors = {
    datetime1: 'is required',
  }
  deepEqual(errors, test_errors, 'validation errors check')
  App.ControllerForm.validate({ errors: errors, form: el })

  equal(el.find('[data-name="datetime1"]').closest('.form-group').hasClass('has-error'), true, 'check datetime1 no has-error')
  equal(el.find('[data-name="datetime1"]').closest('.form-group').find('.help-inline').text(), 'is required', 'check datetime1 error message')

});

test('date validation check', function() {

  $('#forms').append('<hr><h1>date validation check</h1><form id="form3"></form>')

  var el       = $('#form3')
  var defaults = {}
  var form     = new App.ControllerForm({
    el:    el,
    model: {
      configure_attributes: [
        { name: 'date2', display: 'Date2', tag: 'date', null: false, default: defaults['time1'] },
      ],
    },
    params: defaults,
  });

  params = App.ControllerForm.params(el)

  // check params
  params = App.ControllerForm.params(el)
  test_params = {
    date2: null,
  }
  deepEqual(params, test_params, 'params check')

  errors = form.validate(params)
  test_errors = {
    date2: 'is required',
  }
  deepEqual(errors, test_errors, 'validation errors check')
  App.ControllerForm.validate({ errors: errors, form: el })

  equal(el.find('[data-name="date2"]').closest('.form-group').hasClass('has-error'), true, 'check date2 has-error')
  equal(el.find('[data-name="date2"]').closest('.form-group').find('.help-inline').text(), 'is required', 'check date2 error message')

  // set new values
  el.find('[data-name="date2"] [data-item="date"]').val('01/01/2015').trigger('blur')
  el.find('[data-name="date2"] [data-item="date"]').datepicker('setDate')
  el.find('[data-name="date2"] [data-item="date"]').trigger('change')

  // check params
  params = App.ControllerForm.params(el)
  test_params = {
    date2: '2015-01-01',
  }
  deepEqual(params, test_params, 'params check')

  // check errors
  errors = form.validate(params)
  test_errors = undefined
  deepEqual(errors, test_errors, 'validation errors check')
  App.ControllerForm.validate({ errors: errors, form: el })
  equal(el.find('[data-name="date2"]').closest('.form-group').hasClass('has-error'), false, 'check date1 has-error')
  equal(el.find('[data-name="date2"]').closest('.form-group').find('.help-inline').text(), '', 'check date1 error message')

  // set invalid values
  el.find('[data-name="date2"] [data-item="date"]').val('').trigger('blur')
  el.find('[data-name="date2"] [data-item="date"]').datepicker('setDate')
  el.find('[data-name="date2"] [data-item="date"]').trigger('change')
  equal(el.find('[data-name="date2"]').closest('.form-group').hasClass('has-error'), true, 'check date2 has-error')

  // check params
  params = App.ControllerForm.params(el)
  test_params = {
    date2: null,
  }
  deepEqual(params, test_params, 'params check')

  // check errors
  errors = form.validate(params)
  test_errors = {
    date2: 'is required',
  }
  deepEqual(errors, test_errors, 'validation errors check')
  App.ControllerForm.validate({ errors: errors, form: el })

  equal(el.find('[data-name="date2"]').closest('.form-group').hasClass('has-error'), true, 'check date2 has-error')
  equal(el.find('[data-name="date2"]').closest('.form-group').find('.help-inline').text(), 'is required', 'check date2 error message')
});

test( "datetime selector check", function() {

  $('#forms').append('<hr><h1>datetime selector check</h1><form id="form4"></form>')

  var el       = $('#form4')
  var defaults = {}
  var form     = new App.ControllerForm({
    el:    el,
    model: {
      configure_attributes: [
        { name: 'datetime1', display: 'Datetime1', tag: 'datetime', null: false, default: defaults['datetime1'] },
        { name: 'datetime2', display: 'Datetime2', tag: 'datetime', null: false, default: defaults['datetime2'] },
      ],
    },
    params: defaults,
  });

  // check params
  params = App.ControllerForm.params(el)
  test_params = {
    datetime1: null,
    datetime2: null,
  }
  deepEqual(params, test_params, 'params check')

  var timeStamp1 = new Date()
  timeStamp1.setMinutes(0)
  timeStamp1.setSeconds(0)
  timeStamp1.setMilliseconds(0)
  timeStamp1.setHours(8)

  el.find('[data-name="datetime1"] .js-datepicker').datepicker('setDate', timeStamp1)
  el.find('[data-name="datetime1"] .js-datepicker').trigger('blur')

  // check params
  params = App.ControllerForm.params(el)
  test_params = {
    datetime1: timeStamp1.toISOString(),
    datetime2: null,
  }
  deepEqual(params, test_params, 'params check')

  el.find('[data-name="datetime1"] .js-timepicker[data-item="time"]').val('9:00')
  el.find('[data-name="datetime1"] .js-timepicker[data-item="time"]').trigger('blur')

  timeStamp1.setHours(9)

  // check params
  params = App.ControllerForm.params(el)
  test_params = {
    datetime1: timeStamp1.toISOString(),
    datetime2: null,
  }
  deepEqual(params, test_params, 'params check')

  var timeStamp2 = new Date()
  timeStamp2.setMinutes(0)
  timeStamp2.setSeconds(0)
  timeStamp2.setMilliseconds(0)
  timeStamp2.setHours(22)

  el.find('[data-name="datetime2"] .js-datepicker').datepicker('setDate', timeStamp2)
  el.find('[data-name="datetime2"] .js-datepicker').trigger('blur')
  el.find('[data-name="datetime2"] .js-timepicker[data-item="time"]').val(timeStamp2.getHours() + ':00')
  el.find('[data-name="datetime2"] .js-timepicker[data-item="time"]').trigger('blur')

  // check params
  params = App.ControllerForm.params(el)
  test_params = {
    datetime1: timeStamp1.toISOString(),
    datetime2: timeStamp2.toISOString(),
  }
  deepEqual(params, test_params, 'params check')

  // Regression test for issue #2173 - Invalid date causes errors
  el.find('[data-name="datetime1"] .js-datepicker').datepicker('setDate', '01/01/99999')
  el.find('[data-name="datetime1"] .js-datepicker').datepicker('setDate', '01/01/1ABCDEFG')
  el.find('[data-name="datetime1"] .js-datepicker').datepicker('setDate', '01/01/1äöüß')
});

test( "date selector check", function() {

  $('#forms').append('<hr><h1>date selector check</h1><form id="form5"></form>')

  var el       = $('#form5')
  var defaults = {}
  var form     = new App.ControllerForm({
    el:    el,
    model: {
      configure_attributes: [
        { name: 'date3', display: 'Datet1', tag: 'date', null: false, default: defaults['date3'] },
      ],
    },
    params: defaults,
  });

  // check params
  params = App.ControllerForm.params(el)
  test_params = {
    date3: null,
  }
  deepEqual(params, test_params, 'params check')

  timeStamp = new Date()

  el.find('.js-datepicker').datepicker('setDate', timeStamp)
  el.find('.js-datepicker').trigger('blur')

  // check params
  format = function (number) {
    if (parseInt(number) < 10 ) {
      number = '0' + number.toString()
    }
    return number
  }

  currentTime = timeStamp.getFullYear() + '-' + format(timeStamp.getMonth()+1) + '-' + format(timeStamp.getDate())
  params = App.ControllerForm.params(el)
  test_params = {
    date3: currentTime,
  }
  deepEqual(params, test_params, 'params check')

});