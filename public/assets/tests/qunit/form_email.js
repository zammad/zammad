QUnit.test( "field type email check", assert => {
  $('#forms').append('<hr>' +
      '<h1>field type email check</h1>' +
      '<form id="form1">' +
      '</form>')
  var el = $('#form1')

  new App.ControllerForm({
    el: el,
    model: {
      configure_attributes: [
        {
          name: 'email',
          display: 'Email',
          tag: 'input',
          type: 'email',
          limit: 100,
          null: true
        },
      ]
    },
    autofocus: true
  });

  var input     = el.find('[name="email"]');
  var validator = document.querySelector('input[name="email"]');

  [
    { value: 'acme.corp',                 valid: false },
    { value: 'john.doe',                  valid: false },
    { value: '@acme.corp',                valid: false },
    { value: 'john.doe@',                 valid: false },
    { value: 'john.doe@acme.corp',        valid: true },
    { value: 'john.döe@acme.corp',        valid: true },
    { value: 'john.doe@äcme.corp',        valid: true },
    { value: 'john.döe@äcme.corp',        valid: true },
    { value: 'john.doe@бах.corp',         valid: true },
    { value: 'john.doe@xn--cme-pla.corp', valid: true }
  ].forEach(verify);

  function verify(testee) {
    input.val(testee.value);
    valid = validator.checkValidity()

    assert.equal(testee.valid, valid, testee.value)
  }
});
