
// form
test("form without @el", function() {
  var form = new App.ControllerForm()

  equal($(form.html()).is('div'), true)
  equal($(form.html()).hasClass('alert'), true)
  equal($(form.html()).hasClass('hide'), true)

})
test("form elements check", function() {
//    deepEqual(item, test.value, 'group set/get tests' );
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
    richtext2: 'lalu <l> lalu',
    datetime1: Date.parse('2015-01-11T12:40:00Z'),
    checkbox1: [],
    checkbox2: '1',
    boolean1: true,
    boolean2: false,
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'input1', display: 'Input1', tag: 'input', type: 'text', limit: 100, null: true, default: defaults['input1'] },
        { name: 'input2', display: 'Input2', tag: 'input', type: 'text', limit: 100, null: false, default: defaults['input2'] },
        { name: 'password1', display: 'Password1', tag: 'input', type: 'password', limit: 100, null: true, default: defaults['password1'] },
        { name: 'password2', display: 'Password2', tag: 'input', type: 'password', limit: 100, null: false, default: defaults['password2'] },
        { name: 'textarea1', display: 'Textarea1', tag: 'textarea', rows: 6, limit: 100, null: true, upload: true, default: defaults['textarea1'] },
        { name: 'textarea2', display: 'Textarea2', tag: 'textarea', rows: 6, limit: 100, null: false, upload: true, default: defaults['textarea2'] },
        { name: 'select1', display: 'Select1', tag: 'select', null: true, options: { true: 'internal', false: 'public' }, default: defaults['select1'] },
        { name: 'select2', display: 'Select2', tag: 'select', null: false, options: { true: 'internal', false: 'public' }, default: defaults['select2'] },
        { name: 'selectmulti1', display: 'SelectMulti1', tag: 'select', null: true, multiple: true, options: { true: 'internal', false: 'public' }, default: defaults['selectmulti1'] },
        { name: 'selectmulti2', display: 'SelectMulti2', tag: 'select', null: false, multiple: true, options: { true: 'internal', false: 'public' }, default: defaults['selectmulti2'] },
        { name: 'selectmultioption1', display: 'SelectMultiOption1', tag: 'select', null: true, multiple: true, options: [{ value: true, name: 'internal' }, { value: false, name: 'public' }], default: defaults['selectmultioption1'] },
        { name: 'selectmultioption2', display: 'SelectMultiOption2', tag: 'select', null: false, multiple: true, options: [{ value: true, name: 'A' }, { value: 1, name: 'B'}, { value: false, name: 'C' }], default: defaults['selectmultioption2'] },
        { name: 'richtext1', display: 'Richtext1', tag: 'richtext', limit: 100, null: true, upload: true, default: defaults['richtext1'] },
        { name: 'richtext2', display: 'Richtext2', tag: 'richtext', limit: 100, null: true, upload: true, default: defaults['richtext2'] },
        { name: 'datetime1', display: 'Datetime1', tag: 'datetime', null: true, default: defaults['datetime1'] },
        { name: 'datetime2', display: 'Datetime2', tag: 'datetime', null: false, default: defaults['datetime2'] },
        { name: 'checkbox1', display: 'Checkbox1', tag: 'checkbox', null: false, default: defaults['checkbox1'], options: { a: 'AA', b: 'BB' } },
        { name: 'checkbox2', display: 'Checkbox2', tag: 'checkbox', null: false, default: defaults['checkbox2'], options: { 1: '11' } },
        { name: 'boolean1',  display: 'Boolean1',  tag: 'boolean',  null: false, default: defaults['boolean1'] },
        { name: 'boolean2',  display: 'Boolean2',  tag: 'boolean',  null: false, default: defaults['boolean2'] },
        { name: 'boolean3',  display: 'Boolean3',  tag: 'boolean',  null: false, default: defaults['boolean3'] },
      ]
    },
    autofocus: true
  });
  equal(el.find('[name="input1"]').val(), '', 'check input1 value')
  equal(el.find('[name="input1"]').prop('required'), false, 'check input1 required')
//  equal(el.find('[name="input1"]').is(":focus"), true, 'check input1 focus')

  equal(el.find('[name="input2"]').val(), '123abc', 'check input2 value')
  equal(el.find('[name="input2"]').prop('required'), true, 'check input2 required')
  equal(el.find('[name="input2"]').is(":focus"), false, 'check input2 focus')

  equal(el.find('[name="password1"]').val(), '', 'check password1 value')
  equal(el.find('[name="password1_confirm"]').val(), '', 'check password1 value')
  equal(el.find('[name="password1"]').prop('required'), false, 'check password1 required')
  equal(el.find('[name="password1"]').is(":focus"), false, 'check password1 focus')

  equal(el.find('[name="password2"]').val(), 'pw1234<l>', 'check password2 value')
  equal(el.find('[name="password2_confirm"]').val(), 'pw1234<l>', 'check password2 value')
  equal(el.find('[name="password2"]').prop('required'), true, 'check password2 required')
  equal(el.find('[name="password2"]').is(":focus"), false, 'check password2 focus')

  equal(el.find('[name="textarea1"]').val(), '', 'check textarea1 value')
  equal(el.find('[name="textarea1"]').prop('required'), false, 'check textarea1 required')
  equal(el.find('[name="textarea1"]').is(":focus"), false, 'check textarea1 focus')

  equal(el.find('[name="textarea2"]').val(), 'lalu <l> lalu', 'check textarea2 value')
  equal(el.find('[name="textarea2"]').prop('required'), true, 'check textarea2 required')
  equal(el.find('[name="textarea2"]').is(":focus"), false, 'check textarea2 focus')

  equal(el.find('[name="select1"]').val(), 'false', 'check select1 value')
  equal(el.find('[name="select1"]').prop('required'), false, 'check select1 required')
  equal(el.find('[name="select1"]').is(":focus"), false, 'check select1 focus')

  equal(el.find('[name="select2"]').val(), 'true', 'check select2 value')
  equal(el.find('[name="select2"]').prop('required'), true, 'check select2 required')
  equal(el.find('[name="select2"]').is(":focus"), false, 'check select2 focus')

  equal(el.find('[name="selectmulti1"]').val(), 'false', 'check selectmulti1 value')
  equal(el.find('[name="selectmulti1"]').prop('required'), false, 'check selectmulti1 required')
  equal(el.find('[name="selectmulti1"]').is(":focus"), false, 'check selectmulti1 focus')

  equal(el.find('[name="selectmulti2"]').val()[0], 'true', 'check selectmulti2 value')
  equal(el.find('[name="selectmulti2"]').val()[1], 'false', 'check selectmulti2 value')
  equal(el.find('[name="selectmulti2"]').prop('required'), true, 'check selectmulti2 required')
  equal(el.find('[name="selectmulti2"]').is(":focus"), false, 'check selectmulti2 focus')

  //equal(el.find('[name="richtext1"]').val(), '', 'check textarea1 value')
  //equal(el.find('[name="richtext1"]').prop('required'), false, 'check textarea1 required')
  equal(el.find('[name="richtext1"]').is(":focus"), false, 'check textarea1 focus')

  //equal(el.find('[name="richtext2"]').val(), 'lalu <l> lalu', 'check textarea2 value')
  //equal(el.find('[name="richtext2"]').prop('required'), true, 'check textarea2 required')
  equal(el.find('[name="richtext2"]').is(":focus"), false, 'check textarea2 focus')

  equal(el.find('[name="checkbox1"]').first().is(":checked"), false)
  equal(el.find('[name="checkbox1"]').last().is(":checked"), false)
  equal(el.find('[name="checkbox2"]').is(":checked"), true)

  equal(el.find('[name="boolean1"]').val(), 'true')
  equal(el.find('[name="boolean1"]').val(), 'true')
  equal(el.find('[name="boolean2"]').val(), 'false')
});

test("form params check", function() {
//    deepEqual(item, test.value, 'group set/get tests' );

  $('#forms').append('<hr><h1>form params check</h1><form id="form2"></form>')
  var el = $('#form2')
  var defaults = {
    input2: '123abc',
    password2: 'pw1234<l>',
    textarea2: 'lalu <l> lalu',
    select1: false,
    select2: true,
    select3: null,
    select4: undefined,
    selectmulti1: false,
    selectmulti2: [ false, true ],
    selectmultioption1: false,
    selectmultioption2: [ false, true ],
    autocompletion2: 'id2',
    autocompletion2_autocompletion_value_shown: 'value2',
    richtext2: '<div>lalu <b>b</b> lalu</div>',
    richtext3: '<div></div>',
    richtext4: '<div>lalu <i>b</i> lalu</div>',
    richtext5: '<div></div>',
    richtext6: '<div>lalu <b>b</b> lalu</div>',
    richtext7: "<div>&nbsp;<div>&nbsp;\n</div>  \n</div>",
    richtext8: '<div>lalu <i>b</i> lalu</div>',
    datetime1: new Date(Date.parse('2015-01-11T12:40:00Z') ),
    datetime3: new Date(Date.parse('2015-01-11T12:40:00Z') ),
    date1:     '2015-01-11',
    date3:     '2015-01-11',
    active1:   true,
    active2:   false,
    checkbox1: [],
    checkbox2: undefined,
    checkbox3: 'd',
    radiobox1: undefined,
    radiobox2: 'a',
    boolean1:  true,
    boolean2:  false,
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
        { name: 'select3', display: 'Select3', tag: 'select', null: false, nulloption: true, options: { aa: 'aa', bb: 'bb', select3: 'select3' } },
        { name: 'select4', display: 'Select4', tag: 'select', null: false, nulloption: true,  options: { aa: 'aa', bb: 'bb', select3: 'select4' } },
        { name: 'selectmulti1', display: 'SelectMulti1', tag: 'select', null: true, multiple: true, options: { true: 'internal', false: 'public' } },
        { name: 'selectmulti2', display: 'SelectMulti2', tag: 'select', null: false, multiple: true, options: { true: 'internal', false: 'public' } },
        { name: 'selectmultioption1', display: 'SelectMultiOption1', tag: 'select', null: true, multiple: true, options: [{ value: true, name: 'internal' }, { value: false, name: 'public' }] },
        { name: 'selectmultioption2', display: 'SelectMultiOption2', tag: 'select', null: false, multiple: true, options: [{ value: true, name: 'A' }, { value: 1, name: 'B'}, { value: false, name: 'C' }] },
        { name: 'autocompletion1', display: 'AutoCompletion1', tag: 'autocompletion', null: false, options: { true: 'internal', false: 'public' }, source: [ { label: "Choice1", value: "value1", id: "id1" }, { label: "Choice2", value: "value2", id: "id2" }, ], minLength: 1 },
        { name: 'autocompletion2', display: 'AutoCompletion2', tag: 'autocompletion', null: false, options: { true: 'internal', false: 'public' }, source: [ { label: "Choice1", value: "value1", id: "id1" }, { label: "Choice2", value: "value2", id: "id2" }, ], minLength: 1 },
        { name: 'richtext1', display: 'Richtext1', tag: 'richtext', maxlength: 100, null: true, type: 'richtext', multiline: true, upload: true, default: defaults['richtext1'] },
        { name: 'richtext2', display: 'Richtext2', tag: 'richtext', maxlength: 100, null: true, type: 'richtext', multiline: true, upload: true, default: defaults['richtext2'] },
        { name: 'richtext3', display: 'Richtext3', tag: 'richtext', maxlength: 100, null: true, type: 'richtext', multiline: false, default: defaults['richtext3'] },
        { name: 'richtext4', display: 'Richtext4', tag: 'richtext', maxlength: 100, null: true, type: 'richtext', multiline: false, default: defaults['richtext4'] },
        { name: 'richtext5', display: 'Richtext5', tag: 'richtext', maxlength: 100, null: true, type: 'textonly', multiline: true, upload: true, default: defaults['richtext5'] },
        { name: 'richtext6', display: 'Richtext6', tag: 'richtext', maxlength: 100, null: true, type: 'textonly', multiline: true, upload: true, default: defaults['richtext6'] },
        { name: 'richtext7', display: 'Richtext7', tag: 'richtext', maxlength: 100, null: true, type: 'textonly', multiline: false, default: defaults['richtext7'] },
        { name: 'richtext8', display: 'Richtext8', tag: 'richtext', maxlength: 100, null: true, type: 'textonly', multiline: false, default: defaults['richtext8'] },
        { name: 'datetime1', display: 'Datetime1', tag: 'datetime', null: true, default: defaults['datetime1'] },
        { name: 'datetime2', display: 'Datetime2', tag: 'datetime', null: true, default: defaults['datetime2'] },
        { name: 'datetime3', display: 'Datetime3', tag: 'datetime', null: false, default: defaults['datetime3'] },
        { name: 'datetime4', display: 'Datetime4', tag: 'datetime', null: false, default: defaults['datetime4'] },
        { name: 'date1',     display: 'Date1',     tag: 'date', null: true, default: defaults['date1'] },
        { name: 'date2',     display: 'Date2',     tag: 'date', null: true, default: defaults['date2'] },
        { name: 'date3',     display: 'Date3',     tag: 'date', null: false, default: defaults['date3'] },
        { name: 'date4',     display: 'Date4',     tag: 'date', null: false, default: defaults['date4'] },
        { name: 'active1',   display: 'Active1',   tag: 'active', default: defaults['active1'] },
        { name: 'active2',   display: 'Active2',   tag: 'active', default: defaults['active2'] },
        { name: 'checkbox1', display: 'Checkbox1', tag: 'checkbox', null: false, default: defaults['checkbox1'], options: { a: 'AA', b: 'BB' } },
        { name: 'checkbox2', display: 'Checkbox2', tag: 'checkbox', null: false, default: defaults['checkbox2'], options: { 1: '11' } },
        { name: 'checkbox3', display: 'Checkbox3', tag: 'checkbox', null: false, default: defaults['checkbox3'], options: { c: 'CC', d: 'DD' } },
        { name: 'checkbox4', display: 'Checkbox4', tag: 'checkbox', null: false, default: defaults['checkbox4'], options: { aa: 'AA', bb: 'BB' } },
        { name: 'radiobox1', display: 'Radiobox1', tag: 'radio', null: false, default: defaults['radiobox1'], options: { a: 'AA', b: 'BB' } },
        { name: 'radiobox2', display: 'Radiobox2', tag: 'radio', null: false, default: defaults['radiobox2'], options: { a: '11' } },
        { name: 'boolean1',  display: 'Boolean1',  tag: 'boolean',  null: false, default: defaults['boolean1'] },
        { name: 'boolean2',  display: 'Boolean2',  tag: 'boolean',  null: false, default: defaults['boolean2'] },
        { name: 'boolean3',  display: 'Boolean3',  tag: 'boolean',  null: false, default: defaults['boolean3'] },
      ],
    },
    params: defaults,
    autofocus: true
  });
  equal(el.find('[name="input1"]').val(), '', 'check input1 value')
  equal(el.find('[name="input1"]').prop('required'), false, 'check input1 required')
//  equal(el.find('[name="input1"]').is(":focus"), true, 'check input1 focus')

  equal(el.find('[name="input2"]').val(), '123abc', 'check input2 value')
  equal(el.find('[name="input2"]').prop('required'), true, 'check input2 required')
  equal(el.find('[name="input2"]').is(":focus"), false, 'check input2 focus')

  equal(el.find('[name="password1"]').val(), '', 'check password1 value')
  equal(el.find('[name="password1_confirm"]').val(), '', 'check password1 value')
  equal(el.find('[name="password1"]').prop('required'), false, 'check password1 required')
  equal(el.find('[name="password1"]').is(":focus"), false, 'check password1 focus')

  equal(el.find('[name="password2"]').val(), 'pw1234<l>', 'check password2 value')
  equal(el.find('[name="password2_confirm"]').val(), 'pw1234<l>', 'check password2 value')
  equal(el.find('[name="password2"]').prop('required'), true, 'check password2 required')
  equal(el.find('[name="password2"]').is(":focus"), false, 'check password2 focus')

  equal(el.find('[name="textarea1"]').val(), '', 'check textarea1 value')
  equal(el.find('[name="textarea1"]').prop('required'), false, 'check textarea1 required')
  equal(el.find('[name="textarea1"]').is(":focus"), false, 'check textarea1 focus')

  equal(el.find('[name="textarea2"]').val(), 'lalu <l> lalu', 'check textarea2 value')
  equal(el.find('[name="textarea2"]').prop('required'), true, 'check textarea2 required')
  equal(el.find('[name="textarea2"]').is(":focus"), false, 'check textarea2 focus')

  equal(el.find('[name="select1"]').val(), 'false', 'check select1 value')
  equal(el.find('[name="select1"]').prop('required'), false, 'check select1 required')
  equal(el.find('[name="select1"]').is(":focus"), false, 'check select1 focus')

  equal(el.find('[name="select2"]').val(), 'true', 'check select2 value')
  equal(el.find('[name="select2"]').prop('required'), true, 'check select2 required')
  equal(el.find('[name="select2"]').is(":focus"), false, 'check select2 focus')

  equal(el.find('[name="select3"]').val(), '', 'check select3 value')
  equal(el.find('[name="select3"]').prop('required'), true, 'check select3 required')
  equal(el.find('[name="select3"]').is(":focus"), false, 'check select3 focus')

  equal(el.find('[name="select4"]').val(), '', 'check select4 value')
  equal(el.find('[name="select4"]').prop('required'), true, 'check select4 required')
  equal(el.find('[name="select4"]').is(":focus"), false, 'check select4 focus')

  equal(el.find('[name="selectmulti1"]').val(), 'false', 'check selectmulti1 value')
  equal(el.find('[name="selectmulti1"]').prop('required'), false, 'check selectmulti1 required')
  equal(el.find('[name="selectmulti1"]').is(":focus"), false, 'check selectmulti1 focus')

  equal(el.find('[name="selectmulti2"]').val()[0], 'true', 'check selectmulti2 value')
  equal(el.find('[name="selectmulti2"]').val()[1], 'false', 'check selectmulti2 value')
  equal(el.find('[name="selectmulti2"]').prop('required'), true, 'check selectmulti2 required')
  equal(el.find('[name="selectmulti2"]').is(":focus"), false, 'check selectmulti2 focus')

  params = App.ControllerForm.params(el)
  test_params = {
    input1: '',
    input2: '123abc',
    password1: '',
    password1_confirm: '',
    password2: 'pw1234<l>',
    password2_confirm: 'pw1234<l>',
    textarea1: '',
    textarea2: 'lalu <l> lalu',
    select1: 'false',
    select2: 'true',
    select3: '',
    select4: '',
    selectmulti1: 'false',
    selectmulti2: [ 'true', 'false' ],
    selectmultioption1: 'false',
    selectmultioption2: [ 'true', 'false' ],
    autocompletion1: '',
    autocompletion1_autocompletion: '',
    autocompletion1_autocompletion_value_shown: '',
    autocompletion2: 'id2',
    autocompletion2_autocompletion: 'value2',
    autocompletion2_autocompletion_value_shown: 'value2',
    richtext1: '',
    richtext2: '<div>lalu <b>b</b> lalu</div>',
    richtext3: '',
    richtext4: '<div>lalu <i>b</i> lalu</div>',
    richtext5: '',
    richtext6: '<div>lalu <b>b</b> lalu</div>',
    richtext7: '',
    richtext8: '<div>lalu <i>b</i> lalu</div>',
    datetime1: '2015-01-11T12:40:00.000Z',
    datetime2: null,
    datetime3: '2015-01-11T12:40:00.000Z',
    datetime4: null,
    date1: '2015-01-11',
    date2: null,
    date3: '2015-01-11',
    date4: null,
    active1: true,
    active2: false,
    checkbox1: [],
    checkbox2: undefined,
    checkbox3: 'd',
    checkbox4: [],
    radiobox1: undefined,
    radiobox2: 'a',
    boolean1: true,
    boolean2: false,
    boolean3: true,
  }
  deepEqual(params, test_params, 'form param check')

});

test("form defaults + params check", function() {
//    deepEqual(item, test.value, 'group set/get tests' );

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
  equal(el.find('[name="input1"]').val(), '', 'check input1 value')
  equal(el.find('[name="input1"]').prop('required'), false, 'check input1 required')
//  equal(el.find('[name="input1"]').is(":focus"), true, 'check input1 focus')
  equal(el.find('[name="input2"]').val(), 'some used default', 'check input2 value')
  equal(el.find('[name="input2"]').prop('required'), false, 'check input2 required')

  equal(el.find('[name="password1"]').val(), 'some used pass', 'check password1 value')
  equal(el.find('[name="password1_confirm"]').val(), 'some used pass', 'check password1 value')
  equal(el.find('[name="password1"]').prop('required'), true, 'check password1 required')
  equal(el.find('[name="password1"]').is(":focus"), false, 'check password1 focus')

  equal(el.find('[name="password2"]').val(), 'pw1234<l>', 'check password2 value')
  equal(el.find('[name="password2_confirm"]').val(), 'pw1234<l>', 'check password2 value')
  equal(el.find('[name="password2"]').prop('required'), true, 'check password2 required')
  equal(el.find('[name="password2"]').is(":focus"), false, 'check password2 focus')

  equal(el.find('[name="textarea1"]').val(), 'some used text', 'check textarea1 value')
  equal(el.find('[name="textarea1"]').prop('required'), true, 'check textarea1 required')
  equal(el.find('[name="textarea1"]').is(":focus"), false, 'check textarea1 focus')

  equal(el.find('[name="textarea2"]').val(), 'lalu <l> lalu', 'check textarea2 value')
  equal(el.find('[name="textarea2"]').prop('required'), true, 'check textarea2 required')
  equal(el.find('[name="textarea2"]').is(":focus"), false, 'check textarea2 focus')

  equal(el.find('[name="select1"]').val(), 'false', 'check select1 value')
  equal(el.find('[name="select1"]').prop('required'), false, 'check select1 required')
  equal(el.find('[name="select1"]').is(":focus"), false, 'check select1 focus')

  equal(el.find('[name="select2"]').val(), 'false', 'check select2 value')
  equal(el.find('[name="select2"]').prop('required'), false, 'check select2 required')
  equal(el.find('[name="select2"]').is(":focus"), false, 'check select2 focus')

  equal(el.find('[name="selectmulti2"]').val()[0], 'true', 'check selectmulti2 value')
  equal(el.find('[name="selectmulti2"]').val()[1], 'false', 'check selectmulti2 value')
  equal(el.find('[name="selectmulti2"]').prop('required'), true, 'check selectmulti2 required')
  equal(el.find('[name="selectmulti2"]').is(":focus"), false, 'check selectmulti2 focus')

});

test("form dependend fields check", function() {
//    deepEqual(item, test.value, 'group set/get tests' );

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
    datetime1: new Date(Date.parse('2015-01-11T12:40:00Z')),
    datetime3: new Date(Date.parse('2015-01-11T12:40:00Z')),
    date1:     '2015-01-11',
    date3:     '2015-01-11',
  }
  var form = new App.ControllerForm({
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
        { name: 'datetime1', display: 'Datetime1', tag: 'datetime', null: true, default: defaults['datetime1']  },
        { name: 'datetime2', display: 'Datetime2', tag: 'datetime', null: true, default: defaults['datetime2']  },
        { name: 'datetime3', display: 'Datetime3', tag: 'datetime', null: false, default: defaults['datetime3']  },
        { name: 'datetime4', display: 'Datetime4', tag: 'datetime', null: false, default: defaults['datetime4']  },
        { name: 'date1',     display: 'Date1',     tag: 'date', null: true, default: defaults['date1']  },
        { name: 'date2',     display: 'Date2',     tag: 'date', null: true, default: defaults['date2']  },
        { name: 'date3',     display: 'Date3',     tag: 'date', null: false, default: defaults['date3']  },
        { name: 'date4',     display: 'Date4',     tag: 'date', null: false, default: defaults['date4']  },
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
          value: ["true"]
        },
        change: {
          name: 'datetime1',
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
          value: ["false"]
        },
        change: {
          name: 'datetime1',
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
  equal(el.find('[name="input1"]').val(), '', 'check input1 value')
  equal(el.find('[name="input1"]').prop('required'), false, 'check input1 required')
//  equal(el.find('[name="input1"]').is(":focus"), true, 'check input1 focus')
  equal(el.find('[name="input2"]').val(), 'some used default', 'check input2 value')
  equal(el.find('[name="input2"]').prop('required'), false, 'check input2 required')

  equal(el.find('[name="input3"]').val(), 'some used default', 'check input3 value')
  equal(el.find('[name="input3"]').prop('required'), false, 'check input3 required')

  equal(el.find('[name="select1"]').val(), 'false', 'check select1 value')
  equal(el.find('[name="select1"]').prop('required'), false, 'check select1 required')
  equal(el.find('[name="select1"]').is(":focus"), false, 'check select1 focus')

  equal(el.find('[name="select2"]').val(), 'false', 'check select2 value')
  equal(el.find('[name="select2"]').prop('required'), false, 'check select2 required')
  equal(el.find('[name="select2"]').is(":focus"), false, 'check select2 focus')

  equal(el.find('[name="selectmulti2"]').val()[0], 'true', 'check selectmulti2 value')
  equal(el.find('[name="selectmulti2"]').val()[1], 'false', 'check selectmulti2 value')
  equal(el.find('[name="selectmulti2"]').prop('required'), true, 'check selectmulti2 required')
  equal(el.find('[name="selectmulti2"]').is(":focus"), false, 'check selectmulti2 focus')

  var params = App.ControllerForm.params(el)
  var test_params = {
    input1: "",
    input2: "some used default",
    select1: "false",
    select2: "false",
    selectmulti2: [ "true", "false" ],
    selectmultioption1: "false",
    datetime1: '2015-01-11T12:40:00.000Z',
    datetime2: null,
    datetime3: '2015-01-11T12:40:00.000Z',
    datetime4: null,
    date1: '2015-01-11',
    date2: null,
    date3: '2015-01-11',
    date4: null,
  }
  deepEqual(params, test_params, 'form param check')

  errors = form.validate(params)
  test_errors = {
    datetime4: "is required",
    date4:     "is required",
  }
  deepEqual(errors, test_errors, 'validation errors check')
  App.ControllerForm.validate({ errors: errors, form: el })

  el.find('[name="select1"]').val('true')
  el.find('[name="select1"]').trigger('change')
  params = App.ControllerForm.params(el)
  test_params = {
    input1: "",
    input3: "some used default",
    select1: "true",
    select2: "false",
    selectmulti2: [ "true", "false" ],
    selectmultioption1: "false",
    datetime1: null,
    datetime2: null,
    datetime3: '2015-01-11T12:40:00.000Z',
    datetime4: null,
    date1: '2015-01-11',
    date2: null,
    date3: '2015-01-11',
    date4: null,
  }
  deepEqual(params, test_params, 'form param check')
});

test("form handler check with and without fieldset", function() {
//    deepEqual(item, test.value, 'group set/get tests' );

// mix default and params -> check it -> add note
// test auto completion
// show/hide fields base on field values -> bind changed event
// form validation
// form params check

// add signature only if form_state is empty
  $('#forms').append('<hr><h1>form handler check with and without fieldset</h1><form id="form5"></form>')
  var el = $('#form5')
  var defaults = {
    select1: 'a',
    select2: '',
  }

  var formChanges = function(params, attribute, attributes, classname, form, ui) {
    //console.log('FROM', form)
    if (params['select1'] === 'b') {
      //console.log('select1 -> b', params)
      var item = {
        name:    'select2',
        display: 'Select2',
        tag:     'select',
        null:    true,
        options: { 1:'1', 2:'2', 3:'3' },
        default: 3,
      };
      var newElement = ui.formGenItem(item, classname, form)
      form.find('[name="select2"]').closest('.form-group').replaceWith(newElement)
    }
    if (params['select1'] === 'a') {
      //console.log('select1 -> a', params)
      var item = {
        name:    'select2',
        display: 'Select2',
        tag:     'select',
        null:    true,
        options: { 1:'1', 2:'2', 3:'3' },
        default: 1,
      };
      var newElement = ui.formGenItem(item, classname, form)
      form.find('[name="select2"]').closest('.form-group').replaceWith(newElement)
    }
  }

  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'select1', display: 'Select1', tag: 'select', null: true, options: { a: 'a', b: 'b' }, default: 'b'},
        { name: 'select2', display: 'Select2', tag: 'select', null: true, options: { 1:'1', 2:'2', 3:'3' }, default: 2 },
      ],
    },
    params: defaults,
    handlers: [
      formChanges,
    ],
    //noFieldset: true,
  });
  equal(el.find('[name="select1"]').val(), 'a', 'check select1 value')
  equal(el.find('[name="select1"]').prop('required'), false, 'check select1 required')

  equal(el.find('[name="select2"]').val(), '1', 'check select2 value')
  equal(el.find('[name="select2"]').prop('required'), false, 'check select2 required')

  var params = App.ControllerForm.params(el)
  var test_params = {
    select1: 'a',
    select2: '1',
  }
  deepEqual(params, test_params, 'form param check')
  el.find('[name="select1"]').val('b')
  el.find('[name="select1"]').trigger('change')
  params = App.ControllerForm.params(el)
  test_params = {
    select1: 'b',
    select2: '3',
  }
  deepEqual(params, test_params, 'form param check')
  el.find('[name="select1"]').val('a')
  el.find('[name="select1"]').trigger('change')
  params = App.ControllerForm.params(el)
  test_params = {
    select1: 'a',
    select2: '1',
  }
  deepEqual(params, test_params, 'form param check')

  // test with noFieldset
  el.empty()
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'select1', display: 'Select1', tag: 'select', null: true, options: { a: 'a', b: 'b' }, default: 'b'},
        { name: 'select2', display: 'Select2', tag: 'select', null: true, options: { 1:'1', 2:'2', 3:'3' }, default: 2 },
      ],
    },
    params: defaults,
    handlers: [
      formChanges,
    ],
    noFieldset: true,
  });
  equal(el.find('[name="select1"]').val(), 'a', 'check select1 value')
  equal(el.find('[name="select1"]').prop('required'), false, 'check select1 required')

  equal(el.find('[name="select2"]').val(), '1', 'check select2 value')
  equal(el.find('[name="select2"]').prop('required'), false, 'check select2 required')

  var params = App.ControllerForm.params(el)
  var test_params = {
    select1: 'a',
    select2: '1',
  }
  deepEqual(params, test_params, 'form param check')
  el.find('[name="select1"]').val('b')
  el.find('[name="select1"]').trigger('change')
  params = App.ControllerForm.params(el)
  test_params = {
    select1: 'b',
    select2: '3',
  }
  deepEqual(params, test_params, 'form param check')
  el.find('[name="select1"]').val('a')
  el.find('[name="select1"]').trigger('change')
  params = App.ControllerForm.params(el)
  test_params = {
    select1: 'a',
    select2: '1',
  }
  deepEqual(params, test_params, 'form param check')

});

test("form postmaster filter", function() {

  App.TicketPriority.refresh([
    {
      id:   1,
      name: 'prio 1',
    },
    {
      id:   2,
      name: 'prio 2',
    },
  ] )
  App.Group.refresh([
    {
      id:   1,
      name: 'group 1',
    },
    {
      id:   2,
      name: 'group 2',
    },
  ] )

  $('#forms').append('<hr><h1>form postmaster filter</h1><form id="form6"></form>')
  var el = $('#form6')
  var defaults = {
    input2: 'some name',
    match: {
      from: {
        operator: 'contains',
        value: 'some@address',
      },
      subject: {
        operator: 'contains',
        value: 'some subject',
      },
    },
    set: {
      'x-zammad-ticket-customer_id': {
        value: 'customer',
        value_completion: ''
      },
      'x-zammad-ticket-group_id': {
        value: '1'
      },
      'x-zammad-ticket-owner_id': {
        value: 'owner',
        value_completion: ''
      },
      'x-zammad-ticket-priority_id': {
        value: '1'
      },
      'x-zammad-ticket-tags': {
        operator: 'add',
        value: 'test, test1'
      }
    },
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'input1', display: 'Input1', tag: 'input', type: 'text', limit: 100, null: true, default: 'some not used default' },
        { name: 'input2', display: 'Input2', tag: 'input', type: 'text', limit: 100, null: true, default: 'some used default' },
        { name: 'match',  display: 'Match',  tag: 'postmaster_match', null: false, default: false},
        { name: 'set',    display: 'Set',    tag: 'postmaster_set', null: false, default: false},
      ],
    },
    params: defaults,
  });
  params = App.ControllerForm.params(el)
  test_params = {
    input1: 'some not used default',
    input2: 'some name',
    match: {
      from: {
        operator: 'contains',
        value: 'some@address'
      },
      subject: {
        operator: 'contains',
        value: 'some subject'
      }
    },
    set: {
      'x-zammad-ticket-customer_id': {
        value: 'customer',
        value_completion: ''
      },
      'x-zammad-ticket-group_id': {
        value: '1'
      },
      'x-zammad-ticket-owner_id': {
        value: 'owner',
        value_completion: ''
      },
      'x-zammad-ticket-priority_id': {
        value: '1'
      },
      'x-zammad-ticket-tags': {
        operator: 'add',
        value: 'test, test1'
      }
    },
  };
  deepEqual(params, test_params, 'form param check')

  el.find('[name="set::x-zammad-ticket-priority_id::value"]').closest('.js-filterElement').find('.js-remove').click()
  el.find('[name="set::x-zammad-ticket-customer_id::value"]').closest('.js-filterElement').find('.js-remove').click()

  params = App.ControllerForm.params(el)
  test_params = {
    input1: 'some not used default',
    input2: 'some name',
    match: {
      from: {
        operator: 'contains',
        value: 'some@address'
      },
      subject: {
        operator: 'contains',
        value: 'some subject'
      }
    },
    set: {
      'x-zammad-ticket-owner_id': {
        value: 'owner',
        value_completion: ''
      },
      'x-zammad-ticket-group_id': {
        value: '1'
      },
      'x-zammad-ticket-tags': {
        operator: 'add',
        value: 'test, test1'
      },
    },
  };
  deepEqual(params, test_params, 'form param check')

  el.find('.postmaster_set .js-filterElement').last().find('.filter-controls .js-add').click()

  params = App.ControllerForm.params(el)
  test_params = {
    input1: 'some not used default',
    input2: 'some name',
    match: {
      from: {
        operator: 'contains',
        value: 'some@address'
      },
      subject: {
        operator: 'contains',
        value: 'some subject'
      }
    },
    set: {
      'x-zammad-ticket-owner_id': {
        value: 'owner',
        value_completion: ''
      },
      'x-zammad-ticket-group_id': {
        value: '1'
      },
      'x-zammad-ticket-priority_id': {
        value: '1'
      },
      'x-zammad-ticket-tags': {
        operator: 'add',
        value: 'test, test1'
      },
    },
  };
  deepEqual(params, test_params, 'form param check')

  App.Delay.set(function() {
    test("form postmaster filter - needed to do delayed because of tag ui", function() {
      el.find('[name="set::x-zammad-ticket-tags::value"]').closest('.js-filterElement').find('.token .close').last().click()
      params = App.ControllerForm.params(el)
      test_params = {
        input1: 'some not used default',
        input2: 'some name',
        match: {
          from: {
            operator: 'contains',
            value: 'some@address'
          },
          subject: {
            operator: 'contains',
            value: 'some subject'
          }
        },
        set: {
          'x-zammad-ticket-owner_id': {
            value: 'owner',
            value_completion: ''
          },
          'x-zammad-ticket-group_id': {
            value: '1'
          },
          'x-zammad-ticket-priority_id': {
            value: '1'
          },
          'x-zammad-ticket-tags': {
            operator: 'add',
            value: 'test'
          },
        },
      };
      deepEqual(params, test_params, 'form param check')
    })
  }, 500);
});

test("form selector", function() {
  $('#forms').append('<hr><h1>form selector</h1><div><form id="form7"></form></div>')
  var el = $('#form7')
  var defaults = {
    input2: 'some name66',
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'input1', display: 'Input1', tag: 'input', type: 'text', limit: 100, null: true, default: 'some not used default33' },
        { name: 'input2', display: 'Input2', tag: 'input', type: 'text', limit: 100, null: true, default: 'some used default' },
      ],
    },
    params: defaults,
  });
  test_params = {
    input1: 'some not used default33',
    input2: 'some name66',
  };
  params = App.ControllerForm.params(el)
  deepEqual(params, test_params, 'form param check via $("#form")')

  params = App.ControllerForm.params(el.find('input'))
  deepEqual(params, test_params, 'form param check via $("#form").find("input")')

  params = App.ControllerForm.params(el.parent())
  deepEqual(params, test_params, 'form param check via $("#form").parent()')

});

test("form required_if + shown_if", function() {
  $('#forms').append('<hr><h1>form required_if + shown_if</h1><div><form id="form8"></form></div>')
  var el = $('#form8')
  var defaults = {
    input2: 'some name66',
    input3: 'some name77',
    input4: 'some name88',
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'input1', display: 'Input1', tag: 'input', type: 'text', limit: 100, null: true, default: 'some not used default33' },
        { name: 'input2', display: 'Input2', tag: 'input', type: 'text', limit: 100, null: true, default: 'some used default', required_if: { active: true }, shown_if: { active: true } },
        { name: 'input3', display: 'Input3', tag: 'input', type: 'text', limit: 100, null: true, default: 'some used default', required_if: { active: [true,false] }, shown_if: { active: [true,false] } },
        { name: 'input4', display: 'Input4', tag: 'input', type: 'text', limit: 100, null: true, default: 'some used default', required_if: { active: [55,66] }, shown_if: { active: [55,66] } },
        { name: 'active', display: 'Active', tag: 'active', 'default': true },
      ],
    },
    params: defaults,
  });
  test_params = {
    input1: "some not used default33",
    input2: "some name66",
    input3: "some name77",
    active: true,
  };
  params = App.ControllerForm.params(el)
  deepEqual(params, test_params, 'form param check via $("#form")')
  equal(el.find('[name="input2"]').attr('required'), 'required', 'check required attribute of input2 ')
  equal(el.find('[name="input2"]').is(":visible"), true, 'check visible attribute of input2 ')
  equal(el.find('[name="input3"]').attr('required'), 'required', 'check required attribute of input3 ')
  equal(el.find('[name="input3"]').is(":visible"), true, 'check visible attribute of input3 ')
  equal(el.find('[name="input4"]').is(":visible"), false, 'check visible attribute of input4 ')


  el.find('[name="active"]').val('false').trigger('change')
  test_params = {
    input1: "some not used default33",
    active: false,
  };
  params = App.ControllerForm.params(el)
  deepEqual(params, test_params, 'form param check via $("#form")')
  equal(el.find('[name="input2"]').attr('required'), undefined, 'check required attribute of input2')
  equal(el.find('[name="input2"]').is(":visible"), false, 'check visible attribute of input2')
  equal(el.find('[name="input3"]').is(":visible"), false, 'check visible attribute of input3')
  equal(el.find('[name="input4"]').is(":visible"), false, 'check visible attribute of input4')


  el.find('[name="active"]').val('true').trigger('change')
  test_params = {
    input1: "some not used default33",
    input2: "some name66",
    input3: "some name77",
    active: true,
  };
  params = App.ControllerForm.params(el)
  deepEqual(params, test_params, 'form param check via $("#form")')
  equal(el.find('[name="input2"]').attr('required'), 'required', 'check required attribute of input2')
  equal(el.find('[name="input2"]').is(":visible"), true, 'check visible attribute of input2')
  equal(el.find('[name="input3"]').attr('required'), 'required', 'check required attribute of input3')
  equal(el.find('[name="input3"]').is(":visible"), true, 'check visible attribute of input3')
  equal(el.find('[name="input4"]').is(":visible"), false, 'check visible attribute of input4')

});

test("form params check", function() {

  $('#forms').append('<hr><h1>form params check</h1><form id="form9"></form>')
  var el = $('#form9')
  var defaults = {
    select1: false,
    select2: true,
    select3: null,
    select4: undefined,
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'select1', display: 'Select1', tag: 'select', null: true, options: { true: 'internal', false: 'public' } },
        { name: 'select2', display: 'Select2', tag: 'select', null: false, options: { true: 'internal', false: 'public' } },
        { name: 'select3', display: 'Select3', tag: 'select', null: false, nulloption: true, options: { aa: 'aa', bb: 'bb', select3: 'select3' } },
        { name: 'select4', display: 'Select4', tag: 'select', null: false, nulloption: true,  options: { aa: 'aa', bb: 'bb', select3: 'select4' } },
      ],
    },
    params: defaults,
    autofocus: true
  });


  params = App.ControllerForm.params(el)
  test_params = {
    select1: 'false',
    select2: 'true',
    select3: '',
    select4: '',
  }
  //console.log('params', params)
  //console.log('test_params', test_params)
  deepEqual(params, test_params, 'form param check')

});

test("form params check direct", function() {

  $('#forms').append('<hr><h1>form params check direct</h1><form id="form10"><input name="a" value="b"><input name="l::l::l1" value="d"><input name="l::l::" value><input name="f::f::" value><input name="f::f::f1" value="e"></form>')
  var el = $('#form10')

  params = App.ControllerForm.params(el)
  test_params = {
    a: 'b',
    l: {
      l: {
        l1: 'd',
        '': '',
      },
    },
    f: {
      f: {
        f1: 'e',
        '': '',
      },
    },
  }
  //console.log('params', params)
  //console.log('test_params', test_params)
  deepEqual(params, test_params, 'form param check')
});

test("object manager form 1", function() {

  $('#forms').append('<hr><h1>object manager 1</h1><form id="form11"></form>')
  var el = $('#form11')

  var defaults = {}
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'data_type',  display: 'Format', tag: 'object_manager_attribute', null: false },
      ],
    },
    params: $.extend(defaults, { object: 'Ticket' }),
    autofocus: true
  });

  var params = App.ControllerForm.params(el)
  var test_params = {
    data_option: {
      default: "",
      maxlength: 120,
      type: "text"
    },
    data_type: "input",
    screens: {
      create_middle: {
        "ticket.agent": {
          shown: true,
          required: false,
        },
        "ticket.customer": {
          shown: true,
          required: false,
        }
      },
      edit: {
        "ticket.agent": {
          shown: true,
          required: false,
        },
        "ticket.customer": {
          shown: true,
          required: false,
        }
      }
    }
  }

  deepEqual(params, test_params, 'form param check')

  el.find('[name=data_type]').val('datetime').trigger('change')

  params = App.ControllerForm.params(el)
  var test_params = {
    data_option: {
      diff: 24,
      future: true,
      past: true
    },
    data_type: "datetime",
    screens: {
      create_middle: {
        "ticket.agent": {
          shown: true,
          required: false,
        },
        "ticket.customer": {
          shown: true,
          required: false,
        }
      },
      edit: {
        "ticket.agent": {
          shown: true,
          required: false,
        },
        "ticket.customer": {
          shown: true,
          required: false,
        }
      }
    }
  }
  deepEqual(params, test_params, 'form param check')

});

test("object manager form 2", function() {

  $('#forms').append('<hr><h1>object manager 2</h1><form id="form12"></form>')
  var el = $('#form12')

  var defaults = {
    id: 123,
    data_option: {
      default: "",
      maxlength: 120,
      type: "text"
    },
    data_type: "input",
    screens: {
      create_middle: {
        "ticket.agent": {
          shown: true,
          required: false,
        },
      },
      edit: {
        "ticket.agent": {
          shown: true,
          required: false,
        },
      }
    }
  }

  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'data_type',  display: 'Format', tag: 'object_manager_attribute', null: false },
      ],
    },
    params: $.extend(defaults, { object: 'Ticket' }),
    autofocus: true
  });

  var params = App.ControllerForm.params(el)
  var test_params = {
    data_option: {
      default: "",
      maxlength: 120,
      type: "text"
    },
    data_type: "input",
    screens: {
      create_middle: {
        "ticket.agent": {
          shown: true,
          required: false,
        },
        "ticket.customer": {
          shown: false,
          required: false,
        }
      },
      edit: {
        "ticket.agent": {
          shown: true,
          required: false,
        },
        "ticket.customer": {
          shown: false,
          required: false,
        }
      }
    }
  }

  deepEqual(params, test_params, 'form param check')

});

test("object manager form 3", function() {

  $('#forms').append('<hr><h1>object manager 3</h1><form id="form13"></form>')
  var el = $('#form13')

  var defaults = {}
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'data_type',  display: 'Format', tag: 'object_manager_attribute', null: false },
      ],
    },
    params: $.extend(defaults, { object: 'Ticket' }),
    autofocus: true
  });

  var params = App.ControllerForm.params(el)
  var test_params = {
    data_option: {
      default: "",
      maxlength: 120,
      type: "text"
    },
    data_type: "input",
    screens: {
      create_middle: {
        "ticket.agent": {
          shown: true,
          required: false,
        },
        "ticket.customer": {
          shown: true,
          required: false,
        }
      },
      edit: {
        "ticket.agent": {
          shown: true,
          required: false,
        },
        "ticket.customer": {
          shown: true,
          required: false,
        }
      }
    }
  }

  deepEqual(params, test_params, 'form param check')

  el.find('[name="screens::create_middle::ticket.customer::shown"]').click()
  el.find('[name="screens::edit::ticket.customer::shown"]').click()

  params = App.ControllerForm.params(el)
  test_params = {
    data_option: {
      default: "",
      maxlength: 120,
      type: "text"
    },
    data_type: "input",
    screens: {
      create_middle: {
        "ticket.agent": {
          shown: true,
          required: false,
        },
        "ticket.customer": {
          shown: false,
          required: false,
        }
      },
      edit: {
        "ticket.agent": {
          shown: true,
          required: false,
        },
        "ticket.customer": {
          shown: false,
          required: false,
        }
      }
    }
  }
  deepEqual(params, test_params, 'form param check')

});

test("time range form 1", function() {

  $('#forms').append('<hr><h1>time range form 1</h1><form id="form14"></form>')
  var el = $('#form14')

  var defaults = {}
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'time_range',  display: 'Format', tag: 'time_range', null: false },
      ],
    },
    params: $.extend(defaults, { object: 'Ticket' }),
    autofocus: true
  });

  var params = App.ControllerForm.params(el)
  var test_params = {
    "time_range": {
      "range": "minute",
      "value": "1"
    }
  }

  deepEqual(params, test_params, 'base form param range check')

  el.find('.js-range').val('minute').trigger('change')
  el.find('.js-valueRangeSelector .js-value').val('120').trigger('change')

  params = App.ControllerForm.params(el)
  test_params = {
    "time_range": {
      "range": "minute",
      "value": "120"
    }
  }
  deepEqual(params, test_params, 'form param minute range check')

  el.find('.js-range').val('hour').trigger('change')
  el.find('.js-valueRangeSelector .js-value').val('48').trigger('change')

  params = App.ControllerForm.params(el)
  test_params = {
    "time_range": {
      "range": "hour",
      "value": "48"
    }
  }
  deepEqual(params, test_params, 'form param hour range check')

  el.find('.js-range').val('day').trigger('change')
  el.find('.js-valueRangeSelector .js-value').val('31').trigger('change')

  params = App.ControllerForm.params(el)
  test_params = {
    "time_range": {
      "range": "day",
      "value": "31"
    }
  }
  deepEqual(params, test_params, 'form param day range check')

  el.find('.js-range').val('month').trigger('change')
  el.find('.js-valueRangeSelector .js-value').val('12').trigger('change')

  params = App.ControllerForm.params(el)
  test_params = {
    "time_range": {
      "range": "month",
      "value": "12"
    }
  }
  deepEqual(params, test_params, 'form param month range check')

  el.find('.js-range').val('year').trigger('change')
  el.find('.js-valueRangeSelector .js-value').val('20').trigger('change')

  params = App.ControllerForm.params(el)
  test_params = {
    "time_range": {
      "range": "year",
      "value": "20"
    }
  }
  deepEqual(params, test_params, 'form param year range check')
});

test("form select with empty option list", function() {

  $('#forms').append('<hr><h1>form select with empty option list</h1><form id="form15"></form>')
  var el = $('#form15')
  var defaults = {}
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'select1', display: 'Select1', tag: 'select', null: true, default: '', options: {}, relation: '', maxlength: 255 },
        { name: 'select2', display: 'Select2', tag: 'select', null: true, default: '', options: {}, relation: '', maxlength: 255, nulloption: true },
        { name: 'select3', display: 'Select3', tag: 'select', null: true, default: '', options: { undefined: 'A', null: 'B'} },
        { name: 'select4', display: 'Select4', tag: 'select', null: true, default: '', options: { 'A': undefined, 'B': null} },
        { name: 'select5', display: 'Select5', tag: 'select', null: true, default: 'A', options: { 'A': undefined, 'B': null} },
        { name: 'select6', display: 'Select6', tag: 'select', null: true, default: undefined, options: { 'A': undefined, 'B': null} },
      ],
    },
    params: defaults,
    autofocus: true
  });

  params = App.ControllerForm.params(el)
  test_params = {
    select2: '',
    select3: 'undefined',
    select4: 'B',
    select5: 'A',
    select6: 'B',
  }
  deepEqual(params, test_params)
});
