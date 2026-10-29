QUnit.test("DateTime timepicker focuses hours", assert => {
  var form = $('#forms')

  var el = $('<div></div>').attr('id', 'form1')
  el.appendTo(form)

  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'datetime1', display: 'Datetime1', tag: 'datetime', null: true },
        { name: 'datetime2', display: 'Datetime2', tag: 'datetime', null: true, disabled: true },
        { name: 'date3',     display: 'Date3',     tag: 'date',     null: true, disabled: true },
      ]
    },
    autofocus: true
  });

  assert.equal(el.find('[data-name=datetime1] [data-item=date]')[0].disabled, false)
  assert.equal(el.find('[data-name=datetime1] [data-item=time]')[0].disabled, false)
  assert.equal(el.find('[data-name=datetime2] [data-item=date]')[0].disabled, true)
  assert.equal(el.find('[data-name=datetime2] [data-item=time]')[0].disabled, true)
  assert.equal(el.find('[data-name=date3]     [data-item=date]')[0].disabled, true)
});

QUnit.test("Date expands a 2-digit year to the nearest year at most 50 years ahead", assert => {
  var form = $('#forms')

  var el = $('<div></div>').attr('id', 'form2')
  el.appendTo(form)

  new App.ControllerForm({
    el:    el,
    model: {
      configure_attributes: [
        { name: 'date1', display: 'Date1', tag: 'date', null: true },
      ]
    },
  });

  var typeDate = year => {
    var input = el.find('[data-name=date1] [data-item=date]')

    input.val('03/15/' + String(year % 100).padStart(2, '0')).trigger('blur')
    input.datepicker('setDate')
    input.trigger('change')
  }

  var currentYear = new Date().getFullYear()

  typeDate(currentYear + 4)
  assert.equal(App.ControllerForm.params(el).date1, (currentYear + 4) + '-03-15', 'current century')

  typeDate(currentYear - 49)
  assert.equal(App.ControllerForm.params(el).date1, (currentYear - 49) + '-03-15', 'previous century')
});
