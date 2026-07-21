QUnit.test('audit log diff shows only changed attributes for updates', assert => {
  $('#forms').append('<hr><h1>audit log diff update</h1><form id="form1"></form>')

  var el = $('#form1')

  new App.ControllerForm({
    el: el,
    model: {
      configure_attributes: [
        { name: 'diff', display: 'Changes', tag: 'audit_log_diff', null: true },
      ]
    },
    params: {
      value_from: { firstname: 'Nicole', lastname: 'Braun', active: true },
      value_to:   { firstname: 'Nicki',  lastname: 'Braun', active: true },
    },
    autofocus: false
  });

  assert.equal(el.find('.audit-log-diff-line').length, 2, 'only changed attributes are rendered')
  assert.equal(el.find('.audit-log-diff-line--removed').text(), '-firstname: Nicole', 'removed line shows old value')
  assert.equal(el.find('.audit-log-diff-line--added').text(), '+firstname: Nicki', 'added line shows new value')
});

QUnit.test('audit log diff shows all attributes as added for creates', assert => {
  $('#forms').append('<hr><h1>audit log diff create</h1><form id="form2"></form>')

  var el = $('#form2')

  new App.ControllerForm({
    el: el,
    model: {
      configure_attributes: [
        { name: 'diff', display: 'Changes', tag: 'audit_log_diff', null: true },
      ]
    },
    params: {
      value_from: {},
      value_to:   { firstname: 'Nicole', lastname: 'Braun' },
    },
    autofocus: false
  });

  assert.equal(el.find('.audit-log-diff-line--added').length, 2, 'all attributes are rendered as added')
  assert.equal(el.find('.audit-log-diff-line--removed').length, 0, 'no removed lines are rendered')
});

QUnit.test('audit log diff shows all attributes as removed for destroys', assert => {
  $('#forms').append('<hr><h1>audit log diff destroy</h1><form id="form3"></form>')

  var el = $('#form3')

  new App.ControllerForm({
    el: el,
    model: {
      configure_attributes: [
        { name: 'diff', display: 'Changes', tag: 'audit_log_diff', null: true },
      ]
    },
    params: {
      value_from: { firstname: 'Nicole', lastname: 'Braun' },
      value_to:   {},
    },
    autofocus: false
  });

  assert.equal(el.find('.audit-log-diff-line--removed').length, 2, 'all attributes are rendered as removed')
  assert.equal(el.find('.audit-log-diff-line--added').length, 0, 'no added lines are rendered')
});

QUnit.test('audit log diff stringifies non-string and empty values', assert => {
  $('#forms').append('<hr><h1>audit log diff values</h1><form id="form4"></form>')

  var el = $('#form4')

  new App.ControllerForm({
    el: el,
    model: {
      configure_attributes: [
        { name: 'diff', display: 'Changes', tag: 'audit_log_diff', null: true },
      ]
    },
    params: {
      value_from: { active: true,  note: null, preferences: { vip: false } },
      value_to:   { active: false, note: 'VIP', preferences: { vip: true } },
    },
    autofocus: false
  });

  var removed = el.find('.audit-log-diff-line--removed').map(function() { return $(this).text() }).get()
  var added   = el.find('.audit-log-diff-line--added').map(function() { return $(this).text() }).get()

  assert.deepEqual(removed, ['-active: true', '-note: ', '-preferences: {"vip":false}'], 'non-string values are stringified in removed lines')
  assert.deepEqual(added, ['+active: false', '+note: VIP', '+preferences: {"vip":true}'], 'non-string values are stringified in added lines')
});

QUnit.test('audit log diff shows empty state without changes', assert => {
  $('#forms').append('<hr><h1>audit log diff empty</h1><form id="form5"></form>')

  var el = $('#form5')

  new App.ControllerForm({
    el: el,
    model: {
      configure_attributes: [
        { name: 'diff', display: 'Changes', tag: 'audit_log_diff', null: true },
      ]
    },
    params: {
      value_from: { firstname: 'Nicole' },
      value_to:   { firstname: 'Nicole' },
    },
    autofocus: false
  });

  assert.equal(el.find('.audit-log-diff-line').length, 0, 'no diff lines are rendered')
  assert.equal(el.find('.audit-log-diff-empty').length, 1, 'empty state is rendered')
});

QUnit.test('audit log diff uses changed attributes list when present', assert => {
  $('#forms').append('<hr><h1>audit log diff changed attributes</h1><form id="form6"></form>')

  var el = $('#form6')

  new App.ControllerForm({
    el: el,
    model: {
      configure_attributes: [
        { name: 'diff', display: 'Changes', tag: 'audit_log_diff', null: true },
      ]
    },
    params: {
      value_from:  { password: '**********', firstname: 'Nicole' },
      value_to:    { password: '**********', firstname: 'Nicole' },
      preferences: { changed_attributes: ['password'] },
    },
    autofocus: false
  });

  assert.equal(el.find('.audit-log-diff-line').length, 2, 'only the changed attribute is rendered')
  assert.equal(el.find('.audit-log-diff-line--removed').text(), '-password: **********', 'removed line shows masked old value')
  assert.equal(el.find('.audit-log-diff-line--added').text(), '+password: **********', 'added line shows masked new value')
});

QUnit.test('audit log diff sorts keys case-insensitively', assert => {
  $('#forms').append('<hr><h1>audit log diff key sorting</h1><form id="form7"></form>')

  var el = $('#form7')

  new App.ControllerForm({
    el: el,
    model: {
      configure_attributes: [
        { name: 'diff', display: 'Changes', tag: 'audit_log_diff', null: true },
      ]
    },
    params: {
      value_from: {},
      value_to:   { 'Sales': ['full'], 'admin team': ['read'], 'Backoffice': ['change'] },
    },
    autofocus: false
  });

  var added = el.find('.audit-log-diff-line--added').map(function() { return $(this).text() }).get()

  assert.deepEqual(added, ['+admin team: ["read"]', '+Backoffice: ["change"]', '+Sales: ["full"]'], 'keys are sorted case-insensitively')
});
