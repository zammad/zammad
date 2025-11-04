// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

/* eslint-disable zammad/zammad-detect-translatable-string */

// First, let's verify that the field type is available
QUnit.test("object_attribute_options_context field type availability", assert => {
  assert.ok(App.UiElement.object_attribute_options_context, 'object_attribute_options_context field type should be available')
  assert.ok(App.UiElement.object_attribute_options_context.render, 'object_attribute_options_context render method should be available')
});

// object_attribute_options_context
QUnit.test("object_attribute_options_context check", assert => {

  $('#forms').append('<hr><h1>object_attribute_options_context check</h1><form id="form1"></form>')
  var el = $('#form1')

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note 1',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         2,
      name:       '2 normal',
      note:       'some note 2',
      active:     true,
      created_at: '2014-06-10T10:17:34.000Z',
    },
    {
      id:         3,
      name:       '3 high',
      note:       'some note 3',
      active:     true,
      created_at: '2014-06-10T10:17:44.000Z',
    },
  ])

  var defaults = {
    object_attribute_options_context1: { '2': '' },
    object_attribute_options_context2: {},
  }

  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        {
          name:    'object_attribute_options_context1',
          display: 'ObjectAttributeOptionsContext1',
          tag:     'object_attribute_options_context',
          object_attribute_object: 'Ticket',
          object_attribute_name: 'priority_id',
          limit_label: 'Limit to selected options',
          table_label: 'Selected Options',
          limit_description: 'When enabled, only selected options will be available',
          default: defaults['object_attribute_options_context1'],
          null:    true,
          show_description: true
        },
        {
          name:    'object_attribute_options_context2',
          display: 'ObjectAttributeOptionsContext2',
          tag:     'object_attribute_options_context',
          object_attribute_object: 'Ticket',
          object_attribute_name: 'priority_id',
          limit_label: 'Limit to selected options',
          table_label: 'Selected Options',
          limit_description: 'When enabled, only selected options will be available',
          default: defaults['object_attribute_options_context2'],
          null:    true
        },
      ]
    },
    autofocus: true
  })

  var params = App.ControllerForm.params(el)
  var test_params = {
    object_attribute_options_context1: { '2': '' },
    object_attribute_options_context2: {},
  }
  assert.deepEqual(params, test_params, 'form param check')

  // Use data-attribute-name selector to find the specific fields
  var $field1 = el.find('[data-attribute-name="object_attribute_options_context1"]')
  var $field2 = el.find('[data-attribute-name="object_attribute_options_context2"]')

  assert.equal($field1.length, 1, 'field1 should be rendered')
  assert.equal($field2.length, 1, 'field2 should be rendered')

  // Check if the hidden inputs exist
  assert.equal($field1.find('.js-objectAttributeOptionsContext').length, 1, 'hidden input should exist in field1')
  assert.equal($field2.find('.js-objectAttributeOptionsContext').length, 1, 'hidden input should exist in field2')

  // Test that the limit toggle is checked when there are selected options
  assert.equal($field1.find('input[type="checkbox"]').is(':checked'), true, 'limit toggle should be checked when options are selected')
  assert.equal($field2.find('input[type="checkbox"]').is(':checked'), false, 'limit toggle should be unchecked when no options are selected')

  // Test that the list container is visible when limit is active
  assert.equal($field1.find('.js-objectAttributeOptionsContextListContainer').hasClass('hide'), false, 'list container should be visible when limit is active')
  assert.equal($field2.find('.js-objectAttributeOptionsContextListContainer').hasClass('hide'), true, 'list container should be hidden when limit is inactive')

  // Test that selected options are displayed in the table
  var $table1 = $field1.find('.js-objectAttributeOptionsContextList')
  assert.equal($table1.find('tr[data-id="2"]').length, 1, 'selected option should be displayed in table')
  assert.equal($table1.find('tr[data-id="2"] td:first-child').text(), '2 normal', 'selected option should show correct display text')

  // Test that description field is rendered when show_description is enabled
  assert.equal($field1.find('textarea.js-description:visible').length, 1, 'description field should be rendered when show_description is enabled')
  assert.equal($field1.find('textarea.js-descriptionNew').length, 1, 'new description field should be rendered when show_description is enabled')

  // Test toggling the limit switch
  $field2.find('input[type="checkbox"]').trigger('click')
  assert.equal($field2.find('.js-objectAttributeOptionsContextListContainer').hasClass('hide'), false, 'list container should be visible after enabling limit')

  // Test that the hidden input is cleared when limit is disabled
  $field2.find('input[type="checkbox"]').trigger('click')
  assert.equal($field2.find('.js-objectAttributeOptionsContextListContainer').hasClass('hide'), true, 'list container should be hidden after disabling limit')
  assert.equal($field2.find('.js-objectAttributeOptionsContext').val(), '{}', 'hidden input should be cleared when limit is disabled')

});

QUnit.test("object_attribute_options_context with relation check", assert => {

  $('#forms').append('<hr><h1>object_attribute_options_context with relation check</h1><form id="form2"></form>')
  var el = $('#form2')

  // Populate Group data
  App.Group.refresh([
    {
      id:        1,
      name_last: 'Users',
      active:    true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         2,
      name_last: 'Support',
      active:    true,
      created_at: '2014-06-10T10:17:34.000Z',
    },
    {
      id:         3,
      name_last: 'Admin',
      active:    true,
      created_at: '2014-06-10T10:17:44.000Z',
    },
  ])

  var defaults = {
    object_attribute_options_context3: { '1': '' },
  }

  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        {
          name:    'object_attribute_options_context3',
          display: 'ObjectAttributeOptionsContext3',
          tag:     'object_attribute_options_context',
          object_attribute_object: 'Ticket',
          object_attribute_name: 'group_id',
          limit_label: 'Limit to selected groups',
          table_label: 'Selected Groups',
          limit_description: 'When enabled, only selected groups will be available',
          default: defaults['object_attribute_options_context3'],
          null:    true
        },
      ]
    },
    autofocus: true
  })

  var params = App.ControllerForm.params(el)
  var test_params = {
    object_attribute_options_context3: { '1': '' },
  }
  assert.deepEqual(params, test_params, 'form param check with relation')

  // Test that the relation-based options are available in the dropdown
  var $field = el.find('[data-attribute-name="object_attribute_options_context3"]')
  var $dropdown = $field.find('.js-shadow')

  // The dropdown should be rendered with relation options
  assert.equal($dropdown.length, 1, 'dropdown should be rendered for relation-based field')

  // Test that selected relation option is displayed correctly
  var $table = $field.find('.js-objectAttributeOptionsContextList')
  assert.equal($table.find('tr[data-id="1"]').length, 1, 'selected relation option should be displayed in table')
  assert.equal($table.find('tr[data-id="1"] td:first-child').text(), 'Users', 'selected relation option should show correct display text')

});

QUnit.test("object_attribute_options_context with tree options check", assert => {

  $('#forms').append('<hr><h1>object_attribute_options_context with tree options check</h1><form id="form3"></form>')
  var el = $('#form3')

  // Populate ObjectManagerAttribute data for category_id with simple tree options
  App.ObjectManagerAttribute.refresh([
    {
      name: 'category_id',
      object: 'Ticket',
      display: 'Category',
      active: true,
      editable: true,
      data_type: 'tree_select',
      options: [
        { name: 'Hardware', value: 'Hardware' },
        { name: 'Software', value: 'Software', children: [
          { name: 'Windows', value: 'Software::Windows' }
        ]}
      ],
      default: '',
      null: true,
      nulloption: true,
      maxlength: 255
    }
  ])

  // Add the category_id attribute to App.Ticket.configure_attributes
  var categoryAttribute = App.ObjectManagerAttribute.findByAttribute('name', 'category_id')
  if (categoryAttribute) {
    App.Ticket.configure_attributes.push(categoryAttribute)
  }

  var defaults = {
    object_attribute_options_context4: { 'Software::Windows': '' },
  }

  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        {
          name:    'object_attribute_options_context4',
          display: 'ObjectAttributeOptionsContext4',
          tag:     'object_attribute_options_context',
          object_attribute_object: 'Ticket',
          object_attribute_name: 'category_id',
          limit_label: 'Limit to selected categories',
          table_label: 'Selected Categories',
          limit_description: 'When enabled, only selected categories will be available',
          default: defaults['object_attribute_options_context4'],
          null:    true
        },
      ]
    },
    autofocus: true
  })

  var params = App.ControllerForm.params(el)
  var test_params = {
    object_attribute_options_context4: { 'Software::Windows': '' },
  }
  assert.deepEqual(params, test_params, 'form param check with tree options')

  // Test that the tree option is displayed correctly (with › separator)
  var $field = el.find('[data-attribute-name="object_attribute_options_context4"]')
  var $table = $field.find('.js-objectAttributeOptionsContextList')

  assert.equal($table.find('tr[data-id="Software::Windows"]').length, 1, 'tree option should be displayed in table')
  assert.equal($table.find('tr[data-id="Software::Windows"] td:first-child').text(), 'Software › Windows', 'tree option should show flattened display text')

});

QUnit.test("object_attribute_options_context with related_object_attribute_selection_name check", assert => {

  $('#forms').append('<hr><h1>object_attribute_options_context with related_object_attribute_selection_name check</h1><form id="form4"></form>')
  var el = $('#form4')

  // Populate TicketPriority data
  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note 1',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
  ])

  var defaults = {
    object_attribute_options_context5: { '2': '' },
  }

  new App.ControllerForm({
    el:        el,
    params:    {
      ticket: {
        priority_field_name: 'priority_id'
      }
    },
    model:     {
      configure_attributes: [
        {
          name:    'object_attribute_options_context5',
          display: 'ObjectAttributeOptionsContext5',
          tag:     'object_attribute_options_context',
          object_attribute_object: 'Ticket',
          related_object_attribute_selection_name: 'ticket::priority_field_name',
          limit_label: 'Limit to selected priorities',
          table_label: 'Selected Priorities',
          limit_description: 'When enabled, only selected priorities will be available',
          default: defaults['object_attribute_options_context5'],
          null:    true
        },
      ]
    },
    autofocus: true
  })

  // Test that the field is rendered correctly
  var $field = el.find('[data-attribute-name="object_attribute_options_context5"]')
  assert.equal($field.length, 1, 'field should be rendered with related_object_attribute_selection_name')

  // Test that the hidden input exists
  assert.equal($field.find('.js-objectAttributeOptionsContext').length, 1, 'hidden input should exist')

});

QUnit.test("object_attribute_options_context with tree selection filter check", assert => {

  $('#forms').append('<hr><h1>object_attribute_options_context with filter check</h1><form id="form5"></form>')
  var el = $('#form5')

  // Populate TicketPriority data
  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note 1',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         2,
      name:       '2 normal',
      note:       'some note 2',
      active:     true,
      created_at: '2014-06-10T10:17:34.000Z',
    },
    {
      id:         3,
      name:       '3 high',
      note:       'some note 3',
      active:     true,
      created_at: '2014-06-10T10:17:44.000Z',
    },
  ])

  var defaults = {
    object_attribute_options_context5: { '2': '' },
  }

  new App.ControllerForm({
    el:        el,
    params:    {
      ticket: {
        priority_field_name: 'priority_id'
      }
    },
    model:     {
      configure_attributes: [
        {
          name:    'object_attribute_options_context5',
          display: 'ObjectAttributeOptionsContext5',
          tag:     'object_attribute_options_context',
          object_attribute_object: 'Ticket',
          related_object_attribute_selection_name: 'ticket::priority_field_name',
          limit_label: 'Limit to selected priorities',
          table_label: 'Selected Priorities',
          limit_description: 'When enabled, only selected priorities will be available',
          default: defaults['object_attribute_options_context5'],
          null:    true
        },
      ]
    },
    autofocus: true
  })

  // Test that the field is rendered correctly
  var $field = el.find('[data-attribute-name="object_attribute_options_context5"]')
  assert.equal($field.length, 1, 'field should be rendered with related_object_attribute_selection_name')

  // Test that selected option is displayed in the table
  var $table = $field.find('.js-objectAttributeOptionsContextList')
  assert.equal($table.find('tr[data-id="2"]').length, 1, 'selected option should be displayed in table')
  assert.equal($table.find('tr[data-id="2"] td:first-child').text(), '2 normal', 'selected option should show correct display text')

  // Test that selected option is not displayed in tree selection
  var $tree = $field.find('.js-objectAttributeOptionsContextItemAddNew .js-optionsList')
  assert.equal($tree.find('.js-option[data-value]').length, 3, 'number of available options in tree selection')
  assert.ok($tree.find('.js-option[data-value="1"]').length, 'not yet chosen option is present in tree selection (1)')
  assert.notOk($tree.find('.js-option[data-value="2"]').length, 'already chosen option is missing in tree selection (2)')
  assert.ok($tree.find('.js-option[data-value="3"]').length, 'not yet chosen option is present in tree selection (3)')
});
