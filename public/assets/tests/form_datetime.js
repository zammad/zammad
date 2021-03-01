test("DateTime timepicker focuses hours", function(assert) {
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

  equal(el.find('[data-name=datetime1] [data-item=date]')[0].disabled, false)
  equal(el.find('[data-name=datetime1] [data-item=time]')[0].disabled, false)
  equal(el.find('[data-name=datetime2] [data-item=date]')[0].disabled, true)
  equal(el.find('[data-name=datetime2] [data-item=time]')[0].disabled, true)
  equal(el.find('[data-name=date3]     [data-item=date]')[0].disabled, true)
});
