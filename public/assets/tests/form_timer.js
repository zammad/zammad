
test("form elements check", function() {

  $('#forms').append('<hr><h1>form elements check</h1><form id="form1"></form>')
  var el = $('#form1')
  var defaults = {
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'input1', display: 'Input1', tag: 'input', type: 'text', limit: 100, null: true, default: defaults['input1'] },
        { name: 'timer_params', display: 'Timer', tag: 'timer', null: false, default: defaults['timer_params'] },
      ]
    },
    autofocus: true
  });

  equal('Run every Monday at 00:00', el.find('.js-timerResult').val())

  var params = App.ControllerForm.params(el)
  var test_params = {
    input1: '',
    timer_params: {
      days: {
        'Mon': true,
        'Tue': false,
        'Wed': false,
        'Thu': false,
        'Fri': false,
        'Sat': false,
        'Sun': false,
      },
      hours: {
        0: true,
        1: false,
        2: false,
        3: false,
        4: false,
        5: false,
        6: false,
        7: false,
        8: false,
        9: false,
        10: false,
        11: false,
        12: false,
        13: false,
        14: false,
        15: false,
        16: false,
        17: false,
        18: false,
        19: false,
        20: false,
        21: false,
        22: false,
        23: false,
      },
      minutes: {
        0: true,
        10: false,
        20: false,
        30: false,
        40: false,
        50: false,
      },
    },
  }
  deepEqual(params, test_params, 'form param check')

  $('#forms').append('<hr><h1>form elements check</h1><form id="form2"></form>')
  var el = $('#form2')
  var defaults = {
    input1: '123abc',
    timer_params: {
      days: {
        'Mon': true,
        'Fri': true,
      },
      hours: {
        0: true,
        10: true,
        16: true,
      },
      minutes: {
        0: true,
        10: true,
        50: true,
      },
    },
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'input1', display: 'Input1', tag: 'input', type: 'text', limit: 100, null: true, default: defaults['input1'] },
        { name: 'timer_params', display: 'Timer', tag: 'timer', null: false, default: defaults['timer_params'] },
      ]
    },
    autofocus: true
  });

  equal('Run every Monday and Friday at 00:00, 00:10, 00:50, 10:00, 10:10, 10:50, 16:00, 16:10 and 16:50', el.find('.js-timerResult').val())

  var params = App.ControllerForm.params(el)
  var test_params = {
    input1: '123abc',
    timer_params: {
      days: {
        'Mon': true,
        'Tue': false,
        'Wed': false,
        'Thu': false,
        'Fri': true,
        'Sat': false,
        'Sun': false,
      },
      hours: {
        0: true,
        1: false,
        2: false,
        3: false,
        4: false,
        5: false,
        6: false,
        7: false,
        8: false,
        9: false,
        10: true,
        11: false,
        12: false,
        13: false,
        14: false,
        15: false,
        16: true,
        17: false,
        18: false,
        19: false,
        20: false,
        21: false,
        22: false,
        23: false,
      },
      minutes: {
        0: true,
        10: true,
        20: false,
        30: false,
        40: false,
        50: true,
      },
    },
  }
  deepEqual(params, test_params, 'form param check')

  $('#form2 .js-day [data-value="Sat"]').click()
  $('#form2 .js-hour [data-value="16"]').click()
  $('#form2 .js-minute [data-value="10"]').click()

  equal('Run every Monday, Friday and Saturday at 00:00, 00:50, 10:00 and 10:50', el.find('.js-timerResult').val())

  var params = App.ControllerForm.params(el)
  var test_params = {
    input1: '123abc',
    timer_params: {
      days: {
        'Mon': true,
        'Tue': false,
        'Wed': false,
        'Thu': false,
        'Fri': true,
        'Sat': true,
        'Sun': false,
      },
      hours: {
        0: true,
        1: false,
        2: false,
        3: false,
        4: false,
        5: false,
        6: false,
        7: false,
        8: false,
        9: false,
        10: true,
        11: false,
        12: false,
        13: false,
        14: false,
        15: false,
        16: false,
        17: false,
        18: false,
        19: false,
        20: false,
        21: false,
        22: false,
        23: false,
      },
      minutes: {
        0: true,
        10: false,
        20: false,
        30: false,
        40: false,
        50: true,
      },
    },
  }
  deepEqual(params, test_params, 'form param check')

});