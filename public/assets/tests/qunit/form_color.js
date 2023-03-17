QUnit.test("form elements check", assert => {
  var done = assert.async(1)

  $('#forms').append('<hr><h1>form elements check</h1><form id="form1"></form>')

  var el = $('#form1')
  var defaults = {
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'color', display: 'Color', tag: 'color', null: false, default: '#fff' }
      ]
    },
    autofocus: true
  });

  var params = App.ControllerForm.params(el)
  var test_params = {
    color: '#fff'
  }

  assert.deepEqual(params, test_params, 'default param check')

  var inputEl = el.find('.js-input')[0]

  var getSwatchColor = () => { return el.find('.js-swatch').css('background-color') }
  var previousSwatchColor = undefined

  new Promise( (resolve,reject) => {
    syn.click(inputEl).type('[ctrl]+[a]+[backspace]', resolve)
  })
    .then( function() {
      var params = App.ControllerForm.params(el)
      var test_params = {
        color: ''
      }

      assert.deepEqual(params, test_params, 'UI allows color field to be empty')
    })
    .then( function() {
      previousSwatchColor = getSwatchColor()
      return new Promise( (resolve,reject) => {
        syn.click(inputEl).type('rgb(0,100,100)', resolve)
      })
    })
    .then( function() {
      var params = App.ControllerForm.params(el)
      var test_params = {
        color: 'rgb(0,100,100)'
      }

      assert.deepEqual(params, test_params, 'UI allows to type in RGB colors')
      assert.notEqual(previousSwatchColor, getSwatchColor(), 'color in swatch was updated')
    })
    .then( function() {
      var circle = el.find('.js-colorpicker-circle')[0]

      previousSwatchColor = getSwatchColor()
      return new Promise( (resolve,reject) => {
        syn.click(inputEl, resolve)
      })
      .then(function(resolve){
        return new Promise( (resolve, reject) => {
          var square = el.find('.js-colorpicker-saturation-gradient')[0]
          syn.click(square, {}, resolve)
        })
      })
    })
    .then( function() {
      var params = App.ControllerForm.params(el)

      assert.ok(params.color.match(/hsl\(180,(\d{2})%,2\d{1}%\)/), 'Color is transformed to HSL after moving the circle')
      assert.notEqual(previousSwatchColor, getSwatchColor(), 'color in swatch was updated')
    })
    .then( function() {
      var slider = el.find('.js-colorpicker-slider')[0]

      previousSwatchColor = getSwatchColor()
      return new Promise( (resolve,reject) => {
        syn.drag(slider, { to: '-0x-15'}, resolve)
      })
    })
    .then( function() {
      var params = App.ControllerForm.params(el)

      assert.ok(params.color.match(/hsl\(180,(\d{2})%,3\d{1}%\)/), 'Color is changed after moving slider')
      assert.notEqual(previousSwatchColor, getSwatchColor(), 'color in swatch was updated')
    })
    .then( function() {
      let circle = el.find('.js-colorpicker-circle').position()
      let slider = el.find('.js-colorpicker-slider').position()

      previousSwatchColor = getSwatchColor()
      return new Promise( (resolve,reject) => {
        syn.click(inputEl).type('[ctrl]+[a]+[backspace]#ff0000', () => {
          syn.click(inputEl, resolve)
        })
      }).then(function() {
        let new_circle = el.find('.js-colorpicker-circle').position()
        let new_slider = el.find('.js-colorpicker-slider').position()

        assert.notDeepEqual(circle, new_circle, 'Color picker is updated after typing in color')
        assert.notDeepEqual(slider, new_slider, 'Color picker is updated after typing in color')

        assert.notEqual(previousSwatchColor, getSwatchColor(), 'color in swatch was updated')
      })
    })
    .finally(done)
});
