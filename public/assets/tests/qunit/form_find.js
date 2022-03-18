
// form
QUnit.test( "find form check", assert => {

  $('#forms').append('<hr><h1>find form check</h1><form id="form1"></form>')
  var form1 = App.ControllerForm.findForm($('#form1'))
  assert.equal(form1.is('form'), true)

  $('#forms').append('<hr><h1>find form check</h1><form id="form2"><input class="js-input" value="test 123"></form>')
  var form2 = App.ControllerForm.findForm($('#form2 .js-input'))
  assert.equal(form2.is('form'), true)

  $('#forms').append('<hr><h1>find form check</h1><form id="form3"><input class="js-input" value="test 123"><button class="js-button">text</button></form>')
  var form3 = App.ControllerForm.findForm($('#form3 .js-button'))
  assert.equal(form3.is('form'), true)
  App.ControllerForm.disable($('#form3 .js-button'))
  assert.equal($('#form3 .js-button').prop('readonly'), true)
  assert.equal($('#form3 .js-button').prop('disabled'), true)
  assert.equal($('#form3 .js-input').prop('readonly'), true)
  assert.equal($('#form3 .js-input').prop('disabled'), false)

  App.ControllerForm.enable($('#form3 .js-button'))
  assert.equal($('#form3 .js-button').prop('readonly'), false)
  assert.equal($('#form3 .js-button').prop('disabled'), false)
  assert.equal($('#form3 .js-input').prop('readonly'), false)
  assert.equal($('#form3 .js-input').prop('disabled'), false)

  $('#forms').append('<hr><h1>find form check by only disable button</h1><form id="form31"><input class="js-input" value="test 123"><button class="js-button">text</button></form>')
  var form31 = App.ControllerForm.findForm($('#form31 .js-button'))

  App.ControllerForm.disable($('#form31 .js-button'), 'button')

  assert.equal($('#form31 .js-button').prop('readonly'), true)
  assert.equal($('#form31 .js-button').prop('disabled'), true)
  assert.equal($('#form31 .js-input').prop('readonly'), false)
  assert.equal($('#form31 .js-input').prop('disabled'), false)

  App.ControllerForm.enable($('#form31 .js-button'))
  assert.equal($('#form31 .js-button').prop('readonly'), false)
  assert.equal($('#form31 .js-button').prop('disabled'), false)
  assert.equal($('#form31 .js-input').prop('readonly'), false)
  assert.equal($('#form31 .js-input').prop('disabled'), false)

  $('#forms').append('<hr><h1>find form check</h1><div id="form4"><input class="js-input" value="test 123"><button class="js-button">text</button></div>')
  var form4 = App.ControllerForm.findForm($('#form4 .js-button'))
  assert.equal(form4.is('form'), false)
  App.ControllerForm.disable($('#form4 .js-button'))
  assert.equal($('#form4 .js-button').prop('readonly'), true)
  assert.equal($('#form4 .js-button').prop('disabled'), true)
  assert.equal($('#form4 .js-input').prop('readonly'), false)
  assert.equal($('#form4 .js-input').prop('disabled'), false)

  App.ControllerForm.enable($('#form4 .js-button'))
  assert.equal($('#form4 .js-button').prop('readonly'), false)
  assert.equal($('#form4 .js-button').prop('disabled'), false)
  assert.equal($('#form4 .js-input').prop('readonly'), false)
  assert.equal($('#form4 .js-input').prop('disabled'), false)

});
