QUnit.test("form SLA times highlights first row and sets 2:00 by default for new item", function(assert) {
  $('#forms').append('<hr><h1>SLA with defaults</h1><form id="form1"></form>')

  var el = $('#form1')

  var item = new App.Sla()

  new App.ControllerForm({
    el:     el,
    model:  item.constructor,
    params: item
  });

  var row = el.find('.sla_times tbody > tr:first')

  assert.ok(row.hasClass('is-active'))
  assert.equal(row.find('input[data-name=first_response_time]').val(), '02:00')

  $('#forms').append('<hr><h1>SLA with empty times</h1><form id="form2"></form>')

  var el = $('#form2')

  var item = new App.Sla()
  item.id = '123'

  new App.ControllerForm({
    el:     el,
    model:  item.constructor,
    params: item
  });

  var row = el.find('.sla_times tbody > tr:first')

  assert.notOk(row.hasClass('is-active'))
  assert.equal(row.find('input[data-name=first_response_time]').val(), '')
});

QUnit.test("form SLA times highlights and shows settings accordingly", function(assert) {
  $('#forms').append('<hr><h1>SLA with non-first time set</h1><form id="form3"></form>')

  var el = $('#form3')

  var item = new App.Sla()
  item.id = '123'
  item.update_time = 240

  new App.ControllerForm({
    el:     el,
    model:  item.constructor,
    params: item
  });

  var firstRow = el.find('.sla_times tbody > tr:first')
  var secondRow = el.find('.sla_times tbody > tr:nth-child(2)')

  assert.notOk(firstRow.hasClass('is-active'))
  assert.equal(firstRow.find('input[data-name=first_response_time]').val(), '')
  assert.ok(secondRow.hasClass('is-active'))
  assert.equal(secondRow.find('input[data-name=update_time]').val(), '04:00')
  assert.equal(secondRow.find('input[name=update_type]:checked').val(), 'update')

  $('#forms').append('<hr><h1>SLA with response time set</h1><form id="form3a"></form>')

  var el = $('#form3a')

  var item = new App.Sla()
  item.id = '123'
  item.response_time = 180

  new App.ControllerForm({
    el:     el,
    model:  item.constructor,
    params: item
  });

  var firstRow = el.find('.sla_times tbody > tr:first')
  var secondRow = el.find('.sla_times tbody > tr:nth-child(2)')

  assert.notOk(firstRow.hasClass('is-active'))
  assert.equal(firstRow.find('input[data-name=first_response_time]').val(), '')
  assert.ok(secondRow.hasClass('is-active'))
  assert.equal(secondRow.find('input[data-name=response_time]').val(), '03:00')
  assert.equal(secondRow.find('input[name=update_type]:checked').val(), 'response')
})

QUnit.test("form SLA times clears field instead of 00:00", function(assert) {
  $('#forms').append('<hr><h1>SLA placeholder instead of 00:00</h1><form id="form5"></form>')

  var el = $('#form5')

  var item = new App.Sla()

  new App.ControllerForm({
    el:     el,
    model:  item.constructor,
    params: item
  });

  var row = el.find('.sla_times tbody > tr:nth-child(2)')
  var input = row.find('input[data-name=update_time]')

  input.val('asd').trigger('blur')

  assert.equal(input.val(), '', 'shows placeholder')
});
