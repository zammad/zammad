QUnit.test("core_workflow_condition", assert => {
  var form = $('#forms')

  var el = $('<div></div>').attr('id', 'form1')
  el.appendTo(form)

  form = new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'condition_selected',  display: 'Selected conditions', tag: 'core_workflow_condition', null: true, preview: false },
      ]
    },
    autofocus: true
  });

  assert.equal(el.find('.js-remove.is-disabled').length, 1, 'find disabled button')
  el.find('.js-add').click()
  assert.equal(el.find('.js-remove.is-disabled').length, 0, 'find no disabled button after add')
  el.find('.js-remove').click()
  assert.equal(el.find('.js-remove.is-disabled').length, 1, 'find disabled button after remove')
  assert.equal(typeof(App.ControllerForm.params(el).condition_selected), 'object', 'empty element results in a hash')
  assert.equal(_.isEmpty(App.ControllerForm.params(el).condition_selected), true, 'empty element results are empty')

  el.find('.js-add').click()
  el.find("option[value='ticket.owner_id']").prop('selected', true)
  assert.equal(el.find('.js-preCondition').length, 0, 'pre condition not available')
});

QUnit.test("core_workflow_perform", assert => {
  var form = $('#forms')

  var el = $('<div></div>').attr('id', 'form1')
  el.appendTo(form)

  form = new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'perform',  display: 'Action', tag: 'core_workflow_perform', null: true, preview: false },
      ]
    },
    autofocus: true
  });

  assert.equal(el.find('.js-remove.is-disabled').length, 1, 'find disabled button')
  el.find('.js-add').click()
  assert.equal(el.find('.js-remove.is-disabled').length, 0, 'find no disabled button after add')
  el.find('.js-remove').click()
  assert.equal(el.find('.js-remove.is-disabled').length, 1, 'find disabled button after remove')
  assert.equal(typeof(App.ControllerForm.params(el).perform), 'object', 'empty element results in a hash')
  assert.equal(_.isEmpty(App.ControllerForm.params(el).perform), true, 'empty element results are empty')

  el.find('.js-add').click()
  el.find("option[value='ticket.owner_id']").prop('selected', true)
  assert.equal(el.find('.js-preCondition').length, 0, 'pre condition not available')

  el.find('.js-add:last').click()
  el.find("option[value='ticket.group_id']:last").prop('selected', true)
  el.find('.js-add:last').click()
  el.find("option[value='ticket.group_id']:last").prop('selected', true)
  el.find('.js-add:last').click()
  el.find("option[value='ticket.group_id']:last").prop('selected', true)

  attribute_count = {}
  el.find('.js-attributeSelector select').each(function() {
    attribute_count[$(this).val()] ||= 0
    attribute_count[$(this).val()] += 1
  })
  assert.equal(attribute_count['ticket.group_id'], 3, 'hasDuplicateSelector - its possible to select an attribute multiple times')
});
