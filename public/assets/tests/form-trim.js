
test( 'form trim checks', function() {

  var el = $('#form1')
  var test_params = {
    input1: '',
    input2: '',
    input3: 'a',
    input4: 'a b',
    input5: 'äö  ü',
    textarea1: '',
    textarea2: '',
    textarea3: 'a',
    textarea4: "test\r\n\r\n    123",
    ce1: 'lala',
    ce2: "la\nla",
  }

  el.find('[contenteditable]').ce({
    mode: 'richtext'
  })

  var params = App.ControllerForm.params( el )

  deepEqual( params, test_params, 'form param check' )
  console.log('22', params)
  console.log('22', test_params)
})
