test("form elements check", function(assert) {
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

  deepEqual(params, test_params, 'default param check')

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

      deepEqual(params, test_params, 'UI allows color field to be empty')
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

      deepEqual(params, test_params, 'UI allows to type in RGB colors')
      notEqual(previousSwatchColor, getSwatchColor(), 'color in swatch was updated')
    })
    .then( function() {
      var circle = el.find('.js-colorpicker-circle')[0]

      previousSwatchColor = getSwatchColor()
      return new Promise( (resolve,reject) => {
        syn.click(inputEl).drag(circle, { to: '-10x-10'}, resolve)
      })
    })
    .then( function() {
      var params = App.ControllerForm.params(el)
      var test_params = {
        color: 'hsl(169,100%,20%)'
      }

      deepEqual(params, test_params, 'Color is transformed to HSL after moving the circle')
      notEqual(previousSwatchColor, getSwatchColor(), 'color in swatch was updated')
    })
    .then( function() {
      var slider = el.find('.js-colorpicker-slider')[0]

      previousSwatchColor = getSwatchColor()
      return new Promise( (resolve,reject) => {
        syn.drag(slider, { to: '-0x-10'}, resolve)
      })
    })
    .then( function() {
      var params = App.ControllerForm.params(el)
      var test_params = {
        color: 'hsl(169,100%,27%)'
      }

      deepEqual(params, test_params, 'Color code is changed after draging slider')
      notEqual(previousSwatchColor, getSwatchColor(), 'color in swatch was updated')
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

        notDeepEqual(circle, new_circle, 'Color picker is updated after typing in color')
        notDeepEqual(slider, new_slider, 'Color picker is updated after typing in color')

        notEqual(previousSwatchColor, getSwatchColor(), 'color in swatch was updated')
      })
    })
    .finally(done)
});
