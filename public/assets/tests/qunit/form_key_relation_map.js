// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

/* eslint-disable zammad/zammad-detect-translatable-string */

QUnit.test("key_relation_map check", assert => {
  $('#forms').append('<hr><h1>key_relation_map check</h1><form id="form1"></form>')
  var el = $('#form1')

  App.Role.refresh([
    { id: 1, name: 'Admin',    active: true, created_at: '2014-06-10T11:17:34.000Z' },
    { id: 2, name: 'Agent',    active: true, created_at: '2014-06-10T11:17:34.000Z' },
    { id: 3, name: 'Customer', active: true, created_at: '2014-06-10T11:17:34.000Z' },
  ])

  new App.ControllerForm({
    el:    el,
    model: {
      configure_attributes: [
        {
          name:             'map',
          display:          'Mapping',
          tag:              'key_relation_map',
          relation:         'Role',
          key_display:      'Value',
          relation_display: 'Roles',
          default:          { 'zammad-agent': [2, 3] },
          null:             true,
        },
      ],
    },
  })

  var field = el.find('[data-attribute-name="map"]')

  assert.deepEqual(App.ControllerForm.params(el), { map: { 'zammad-agent': [2, 3] } }, 'renders the value without leaking the inputs of a row')
  assert.equal(field.find('.js-row').length, 1, 'renders a row per value')
  assert.equal(field.find('.js-row .token').length, 2, 'renders a token per role')
  assert.ok(field.find('.js-empty').hasClass('hide'), 'hides the empty state')

  var addRow = (key, roleIds) => {
    field.find('.js-addRow').trigger('click')

    var row = field.find('.js-row').last()
    row.find('.js-key').val(key)
    roleIds.forEach(roleId => {
      row.find('.js-shadow').append($('<option/>').attr('selected', true).attr('value', roleId))
    })
    row.find('.js-key').trigger('input')
  }

  addRow(' zammad-admin ', [1])
  assert.deepEqual(App.ControllerForm.params(el).map, { 'zammad-agent': [2, 3], 'zammad-admin': [1] }, 'adds a row with a trimmed value')

  addRow('zammad-agent', [1])
  assert.deepEqual(App.ControllerForm.params(el).map, { 'zammad-agent': [2, 3, 1], 'zammad-admin': [1] }, 'merges the roles of duplicate values')

  addRow('', [])
  assert.deepEqual(App.ControllerForm.params(el).map, { 'zammad-agent': [2, 3, 1], 'zammad-admin': [1] }, 'ignores empty rows')

  addRow('zammad-customer', [])
  assert.deepEqual(App.ControllerForm.params(el).map['zammad-customer'], [], 'keeps a value without roles for the validation')

  addRow('hasOwnProperty', [1])
  assert.deepEqual(App.ControllerForm.params(el).map['hasOwnProperty'], [1], 'keeps values named like object properties')

  field.find('.js-row .js-removeRow').each((_index, button) => $(button).trigger('click'))
  assert.deepEqual(App.ControllerForm.params(el).map, {}, 'removes all rows')
  assert.notOk(field.find('.js-empty').hasClass('hide'), 'shows the empty state')
});
