test("DateTime timepicker focuses hours", function(assert) {
  var done = assert.async(1)

  var form = $('#forms')

  var el = $('<div></div>').attr('id', 'form1')
  el.appendTo(form)

  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'datetime1', display: 'Datetime1', tag: 'datetime', null: true },
      ]
    },
    autofocus: true
  });

  let timepicker = el.find('[data-item=time]')

  timepicker.focus()

  setTimeout(function(){ // give it time to apply focus
    equal(timepicker[0].selectionStart, 0)
    equal(timepicker[0].selectionEnd, 2)

    done()
  }, 100)
});
