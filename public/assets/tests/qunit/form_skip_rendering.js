QUnit.test("form elements not rendered", assert => {
  $('#forms').append('<hr><h1>form elements check</h1><form id="form1"></form>')

  var el = $('#form1')

  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'shown',  display: 'Shown',  tag: 'input' },
        { name: 'hidden', display: 'Hidden', tag: 'input', skipRendering: true }
      ]
    },
    autofocus: true
  });

  assert.ok(el.find('input[name=shown]').get(0), 'control element is visible')
  assert.notOk(el.find('input[name=hidden]').get(0), 'element with skipRendering is not shown')
});
