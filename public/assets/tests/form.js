
// form
test( "form elements check", function() {
//    deepEqual( item, test.value, 'group set/get tests' );
  $('#forms').append('<hr><h1>form elements check</h1><form id="form1"></form>')
  var el = $('#form1')
  var defaults = {
    input2: '123abc',
    password2: 'pw1234<l>',
    textarea2: 'lalu <l> lalu',
    select1: false,
    select2: true,
    selectmulti1: false,
    selectmulti2: [ false, true ],
    selectmultioption1: false,
    selectmultioption2: [ false, true ],
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'input1', display: 'Input1', tag: 'input', type: 'text', limit: 100, null: true, default: defaults['input1'] },
        { name: 'input2', display: 'Input2', tag: 'input', type: 'text', limit: 100, null: false, default: defaults['input2'] },
        { name: 'password1', display: 'Password1', tag: 'input', type: 'password', limit: 100, null: true, default: defaults['password1'] },
        { name: 'password2', display: 'Password2', tag: 'input', type: 'password', limit: 100, null: false, default: defaults['password2'] },
        { name: 'textarea1', display: 'Textarea1', tag: 'textarea', rows: 6, limit: 100, null: true, upload: true, default: defaults['textarea1']  },
        { name: 'textarea2', display: 'Textarea2', tag: 'textarea', rows: 6, limit: 100, null: false, upload: true, default: defaults['textarea2']  },
        { name: 'select1', display: 'Select1', tag: 'select', null: true, options: { true: 'internal', false: 'public' }, default: defaults['select1'] },
        { name: 'select2', display: 'Select2', tag: 'select', null: false, options: { true: 'internal', false: 'public' }, default: defaults['select2'] },
        { name: 'selectmulti1', display: 'SelectMulti1', tag: 'select', null: true, multiple: true, options: { true: 'internal', false: 'public' }, default: defaults['selectmulti1'] },
        { name: 'selectmulti2', display: 'SelectMulti2', tag: 'select', null: false, multiple: true, options: { true: 'internal', false: 'public' }, default: defaults['selectmulti2'] },
        { name: 'selectmultioption1', display: 'SelectMultiOption1', tag: 'select', null: true, multiple: true, options: [{ value: true, name: 'internal' }, { value: false, name: 'public' }], default: defaults['selectmultioption1'] },
        { name: 'selectmultioption2', display: 'SelectMultiOption2', tag: 'select', null: false, multiple: true, options: [{ value: true, name: 'A' }, { value: 1, name: 'B'}, { value: false, name: 'C' }], default: defaults['selectmultioption2'] },

      ]
    },
    autofocus: true
  });
  equal( el.find('[name="input1"]').val(), '', 'check input1 value')
  equal( el.find('[name="input1"]').prop('required'), false, 'check input1 required')
//  equal( el.find('[name="input1"]').is(":focus"), true, 'check input1 focus')

  equal( el.find('[name="input2"]').val(), '123abc', 'check input2 value')
  equal( el.find('[name="input2"]').prop('required'), true, 'check input2 required')
  equal( el.find('[name="input2"]').is(":focus"), false, 'check input2 focus')

  equal( el.find('[name="password1"]').val(), '', 'check password1 value')
  equal( el.find('[name="password1_confirm"]').val(), '', 'check password1 value')
  equal( el.find('[name="password1"]').prop('required'), false, 'check password1 required')
  equal( el.find('[name="password1"]').is(":focus"), false, 'check password1 focus')

  equal( el.find('[name="password2"]').val(), 'pw1234<l>', 'check password2 value')
  equal( el.find('[name="password2_confirm"]').val(), 'pw1234<l>', 'check password2 value')
  equal( el.find('[name="password2"]').prop('required'), true, 'check password2 required')
  equal( el.find('[name="password2"]').is(":focus"), false, 'check password2 focus')

  equal( el.find('[name="textarea1"]').val(), '', 'check textarea1 value')
  equal( el.find('[name="textarea1"]').prop('required'), false, 'check textarea1 required')
  equal( el.find('[name="textarea1"]').is(":focus"), false, 'check textarea1 focus')

  equal( el.find('[name="textarea2"]').val(), 'lalu <l> lalu', 'check textarea2 value')
  equal( el.find('[name="textarea2"]').prop('required'), true, 'check textarea2 required')
  equal( el.find('[name="textarea2"]').is(":focus"), false, 'check textarea2 focus')

  equal( el.find('[name="select1"]').val(), 'false', 'check select1 value')
  equal( el.find('[name="select1"]').prop('required'), false, 'check select1 required')
  equal( el.find('[name="select1"]').is(":focus"), false, 'check select1 focus')

  equal( el.find('[name="select2"]').val(), 'true', 'check select2 value')
  equal( el.find('[name="select2"]').prop('required'), true, 'check select2 required')
  equal( el.find('[name="select2"]').is(":focus"), false, 'check select2 focus')

  equal( el.find('[name="selectmulti1"]').val(), 'false', 'check selectmulti1 value')
  equal( el.find('[name="selectmulti1"]').prop('required'), false, 'check selectmulti1 required')
  equal( el.find('[name="selectmulti1"]').is(":focus"), false, 'check selectmulti1 focus')

  equal( el.find('[name="selectmulti2"]').val()[0], 'true', 'check selectmulti2 value')
  equal( el.find('[name="selectmulti2"]').val()[1], 'false', 'check selectmulti2 value')
  equal( el.find('[name="selectmulti2"]').prop('required'), true, 'check selectmulti2 required')
  equal( el.find('[name="selectmulti2"]').is(":focus"), false, 'check selectmulti2 focus')

});

test( "form params check", function() {
//    deepEqual( item, test.value, 'group set/get tests' );

  $('#forms').append('<hr><h1>form params check</h1><form id="form2"></form>')
  var el = $('#form2')
  var defaults = {
    input2: '123abc',
    password2: 'pw1234<l>',
    textarea2: 'lalu <l> lalu',
    select1: false,
    select2: true,
    selectmulti1: false,
    selectmulti2: [ false, true ],
    selectmultioption1: false,
    selectmultioption2: [ false, true ],
    autocompletion2: 'id2',
    autocompletion2_autocompletion_value_shown: 'value2',
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'input1', display: 'Input1', tag: 'input', type: 'text', limit: 100, null: true },
        { name: 'input2', display: 'Input2', tag: 'input', type: 'text', limit: 100, null: false },
        { name: 'password1', display: 'Password1', tag: 'input', type: 'password', limit: 100, null: true },
        { name: 'password2', display: 'Password2', tag: 'input', type: 'password', limit: 100, null: false },
        { name: 'textarea1', display: 'Textarea1', tag: 'textarea', rows: 6, limit: 100, null: true, upload: true },
        { name: 'textarea2', display: 'Textarea2', tag: 'textarea', rows: 6, limit: 100, null: false, upload: true },
        { name: 'select1', display: 'Select1', tag: 'select', null: true, options: { true: 'internal', false: 'public' } },
        { name: 'select2', display: 'Select2', tag: 'select', null: false, options: { true: 'internal', false: 'public' } },
        { name: 'selectmulti1', display: 'SelectMulti1', tag: 'select', null: true, multiple: true, options: { true: 'internal', false: 'public' } },
        { name: 'selectmulti2', display: 'SelectMulti2', tag: 'select', null: false, multiple: true, options: { true: 'internal', false: 'public' } },
        { name: 'selectmultioption1', display: 'SelectMultiOption1', tag: 'select', null: true, multiple: true, options: [{ value: true, name: 'internal' }, { value: false, name: 'public' }] },
        { name: 'selectmultioption2', display: 'SelectMultiOption2', tag: 'select', null: false, multiple: true, options: [{ value: true, name: 'A' }, { value: 1, name: 'B'}, { value: false, name: 'C' }] },
        { name: 'autocompletion1', display: 'AutoCompletion1', tag: 'autocompletion', null: false, options: { true: 'internal', false: 'public' }, source: [ { label: "Choice1", value: "value1", id: "id1" }, { label: "Choice2", value: "value2", id: "id2" }, ], minLength: 1 },
        { name: 'autocompletion2', display: 'AutoCompletion2', tag: 'autocompletion', null: false, options: { true: 'internal', false: 'public' }, source: [ { label: "Choice1", value: "value1", id: "id1" }, { label: "Choice2", value: "value2", id: "id2" }, ], minLength: 1 },
      ],
    },
    params: defaults,
    autofocus: true
  });
  equal( el.find('[name="input1"]').val(), '', 'check input1 value')
  equal( el.find('[name="input1"]').prop('required'), false, 'check input1 required')
//  equal( el.find('[name="input1"]').is(":focus"), true, 'check input1 focus')

  equal( el.find('[name="input2"]').val(), '123abc', 'check input2 value')
  equal( el.find('[name="input2"]').prop('required'), true, 'check input2 required')
  equal( el.find('[name="input2"]').is(":focus"), false, 'check input2 focus')

  equal( el.find('[name="password1"]').val(), '', 'check password1 value')
  equal( el.find('[name="password1_confirm"]').val(), '', 'check password1 value')
  equal( el.find('[name="password1"]').prop('required'), false, 'check password1 required')
  equal( el.find('[name="password1"]').is(":focus"), false, 'check password1 focus')

  equal( el.find('[name="password2"]').val(), 'pw1234<l>', 'check password2 value')
  equal( el.find('[name="password2_confirm"]').val(), 'pw1234<l>', 'check password2 value')
  equal( el.find('[name="password2"]').prop('required'), true, 'check password2 required')
  equal( el.find('[name="password2"]').is(":focus"), false, 'check password2 focus')

  equal( el.find('[name="textarea1"]').val(), '', 'check textarea1 value')
  equal( el.find('[name="textarea1"]').prop('required'), false, 'check textarea1 required')
  equal( el.find('[name="textarea1"]').is(":focus"), false, 'check textarea1 focus')

  equal( el.find('[name="textarea2"]').val(), 'lalu <l> lalu', 'check textarea2 value')
  equal( el.find('[name="textarea2"]').prop('required'), true, 'check textarea2 required')
  equal( el.find('[name="textarea2"]').is(":focus"), false, 'check textarea2 focus')

  equal( el.find('[name="select1"]').val(), 'false', 'check select1 value')
  equal( el.find('[name="select1"]').prop('required'), false, 'check select1 required')
  equal( el.find('[name="select1"]').is(":focus"), false, 'check select1 focus')

  equal( el.find('[name="select2"]').val(), 'true', 'check select2 value')
  equal( el.find('[name="select2"]').prop('required'), true, 'check select2 required')
  equal( el.find('[name="select2"]').is(":focus"), false, 'check select2 focus')

  equal( el.find('[name="selectmulti1"]').val(), 'false', 'check selectmulti1 value')
  equal( el.find('[name="selectmulti1"]').prop('required'), false, 'check selectmulti1 required')
  equal( el.find('[name="selectmulti1"]').is(":focus"), false, 'check selectmulti1 focus')

  equal( el.find('[name="selectmulti2"]').val()[0], 'true', 'check selectmulti2 value')
  equal( el.find('[name="selectmulti2"]').val()[1], 'false', 'check selectmulti2 value')
  equal( el.find('[name="selectmulti2"]').prop('required'), true, 'check selectmulti2 required')
  equal( el.find('[name="selectmulti2"]').is(":focus"), false, 'check selectmulti2 focus')

});

test( "form defaults + params check", function() {
//    deepEqual( item, test.value, 'group set/get tests' );

// mix default and params -> check it -> add note
// test auto completion
// show/hide fields base on field values -> bind changed event
// form validation
// form params check

// add signature only if form_state is empty
  $('#forms').append('<hr><h1>form defaults + params check</h1><form id="form3"></form>')
  var el = $('#form3')
  var defaults = {
    input1: '',
    password2: 'pw1234<l>',
    textarea2: 'lalu <l> lalu',
    select2: false,
    selectmulti2: [ false, true ],
    selectmultioption1: false,
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'input1', display: 'Input1', tag: 'input', type: 'text', limit: 100, null: true, default: 'some not used default' },
        { name: 'input2', display: 'Input2', tag: 'input', type: 'text', limit: 100, null: true, default: 'some used default' },
        { name: 'password1', display: 'Password1', tag: 'input', type: 'password', limit: 100, null: false, default: 'some used pass' },
        { name: 'password2', display: 'Password2', tag: 'input', type: 'password', limit: 100, null: false, default: 'some not used pass' },
        { name: 'textarea1', display: 'Textarea1', tag: 'textarea', rows: 6, limit: 100, null: false, upload: true, default: 'some used text' },
        { name: 'textarea2', display: 'Textarea2', tag: 'textarea', rows: 6, limit: 100, null: false, upload: true, default: 'some not used text' },
        { name: 'select1', display: 'Select1', tag: 'select', null: true, options: { true: 'internal', false: 'public' }, default: false},
        { name: 'select2', display: 'Select2', tag: 'select', null: true, options: { true: 'internal', false: 'public' }, default: true },
        { name: 'selectmulti2', display: 'SelectMulti2', tag: 'select', null: false, multiple: true, options: { true: 'internal', false: 'public' }, default: [] },
        { name: 'selectmultioption1', display: 'SelectMultiOption1', tag: 'select', null: true, multiple: true, options: [{ value: true, name: 'internal' }, { value: false, name: 'public' }], default: true },
      ],
    },
    params: defaults,
    autofocus: true
  });
  equal( el.find('[name="input1"]').val(), '', 'check input1 value')
  equal( el.find('[name="input1"]').prop('required'), false, 'check input1 required')
//  equal( el.find('[name="input1"]').is(":focus"), true, 'check input1 focus')
  equal( el.find('[name="input2"]').val(), 'some used default', 'check input2 value')
  equal( el.find('[name="input2"]').prop('required'), false, 'check input2 required')

  equal( el.find('[name="password1"]').val(), 'some used pass', 'check password1 value')
  equal( el.find('[name="password1_confirm"]').val(), 'some used pass', 'check password1 value')
  equal( el.find('[name="password1"]').prop('required'), true, 'check password1 required')
  equal( el.find('[name="password1"]').is(":focus"), false, 'check password1 focus')

  equal( el.find('[name="password2"]').val(), 'pw1234<l>', 'check password2 value')
  equal( el.find('[name="password2_confirm"]').val(), 'pw1234<l>', 'check password2 value')
  equal( el.find('[name="password2"]').prop('required'), true, 'check password2 required')
  equal( el.find('[name="password2"]').is(":focus"), false, 'check password2 focus')

  equal( el.find('[name="textarea1"]').val(), 'some used text', 'check textarea1 value')
  equal( el.find('[name="textarea1"]').prop('required'), true, 'check textarea1 required')
  equal( el.find('[name="textarea1"]').is(":focus"), false, 'check textarea1 focus')

  equal( el.find('[name="textarea2"]').val(), 'lalu <l> lalu', 'check textarea2 value')
  equal( el.find('[name="textarea2"]').prop('required'), true, 'check textarea2 required')
  equal( el.find('[name="textarea2"]').is(":focus"), false, 'check textarea2 focus')

  equal( el.find('[name="select1"]').val(), 'false', 'check select1 value')
  equal( el.find('[name="select1"]').prop('required'), false, 'check select1 required')
  equal( el.find('[name="select1"]').is(":focus"), false, 'check select1 focus')

  equal( el.find('[name="select2"]').val(), 'false', 'check select2 value')
  equal( el.find('[name="select2"]').prop('required'), false, 'check select2 required')
  equal( el.find('[name="select2"]').is(":focus"), false, 'check select2 focus')

  equal( el.find('[name="selectmulti2"]').val()[0], 'true', 'check selectmulti2 value')
  equal( el.find('[name="selectmulti2"]').val()[1], 'false', 'check selectmulti2 value')
  equal( el.find('[name="selectmulti2"]').prop('required'), true, 'check selectmulti2 required')
  equal( el.find('[name="selectmulti2"]').is(":focus"), false, 'check selectmulti2 focus')

});

test( "form dependend fields check", function() {
//    deepEqual( item, test.value, 'group set/get tests' );

// mix default and params -> check it -> add note
// test auto completion
// show/hide fields base on field values -> bind changed event
// form validation
// form params check

// add signature only if form_state is empty
  $('#forms').append('<hr><h1>form dependend fields check</h1><form id="form4"></form>')
  var el = $('#form4')
  var defaults = {
    input1: '',
    select2: false,
    selectmulti2: [ false, true ],
    selectmultioption1: false,
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'input1', display: 'Input1', tag: 'input', type: 'text', limit: 100, null: true, default: 'some not used default' },
        { name: 'input2', display: 'Input2', tag: 'input', type: 'text', limit: 100, null: true, default: 'some used default' },
        { name: 'input3', display: 'Input3', tag: 'input', type: 'text', limit: 100, null: true, hide: true, default: 'some used default' },
        { name: 'select1', display: 'Select1', tag: 'select', null: true, options: { true: 'internal', false: 'public' }, default: false},
        { name: 'select2', display: 'Select2', tag: 'select', null: true, options: { true: 'internal', false: 'public' }, default: true },
        { name: 'selectmulti2', display: 'SelectMulti2', tag: 'select', null: false, multiple: true, options: { true: 'internal', false: 'public' }, default: [] },
        { name: 'selectmultioption1', display: 'SelectMultiOption1', tag: 'select', null: true, multiple: true, options: [{ value: true, name: 'internal' }, { value: false, name: 'public' }], default: true },
      ],
    },
    params: defaults,
    dependency: [
      {
        bind: {
          name: 'select1',
          value: ["true"]
        },
        change: {
          name: 'input2',
          action: 'hide'
        },
      },
      {
        bind: {
          name: 'select1',
          value: ["false"]
        },
        change: {
          name: 'input2',
          action: 'show'
        },
      },
      {
        bind: {
          name: 'select1',
          value: ["true"]
        },
        change: {
          name: 'input3',
          action: 'show'
        },
      },
      {
        bind: {
          name: 'select1',
          value: ["false"]
        },
        change: {
          name: 'input3',
          action: 'hide'
        },
      }
    ],
    autofocus: true
  });
  equal( el.find('[name="input1"]').val(), '', 'check input1 value')
  equal( el.find('[name="input1"]').prop('required'), false, 'check input1 required')
//  equal( el.find('[name="input1"]').is(":focus"), true, 'check input1 focus')
  equal( el.find('[name="input2"]').val(), 'some used default', 'check input2 value')
  equal( el.find('[name="input2"]').prop('required'), false, 'check input2 required')

  equal( el.find('[name="input3"]').val(), 'some used default', 'check input3 value')
  equal( el.find('[name="input3"]').prop('required'), false, 'check input3 required')

  equal( el.find('[name="select1"]').val(), 'false', 'check select1 value')
  equal( el.find('[name="select1"]').prop('required'), false, 'check select1 required')
  equal( el.find('[name="select1"]').is(":focus"), false, 'check select1 focus')

  equal( el.find('[name="select2"]').val(), 'false', 'check select2 value')
  equal( el.find('[name="select2"]').prop('required'), false, 'check select2 required')
  equal( el.find('[name="select2"]').is(":focus"), false, 'check select2 focus')

  equal( el.find('[name="selectmulti2"]').val()[0], 'true', 'check selectmulti2 value')
  equal( el.find('[name="selectmulti2"]').val()[1], 'false', 'check selectmulti2 value')
  equal( el.find('[name="selectmulti2"]').prop('required'), true, 'check selectmulti2 required')
  equal( el.find('[name="selectmulti2"]').is(":focus"), false, 'check selectmulti2 focus')

  var params = App.ControllerForm.params( el )
  var test_params = {
    input1: "",
    input2: "some used default",
    select1: "false",
    select2: "false",
    selectmulti2: [ "true", "false" ],
    selectmultioption1: "false"
  }
  deepEqual( params, test_params, 'form param check' );
  el.find('[name="select1"]').val('true')
  el.find('[name="select1"]').trigger('change')
  params = App.ControllerForm.params( el )
  test_params = {
    input1: "",
    input3: "some used default",
    select1: "true",
    select2: "false",
    selectmulti2: [ "true", "false" ],
    selectmultioption1: "false"
  }
  deepEqual( params, test_params, 'form param check' );
});

