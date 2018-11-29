
// form
test( "find form check", function() {

  $('#forms').append('<hr><h1>find form check</h1><form id="form1"></form>')
  var form1 = App.ControllerForm.findForm($('#form1'))
  equal(form1.is('form'), true)

  $('#forms').append('<hr><h1>find form check</h1><form id="form2"><input class="js-input" value="test 123"></form>')
  var form2 = App.ControllerForm.findForm($('#form2 .js-input'))
  equal(form2.is('form'), true)

  $('#forms').append('<hr><h1>find form check</h1><form id="form3"><input class="js-input" value="test 123"><button class="js-button">text</button></form>')
  var form3 = App.ControllerForm.findForm($('#form3 .js-button'))
  equal(form3.is('form'), true)
  App.ControllerForm.disable($('#form3 .js-button'))
  equal($('#form3 .js-button').attr('readonly'), 'readonly')
  equal($('#form3 .js-button').attr('disabled'), 'disabled')
  equal($('#form3 .js-input').attr('readonly'), 'readonly')
  equal($('#form3 .js-input').attr('disabled'), undefined)

  App.ControllerForm.enable($('#form3 .js-button'))
  equal($('#form3 .js-button').attr('readonly'), undefined)
  equal($('#form3 .js-button').attr('disabled'), undefined)
  equal($('#form3 .js-input').attr('readonly'), undefined)
  equal($('#form3 .js-input').attr('disabled'), undefined)

  $('#forms').append('<hr><h1>find form check</h1><div id="form4"><input class="js-input" value="test 123"><button class="js-button">text</button></div>')
  var form4 = App.ControllerForm.findForm($('#form4 .js-button'))
  equal(form4.is('form'), false)
  App.ControllerForm.disable($('#form4 .js-button'))
  equal($('#form4 .js-button').attr('readonly'), 'readonly')
  equal($('#form4 .js-button').attr('disabled'), 'disabled')

  App.ControllerForm.enable($('#form4 .js-button'))
  equal($('#form4 .js-input').attr('readonly'), undefined)
  equal($('#form4 .js-input').attr('disabled'), undefined)

});
