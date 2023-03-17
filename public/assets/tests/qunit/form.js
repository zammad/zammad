
// form
QUnit.test("form without @el", assert => {
  var form = new App.ControllerForm()

  assert.equal($(form.html()).is('div'), true)
  assert.equal($(form.html()).hasClass('alert'), true)
  assert.equal($(form.html()).hasClass('hide'), true)

})
QUnit.test("form elements check", assert => {
//    assert.deepEqual(item, test.value, 'group set/get tests' );
  $('#qunit').append('<hr><h1>form elements check</h1><form id="form1"></form>')
  var el = $('#form1')
  var defaults = {
    input2: '123abc',
    password2: 'pw1234<l>',
    textarea2: 'lalu <l> lalu',
    select1: false,
    select2: true,
    selectmulti1: [ false ],
    selectmulti2: [ false, true ],
    selectmultioption1: [ false ],
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
        { name: 'textarea3', display: 'Textarea3', tag: 'textarea', limit: 100, null: false, upload: true, default: defaults['textarea3'] },
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
  assert.equal(el.find('[name="input1"]').val(), '', 'check input1 value')
  assert.equal(el.find('[name="input1"]').prop('required'), false, 'check input1 required')
//  assert.equal(el.find('[name="input1"]').is(":focus"), true, 'check input1 focus')

  assert.equal(el.find('[name="input2"]').val(), '123abc', 'check input2 value')
  assert.equal(el.find('[name="input2"]').prop('required'), true, 'check input2 required')
  assert.equal(el.find('[name="input2"]').is(":focus"), false, 'check input2 focus')

  assert.equal(el.find('[name="password1"]').val(), '', 'check password1 value')
  assert.equal(el.find('[name="password1_confirm"]').val(), '', 'check password1 value')
  assert.equal(el.find('[name="password1"]').prop('required'), false, 'check password1 required')
  assert.equal(el.find('[name="password1"]').is(":focus"), false, 'check password1 focus')

  assert.equal(el.find('[name="password2"]').val(), 'pw1234<l>', 'check password2 value')
  assert.equal(el.find('[name="password2_confirm"]').val(), 'pw1234<l>', 'check password2 value')
  assert.equal(el.find('[name="password2"]').prop('required'), true, 'check password2 required')
  assert.equal(el.find('[name="password2"]').is(":focus"), false, 'check password2 focus')

  assert.equal(el.find('[name="textarea1"]').val(), '', 'check textarea1 value')
  assert.equal(el.find('[name="textarea1"]').prop('required'), false, 'check textarea1 required')
  assert.equal(el.find('[name="textarea1"]').is(":focus"), false, 'check textarea1 focus')

  assert.equal(el.find('[name="textarea2"]').val(), 'lalu <l> lalu', 'check textarea2 value')
  assert.equal(el.find('[name="textarea2"]').prop('required'), true, 'check textarea2 required')
  assert.equal(el.find('[name="textarea2"]').is(":focus"), false, 'check textarea2 focus')
  assert.equal(el.find('[name="textarea2"]').prop("rows"), 6, 'check textarea2 rows')

  assert.equal(el.find('[name="textarea3"]').prop("rows"), 4, 'check textarea3 rows (default value)')

  assert.equal(el.find('[name="select1"]').val(), 'false', 'check select1 value')
  assert.equal(el.find('[name="select1"]').prop('required'), false, 'check select1 required')
  assert.equal(el.find('[name="select1"]').is(":focus"), false, 'check select1 focus')

  assert.equal(el.find('[name="select2"]').val(), 'true', 'check select2 value')
  assert.equal(el.find('[name="select2"]').prop('required'), true, 'check select2 required')
  assert.equal(el.find('[name="select2"]').is(":focus"), false, 'check select2 focus')

  assert.equal(el.find('[name="selectmulti1"]').val(), 'false', 'check selectmulti1 value')
  assert.equal(el.find('[name="selectmulti1"]').prop('required'), false, 'check selectmulti1 required')
  assert.equal(el.find('[name="selectmulti1"]').is(":focus"), false, 'check selectmulti1 focus')

  assert.equal(el.find('[name="selectmulti2"]').val()[0], 'true', 'check selectmulti2 value')
  assert.equal(el.find('[name="selectmulti2"]').val()[1], 'false', 'check selectmulti2 value')
  assert.equal(el.find('[name="selectmulti2"]').prop('required'), true, 'check selectmulti2 required')
  assert.equal(el.find('[name="selectmulti2"]').is(":focus"), false, 'check selectmulti2 focus')

  //equal(el.find('[name="richtext1"]').val(), '', 'check textarea1 value')
  //equal(el.find('[name="richtext1"]').prop('required'), false, 'check textarea1 required')
  assert.equal(el.find('[name="richtext1"]').is(":focus"), false, 'check textarea1 focus')

  //equal(el.find('[name="richtext2"]').val(), 'lalu <l> lalu', 'check textarea2 value')
  //equal(el.find('[name="richtext2"]').prop('required'), true, 'check textarea2 required')
  assert.equal(el.find('[name="richtext2"]').is(":focus"), false, 'check textarea2 focus')

  assert.equal(el.find('[name="checkbox1"]').first().is(":checked"), false)
  assert.equal(el.find('[name="checkbox1"]').last().is(":checked"), false)
  assert.equal(el.find('[name="checkbox2"]').is(":checked"), true)

  assert.equal(el.find('[name="boolean1"]').val(), 'true')
  assert.equal(el.find('[name="boolean1"]').val(), 'true')
  assert.equal(el.find('[name="boolean2"]').val(), 'false')
});

QUnit.test("form params check 1", assert => {
//    assert.deepEqual(item, test.value, 'group set/get tests' );

  $('#qunit').append('<hr><h1>form params check</h1><form id="form2"></form>')
  var el = $('#form2')
  var defaults = {
    input2: '123abc',
    password2: 'pw1234<l>',
    textarea2: 'lalu <l> lalu',
    select1: false,
    select2: true,
    select3: null,
    select4: undefined,
    select5: false,
    selectmulti1: [ false ],
    selectmulti2: [ false, true ],
    selectmulti3: [ false ],
    selectmultioption1: [ false ],
    selectmultioption2: [ false, true ],
    selectmultioption2: [ false, true ],
    selectmultioption3: [ false ],
    autocompletion2: 'id2',
    autocompletion2_autocompletion_value_shown: 'value2',
    richtext2: '<div>lalu <b>b</b> lalu</div>',
    richtext3: '<div></div>',
    richtext4: '<div>lalu <i>b</i> lalu</div>',
    richtext5: '<div></div>',
    richtext6: '<div>lalu <b>b</b> lalu</div>',
    richtext7: "<div>&nbsp;<div>&nbsp;\n</div>  \n</div>",
    richtext8: '<div>lalu <i>b</i> lalu</div>',
    richtext9: '<div>lalu <b>b</b> lalu</div>',
    datetime1: new Date(Date.parse('2015-01-11T12:40:00Z') ),
    datetime3: new Date(Date.parse('2015-01-11T12:40:00Z') ),
    datetime5: new Date(Date.parse('2015-01-11T12:40:00Z') ),
    date1:     '2015-01-11',
    date3:     '2015-01-11',
    date5:     '2015-01-11',
    active1:   true,
    active2:   false,
    checkbox1: [],
    checkbox2: undefined,
    checkbox3: 'd',
    checkbox5: 'd',
    radiobox1: undefined,
    radiobox2: 'a',
    radiobox3: 'a',
    boolean1:  true,
    boolean2:  false,
    boolean4:  false,
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'input1', display: 'Input1', tag: 'input', type: 'text', limit: 100, null: true },
        { name: 'input2', display: 'Input2', tag: 'input', type: 'text', limit: 100, null: false },
        { name: 'input3', display: 'Input3', tag: 'input', type: 'text', limit: 100, null: true, disabled: true },
        { name: 'password1', display: 'Password1', tag: 'input', type: 'password', limit: 100, null: true },
        { name: 'password2', display: 'Password2', tag: 'input', type: 'password', limit: 100, null: false },
        { name: 'textarea1', display: 'Textarea1', tag: 'textarea', rows: 6, limit: 100, null: true, upload: true },
        { name: 'textarea2', display: 'Textarea2', tag: 'textarea', rows: 6, limit: 100, null: false, upload: true },
        { name: 'textarea3', display: 'Textarea3', tag: 'textarea', rows: 6, limit: 100, null: true, upload: false, disabled: true },
        { name: 'select1', display: 'Select1', tag: 'select', null: true, options: { true: 'internal', false: 'public' } },
        { name: 'select2', display: 'Select2', tag: 'select', null: false, options: { true: 'internal', false: 'public' } },
        { name: 'select3', display: 'Select3', tag: 'select', null: false, nulloption: true, options: { aa: 'aa', bb: 'bb', select3: 'select3' } },
        { name: 'select4', display: 'Select4', tag: 'select', null: false, nulloption: true,  options: { aa: 'aa', bb: 'bb', select3: 'select4' } },
        { name: 'select5', display: 'Select5', tag: 'select', null: true, options: { true: 'internal', false: 'public' }, disabled: true },
        { name: 'selectmulti1', display: 'SelectMulti1', tag: 'select', null: true, multiple: true, options: { true: 'internal', false: 'public' } },
        { name: 'selectmulti2', display: 'SelectMulti2', tag: 'select', null: false, multiple: true, options: { true: 'internal', false: 'public' } },
        { name: 'selectmulti3', display: 'SelectMulti3', tag: 'select', null: true, multiple: true, options: { true: 'internal', false: 'public' }, disabled: true },
        { name: 'selectmultioption1', display: 'SelectMultiOption1', tag: 'select', null: true, multiple: true, options: [{ value: true, name: 'internal' }, { value: false, name: 'public' }] },
        { name: 'selectmultioption2', display: 'SelectMultiOption2', tag: 'select', null: false, multiple: true, options: [{ value: true, name: 'A' }, { value: 1, name: 'B'}, { value: false, name: 'C' }] },
        { name: 'selectmultioption3', display: 'SelectMultiOption3', tag: 'select', null: true, multiple: true, options: [{ value: true, name: 'internal' }, { value: false, name: 'public' }], disabled: true },
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
        { name: 'richtext9', display: 'Richtext9', tag: 'richtext', maxlength: 100, null: true, type: 'richtext', multiline: true, upload: true, default: defaults['richtext9'], disabled: true},
        { name: 'datetime1', display: 'Datetime1', tag: 'datetime', null: true, default: defaults['datetime1'] },
        { name: 'datetime2', display: 'Datetime2', tag: 'datetime', null: true, default: defaults['datetime2'] },
        { name: 'datetime3', display: 'Datetime3', tag: 'datetime', null: false, default: defaults['datetime3'] },
        { name: 'datetime4', display: 'Datetime4', tag: 'datetime', null: false, default: defaults['datetime4'] },
        { name: 'datetime5', display: 'Datetime4', tag: 'datetime', null: false, default: defaults['datetime5'], disabled: true },
        { name: 'date1',     display: 'Date1',     tag: 'date', null: true, default: defaults['date1'] },
        { name: 'date2',     display: 'Date2',     tag: 'date', null: true, default: defaults['date2'] },
        { name: 'date3',     display: 'Date3',     tag: 'date', null: false, default: defaults['date3'] },
        { name: 'date4',     display: 'Date4',     tag: 'date', null: false, default: defaults['date4'] },
        { name: 'date5',     display: 'Date4',     tag: 'date', null: false, default: defaults['date5'], disabled: true },
        { name: 'active1',   display: 'Active1',   tag: 'active', default: defaults['active1'] },
        { name: 'active2',   display: 'Active2',   tag: 'active', default: defaults['active2'] },
        { name: 'checkbox1', display: 'Checkbox1', tag: 'checkbox', null: false, default: defaults['checkbox1'], options: { a: 'AA', b: 'BB' } },
        { name: 'checkbox2', display: 'Checkbox2', tag: 'checkbox', null: false, default: defaults['checkbox2'], options: { 1: '11' } },
        { name: 'checkbox3', display: 'Checkbox3', tag: 'checkbox', null: false, default: defaults['checkbox3'], options: { c: 'CC', d: 'DD' } },
        { name: 'checkbox4', display: 'Checkbox4', tag: 'checkbox', null: false, default: defaults['checkbox4'], options: { aa: 'AA', bb: 'BB' } },
        { name: 'checkbox5', display: 'Checkbox5', tag: 'checkbox', null: false, default: defaults['checkbox5'], options: { c: 'CC', d: 'DD' }, disabled: true },
        { name: 'radiobox1', display: 'Radiobox1', tag: 'radio', null: false, default: defaults['radiobox1'], options: { a: 'AA', b: 'BB' } },
        { name: 'radiobox2', display: 'Radiobox2', tag: 'radio', null: false, default: defaults['radiobox2'], options: { a: '11' } },
        { name: 'radiobox3', display: 'Radiobox3', tag: 'radio', null: false, default: defaults['radiobox3'], options: { a: 'AA', b: 'BB' }, disabled: true },
        { name: 'boolean1',  display: 'Boolean1',  tag: 'boolean',  null: false, default: defaults['boolean1'] },
        { name: 'boolean2',  display: 'Boolean2',  tag: 'boolean',  null: false, default: defaults['boolean2'] },
        { name: 'boolean3',  display: 'Boolean3',  tag: 'boolean',  null: false, default: defaults['boolean3'] },
        { name: 'boolean4',  display: 'Boolean4',  tag: 'boolean',  null: false, default: defaults['boolean4'], disabled: true },
      ],
    },
    params: defaults,
    autofocus: true
  });
  assert.equal(el.find('[name="input1"]').val(), '', 'check input1 value')
  assert.equal(el.find('[name="input1"]').prop('required'), false, 'check input1 required')
//  assert.equal(el.find('[name="input1"]').is(":focus"), true, 'check input1 focus')

  assert.equal(el.find('[name="input2"]').val(), '123abc', 'check input2 value')
  assert.equal(el.find('[name="input2"]').prop('required'), true, 'check input2 required')
  assert.equal(el.find('[name="input2"]').is(":focus"), false, 'check input2 focus')

  assert.equal(el.find('[name="input3"]').prop("disabled"), true, 'check input3 disabled')

  assert.equal(el.find('[name="password1"]').val(), '', 'check password1 value')
  assert.equal(el.find('[name="password1_confirm"]').val(), '', 'check password1 value')
  assert.equal(el.find('[name="password1"]').prop('required'), false, 'check password1 required')
  assert.equal(el.find('[name="password1"]').is(":focus"), false, 'check password1 focus')

  assert.equal(el.find('[name="password2"]').val(), 'pw1234<l>', 'check password2 value')
  assert.equal(el.find('[name="password2_confirm"]').val(), 'pw1234<l>', 'check password2 value')
  assert.equal(el.find('[name="password2"]').prop('required'), true, 'check password2 required')
  assert.equal(el.find('[name="password2"]').is(":focus"), false, 'check password2 focus')

  assert.equal(el.find('[name="textarea1"]').val(), '', 'check textarea1 value')
  assert.equal(el.find('[name="textarea1"]').prop('required'), false, 'check textarea1 required')
  assert.equal(el.find('[name="textarea1"]').is(":focus"), false, 'check textarea1 focus')

  assert.equal(el.find('[name="textarea2"]').val(), 'lalu <l> lalu', 'check textarea2 value')
  assert.equal(el.find('[name="textarea2"]').prop('required'), true, 'check textarea2 required')
  assert.equal(el.find('[name="textarea2"]').is(":focus"), false, 'check textarea2 focus')

  assert.equal(el.find('[name="textarea3"]').prop("disabled"), true, 'check textarea3 disabled')

  assert.equal(el.find('[name="select1"]').val(), 'false', 'check select1 value')
  assert.equal(el.find('[name="select1"]').prop('required'), false, 'check select1 required')
  assert.equal(el.find('[name="select1"]').is(":focus"), false, 'check select1 focus')

  assert.equal(el.find('[name="select2"]').val(), 'true', 'check select2 value')
  assert.equal(el.find('[name="select2"]').prop('required'), true, 'check select2 required')
  assert.equal(el.find('[name="select2"]').is(":focus"), false, 'check select2 focus')

  assert.equal(el.find('[name="select3"]').val(), '', 'check select3 value')
  assert.equal(el.find('[name="select3"]').prop('required'), true, 'check select3 required')
  assert.equal(el.find('[name="select3"]').is(":focus"), false, 'check select3 focus')

  assert.equal(el.find('[name="select4"]').val(), '', 'check select4 value')
  assert.equal(el.find('[name="select4"]').prop('required'), true, 'check select4 required')
  assert.equal(el.find('[name="select4"]').is(":focus"), false, 'check select4 focus')

  assert.equal(el.find('[name="select5"]').prop("disabled"), true, 'check select5 disabled')

  assert.equal(el.find('[name="selectmulti1"]').val(), 'false', 'check selectmulti1 value')
  assert.equal(el.find('[name="selectmulti1"]').prop('required'), false, 'check selectmulti1 required')
  assert.equal(el.find('[name="selectmulti1"]').is(":focus"), false, 'check selectmulti1 focus')

  assert.equal(el.find('[name="selectmulti2"]').val()[0], 'true', 'check selectmulti2 value')
  assert.equal(el.find('[name="selectmulti2"]').val()[1], 'false', 'check selectmulti2 value')
  assert.equal(el.find('[name="selectmulti2"]').prop('required'), true, 'check selectmulti2 required')
  assert.equal(el.find('[name="selectmulti2"]').is(":focus"), false, 'check selectmulti2 focus')

  assert.equal(el.find('[name="selectmulti3"]').prop("disabled"), true, 'check selectmulti3 disabled')
  assert.equal(el.find('[name="selectmultioption3"]').prop("disabled"), true, 'check selectmultioption3 disabled')

  assert.equal(el.find('[name="boolean4"]').prop("disabled"), true, 'check boolean4 disabled')
  assert.equal(el.find('[data-name="richtext9"]').prop("contenteditable"), "false", 'check richtext9 disabled')
  assert.equal(el.find('[name="checkbox5"]').prop("disabled"), true, 'check checkbox5 disabled')
  assert.equal(el.find('[name="radiobox3"]').prop("disabled"), true, 'check radiobox3 disabled')

  params = App.ControllerForm.params(el)
  test_params = {
    input1: '',
    input2: '123abc',
    input3: '',
    password1: '',
    password1_confirm: '',
    password2: 'pw1234<l>',
    password2_confirm: 'pw1234<l>',
    textarea1: '',
    textarea2: 'lalu <l> lalu',
    textarea3: '',
    select1: 'false',
    select2: 'true',
    select3: '',
    select4: '',
    select5: 'false',
    selectmulti1: [ 'false' ],
    selectmulti2: [ 'true', 'false' ],
    selectmulti3: [ 'false' ],
    selectmultioption1: [ 'false' ],
    selectmultioption2: [ 'true', 'false' ],
    selectmultioption3: [ 'false' ],
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
    richtext9: '<div>lalu <b>b</b> lalu</div>',
    datetime1: '2015-01-11T12:40:00.000Z',
    datetime2: null,
    datetime3: '2015-01-11T12:40:00.000Z',
    datetime4: null,
    datetime5: '2015-01-11T12:40:00.000Z',
    date1: '2015-01-11',
    date2: null,
    date3: '2015-01-11',
    date4: null,
    date5: '2015-01-11',
    active1: true,
    active2: false,
    checkbox1: [],
    checkbox2: undefined,
    checkbox3: 'd',
    checkbox4: [],
    checkbox5: 'd',
    radiobox1: undefined,
    radiobox2: 'a',
    radiobox3: 'a',
    boolean1: true,
    boolean2: false,
    boolean3: true,
    boolean4: false,
  }
  assert.deepEqual(params, test_params, 'form param check 1')

});

QUnit.test("form defaults + params check", assert => {
//    assert.deepEqual(item, test.value, 'group set/get tests' );

// mix default and params -> check it -> add note
// test auto completion
// show/hide fields base on field values -> bind changed event
// form validation
// form params check

// add signature only if form_state is empty
  $('#qunit').append('<hr><h1>form defaults + params check</h1><form id="form3"></form>')
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
  assert.equal(el.find('[name="input1"]').val(), '', 'check input1 value')
  assert.equal(el.find('[name="input1"]').prop('required'), false, 'check input1 required')
//  assert.equal(el.find('[name="input1"]').is(":focus"), true, 'check input1 focus')
  assert.equal(el.find('[name="input2"]').val(), 'some used default', 'check input2 value')
  assert.equal(el.find('[name="input2"]').prop('required'), false, 'check input2 required')

  assert.equal(el.find('[name="password1"]').val(), 'some used pass', 'check password1 value')
  assert.equal(el.find('[name="password1_confirm"]').val(), 'some used pass', 'check password1 value')
  assert.equal(el.find('[name="password1"]').prop('required'), true, 'check password1 required')
  assert.equal(el.find('[name="password1"]').is(":focus"), false, 'check password1 focus')

  assert.equal(el.find('[name="password2"]').val(), 'pw1234<l>', 'check password2 value')
  assert.equal(el.find('[name="password2_confirm"]').val(), 'pw1234<l>', 'check password2 value')
  assert.equal(el.find('[name="password2"]').prop('required'), true, 'check password2 required')
  assert.equal(el.find('[name="password2"]').is(":focus"), false, 'check password2 focus')

  assert.equal(el.find('[name="textarea1"]').val(), 'some used text', 'check textarea1 value')
  assert.equal(el.find('[name="textarea1"]').prop('required'), true, 'check textarea1 required')
  assert.equal(el.find('[name="textarea1"]').is(":focus"), false, 'check textarea1 focus')

  assert.equal(el.find('[name="textarea2"]').val(), 'lalu <l> lalu', 'check textarea2 value')
  assert.equal(el.find('[name="textarea2"]').prop('required'), true, 'check textarea2 required')
  assert.equal(el.find('[name="textarea2"]').is(":focus"), false, 'check textarea2 focus')

  assert.equal(el.find('[name="select1"]').val(), 'false', 'check select1 value')
  assert.equal(el.find('[name="select1"]').prop('required'), false, 'check select1 required')
  assert.equal(el.find('[name="select1"]').is(":focus"), false, 'check select1 focus')

  assert.equal(el.find('[name="select2"]').val(), 'false', 'check select2 value')
  assert.equal(el.find('[name="select2"]').prop('required'), false, 'check select2 required')
  assert.equal(el.find('[name="select2"]').is(":focus"), false, 'check select2 focus')

  assert.equal(el.find('[name="selectmulti2"]').val()[0], 'true', 'check selectmulti2 value')
  assert.equal(el.find('[name="selectmulti2"]').val()[1], 'false', 'check selectmulti2 value')
  assert.equal(el.find('[name="selectmulti2"]').prop('required'), true, 'check selectmulti2 required')
  assert.equal(el.find('[name="selectmulti2"]').is(":focus"), false, 'check selectmulti2 focus')

});

QUnit.test("form dependend fields check", assert => {
//    assert.deepEqual(item, test.value, 'group set/get tests' );

// mix default and params -> check it -> add note
// test auto completion
// show/hide fields base on field values -> bind changed event
// form validation
// form params check

// add signature only if form_state is empty
  $('#qunit').append('<hr><h1>form dependend fields check</h1><form id="form4"></form>')
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
  assert.equal(el.find('[name="input1"]').val(), '', 'check input1 value')
  assert.equal(el.find('[name="input1"]').prop('required'), false, 'check input1 required')
//  assert.equal(el.find('[name="input1"]').is(":focus"), true, 'check input1 focus')
  assert.equal(el.find('[name="input2"]').val(), 'some used default', 'check input2 value')
  assert.equal(el.find('[name="input2"]').prop('required'), false, 'check input2 required')

  assert.equal(el.find('[name="input3"]').val(), 'some used default', 'check input3 value')
  assert.equal(el.find('[name="input3"]').prop('required'), false, 'check input3 required')

  assert.equal(el.find('[name="select1"]').val(), 'false', 'check select1 value')
  assert.equal(el.find('[name="select1"]').prop('required'), false, 'check select1 required')
  assert.equal(el.find('[name="select1"]').is(":focus"), false, 'check select1 focus')

  assert.equal(el.find('[name="select2"]').val(), 'false', 'check select2 value')
  assert.equal(el.find('[name="select2"]').prop('required'), false, 'check select2 required')
  assert.equal(el.find('[name="select2"]').is(":focus"), false, 'check select2 focus')

  assert.equal(el.find('[name="selectmulti2"]').val()[0], 'true', 'check selectmulti2 value')
  assert.equal(el.find('[name="selectmulti2"]').val()[1], 'false', 'check selectmulti2 value')
  assert.equal(el.find('[name="selectmulti2"]').prop('required'), true, 'check selectmulti2 required')
  assert.equal(el.find('[name="selectmulti2"]').is(":focus"), false, 'check selectmulti2 focus')

  var params = App.ControllerForm.params(el)
  var test_params = {
    input1: "",
    input2: "some used default",
    input3: "some used default",
    select1: "false",
    select2: "false",
    selectmulti2: [ "true", "false" ],
    selectmultioption1: [ "false" ],
    datetime1: '2015-01-11T12:40:00.000Z',
    datetime2: null,
    datetime3: '2015-01-11T12:40:00.000Z',
    datetime4: null,
    date1: '2015-01-11',
    date2: null,
    date3: '2015-01-11',
    date4: null,
  }
  assert.deepEqual(params, test_params, 'form param check 2')

  errors = form.validate(params)
  test_errors = {
    datetime4: "is required",
    date4:     "is required",
  }
  assert.deepEqual(errors, test_errors, 'validation errors check')
  App.ControllerForm.validate({ errors: errors, form: el })

  el.find('[name="select1"]').val('true')
  el.find('[name="select1"]').trigger('change')
  params = App.ControllerForm.params(el)
  test_params = {
    input1: "",
    input2: "some used default",
    input3: "some used default",
    select1: "true",
    select2: "false",
    selectmulti2: [ "true", "false" ],
    selectmultioption1: [ "false" ],
    datetime1: '2015-01-11T12:40:00.000Z',
    datetime2: null,
    datetime3: '2015-01-11T12:40:00.000Z',
    datetime4: null,
    date1: '2015-01-11',
    date2: null,
    date3: '2015-01-11',
    date4: null,
  }
  assert.deepEqual(params, test_params, 'form param check 3')
});

QUnit.test("form handler check with and without fieldset", assert => {
//    assert.deepEqual(item, test.value, 'group set/get tests' );

// mix default and params -> check it -> add note
// test auto completion
// show/hide fields base on field values -> bind changed event
// form validation
// form params check

// add signature only if form_state is empty
  $('#qunit').append('<hr><h1>form handler check with and without fieldset</h1><form id="form5"></form>')
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
  assert.equal(el.find('[name="select1"]').val(), 'a', 'check select1 value')
  assert.equal(el.find('[name="select1"]').prop('required'), false, 'check select1 required')

  assert.equal(el.find('[name="select2"]').val(), '1', 'check select2 value')
  assert.equal(el.find('[name="select2"]').prop('required'), false, 'check select2 required')

  var params = App.ControllerForm.params(el)
  var test_params = {
    select1: 'a',
    select2: '1',
  }
  assert.deepEqual(params, test_params, 'form param check 4')
  el.find('[name="select1"]').val('b')
  el.find('[name="select1"]').trigger('change')
  params = App.ControllerForm.params(el)
  test_params = {
    select1: 'b',
    select2: '3',
  }
  assert.deepEqual(params, test_params, 'form param check 5')
  el.find('[name="select1"]').val('a')
  el.find('[name="select1"]').trigger('change')
  params = App.ControllerForm.params(el)
  test_params = {
    select1: 'a',
    select2: '1',
  }
  assert.deepEqual(params, test_params, 'form param check 6')

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
  assert.equal(el.find('[name="select1"]').val(), 'a', 'check select1 value')
  assert.equal(el.find('[name="select1"]').prop('required'), false, 'check select1 required')

  assert.equal(el.find('[name="select2"]').val(), '1', 'check select2 value')
  assert.equal(el.find('[name="select2"]').prop('required'), false, 'check select2 required')

  var params = App.ControllerForm.params(el)
  var test_params = {
    select1: 'a',
    select2: '1',
  }
  assert.deepEqual(params, test_params, 'form param check 7')
  el.find('[name="select1"]').val('b')
  el.find('[name="select1"]').trigger('change')
  params = App.ControllerForm.params(el)
  test_params = {
    select1: 'b',
    select2: '3',
  }
  assert.deepEqual(params, test_params, 'form param check 8')
  el.find('[name="select1"]').val('a')
  el.find('[name="select1"]').trigger('change')
  params = App.ControllerForm.params(el)
  test_params = {
    select1: 'a',
    select2: '1',
  }
  assert.deepEqual(params, test_params, 'form param check 9')

});

QUnit.test("form postmaster filter", assert => {

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

  $('#qunit').append('<hr><h1>form postmaster filter</h1><form id="form6"></form>')
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
        { name: 'set',    display: 'Set',    tag: 'postmaster_set', null: false, default: false, user_action: false},
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
  assert.deepEqual(params, test_params, 'form param check 10')

  el.find('[name="set::x-zammad-ticket-priority_id::value"]').closest('.js-filterElement').find('.js-remove').trigger('click')
  el.find('[name="set::x-zammad-ticket-customer_id::value"]').closest('.js-filterElement').find('.js-remove').trigger('click')

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
  assert.deepEqual(params, test_params, 'form param check 11')

  el.find('.postmaster_set .js-filterElement').last().find('.filter-controls .js-add').trigger('click')

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
      'x-zammad-ticket-title': {
        value: ''
      },
    },
  };
  assert.deepEqual(params, test_params, 'form param check 12')

  App.Delay.set(function() {
    QUnit.test("form postmaster filter - needed to do delayed because of tag ui", assert => {
      el.find('[name="set::x-zammad-ticket-tags::value"]').closest('.js-filterElement').find('.token .close').last().trigger('click')
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
      assert.deepEqual(params, test_params, 'form param check 13')
    })
  }, 500);
});

QUnit.test("form selector", assert => {
  $('#qunit').append('<hr><h1>form selector</h1><div><form id="form7"></form></div>')
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
  assert.deepEqual(params, test_params, 'form param check 14 via $("#form")')

  params = App.ControllerForm.params(el.find('input'))
  assert.deepEqual(params, test_params, 'form param check 15 via $("#form").find("input")')

  params = App.ControllerForm.params(el.parent())
  assert.deepEqual(params, test_params, 'form param check 16 via $("#form").parent()')

});

QUnit.test("form params check 2", assert => {

  $('#qunit').append('<hr><h1>form params check</h1><form id="form9"></form>')
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
  assert.deepEqual(params, test_params, 'form param check 17')

});

QUnit.test("form params check direct", assert => {

  $('#qunit').append('<hr><h1>form params check direct</h1><form id="form10"><input name="a" value="b"><input name="l::l::l1" value="d"><input name="l::l::" value><input name="f::f::" value><input name="f::f::f1" value="e"></form>')
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
  assert.deepEqual(params, test_params, 'form param check 18')
});

QUnit.test("object manager form 1", assert => {

  $('#qunit').append('<hr><h1>object manager 1</h1><form id="form11"></form>')
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
      linktemplate: "",
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

  assert.deepEqual(params, test_params, 'form param check 19')

  el.find('[name=data_type]').val('datetime').trigger('change')

  params = App.ControllerForm.params(el)
  var test_params = {
    data_option: {
      diff: null,
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
  assert.deepEqual(params, test_params, 'form param check 20')

});

QUnit.test("object manager form 2", assert => {

  $('#qunit').append('<hr><h1>object manager 2</h1><form id="form12"></form>')
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
      linktemplate: "",
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

  assert.deepEqual(params, test_params, 'form param check 21')

});

QUnit.test("object manager form 3", assert => {

  $('#qunit').append('<hr><h1>object manager 3</h1><form id="form13"></form>')
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
      linktemplate: "",
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

  assert.deepEqual(params, test_params, 'form param check 22')

  el.find('[name="screens::create_middle::ticket.customer::shown"]').trigger('click')
  el.find('[name="screens::edit::ticket.customer::shown"]').trigger('click')

  params = App.ControllerForm.params(el)
  test_params = {
    data_option: {
      default: "",
      linktemplate: "",
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
  assert.deepEqual(params, test_params, 'form param check 23')

});

QUnit.test("check if select value is not existing but is shown", assert => {

  $('#qunit').append('<hr><h1>check if select value is not existing but is shown</h1><form id="form17"></form>')
  var el = $('#form17')
  var defaults = {
    select1: 'NOT EXISTING',
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'select1', display: 'Select1', tag: 'select', null: true, default: 'XY', options: { 'XX': 'AA', 'A': 'XX', 'B': 'B', 'XY': 'b', '': 'äöü' } },
      ],
    },
    params: defaults,
  });

  params = App.ControllerForm.params(el)
  test_params = {
    select1: 'NOT EXISTING',
  }
  assert.deepEqual(params, test_params)

  assert.equal('AA', el.find('[name=select1] option')[0].text)
  assert.equal('äöü', el.find('[name=select1] option')[1].text)
  assert.equal('b', el.find('[name=select1] option')[2].text)
  assert.equal('B', el.find('[name=select1] option')[3].text)
  assert.equal('NOT EXISTING', el.find('[name=select1] option')[4].text)
  assert.equal('XX', el.find('[name=select1] option')[5].text)

});

QUnit.test("check if select value is not existing and is not shown", assert => {

  $('#qunit').append('<hr><h1>check if select value is not existing and is not shown</h1><form id="form18"></form>')
  var el = $('#form18')
  var defaults = {
    select1: 'NOT EXISTING',
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'select1', display: 'Select1', tag: 'select', null: true, default: 'XY', options: { 'XX': 'AA', 'A': 'XX', 'B': 'B', 'XY': 'b', '': 'äöü' } },
      ],
    },
    params: defaults,
    rejectNonExistentValues: true,
  });

  params = App.ControllerForm.params(el)
  test_params = {
    select1: 'XY',
  }
  assert.deepEqual(params, test_params)

  assert.equal('AA', el.find('[name=select1] option')[0].text)
  assert.equal('äöü', el.find('[name=select1] option')[1].text)
  assert.equal('b', el.find('[name=select1] option')[2].text)
  assert.equal('B', el.find('[name=select1] option')[3].text)
  assert.equal('XX', el.find('[name=select1] option')[4].text)

});

QUnit.test("time range form 1", assert => {

  $('#qunit').append('<hr><h1>time range form 1</h1><form id="form14"></form>')
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

  assert.deepEqual(params, test_params, 'base form param range check')

  el.find('.js-range').val('minute').trigger('change')
  el.find('.js-valueRangeSelector .js-value').val('120').trigger('change')

  params = App.ControllerForm.params(el)
  test_params = {
    "time_range": {
      "range": "minute",
      "value": "120"
    }
  }
  assert.deepEqual(params, test_params, 'form param minute range check')

  el.find('.js-range').val('hour').trigger('change')
  el.find('.js-valueRangeSelector .js-value').val('48').trigger('change')

  params = App.ControllerForm.params(el)
  test_params = {
    "time_range": {
      "range": "hour",
      "value": "48"
    }
  }
  assert.deepEqual(params, test_params, 'form param hour range check')

  el.find('.js-range').val('day').trigger('change')
  el.find('.js-valueRangeSelector .js-value').val('31').trigger('change')

  params = App.ControllerForm.params(el)
  test_params = {
    "time_range": {
      "range": "day",
      "value": "31"
    }
  }
  assert.deepEqual(params, test_params, 'form param day range check')

  el.find('.js-range').val('month').trigger('change')
  el.find('.js-valueRangeSelector .js-value').val('12').trigger('change')

  params = App.ControllerForm.params(el)
  test_params = {
    "time_range": {
      "range": "month",
      "value": "12"
    }
  }
  assert.deepEqual(params, test_params, 'form param month range check')

  el.find('.js-range').val('year').trigger('change')
  el.find('.js-valueRangeSelector .js-value').val('20').trigger('change')

  params = App.ControllerForm.params(el)
  test_params = {
    "time_range": {
      "range": "year",
      "value": "20"
    }
  }
  assert.deepEqual(params, test_params, 'form param year range check')

  el.find('.js-range').val('minute').trigger('change')
  el.find('.js-valueRangeSelector .js-value').val('11').trigger('change')

  el.find('.js-range').val('hour').trigger('change')

  params = App.ControllerForm.params(el)
  test_params = {
    "time_range": {
      "range": "hour",
      "value": "11"
    }
  }
  assert.deepEqual(params, test_params, 'form param selected value hour check')

  el.find('.js-range').val('day').trigger('change')

  params = App.ControllerForm.params(el)
  test_params = {
    "time_range": {
      "range": "day",
      "value": "11"
    }
  }
  assert.deepEqual(params, test_params, 'form param selected value day check')

  el.find('.js-range').val('month').trigger('change')

  params = App.ControllerForm.params(el)
  test_params = {
    "time_range": {
      "range": "month",
      "value": "11"
    }
  }
  assert.deepEqual(params, test_params, 'form param selected value month check')

  el.find('.js-range').val('year').trigger('change')

  params = App.ControllerForm.params(el)
  test_params = {
    "time_range": {
      "range": "year",
      "value": "11"
    }
  }
  assert.deepEqual(params, test_params, 'form param selected value year check')
});

QUnit.test("form select with empty option list", assert => {

  $('#qunit').append('<hr><h1>form select with empty option list</h1><form id="form15"></form>')
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
  assert.deepEqual(params, test_params)
});

QUnit.test("form elements with sort check", assert => {

  $('#qunit').append('<hr><h1>form elements with sort check</h1><form id="form16"></form>')
  var el = $('#form16')
  var defaults = {}
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'select1', display: 'Select1', tag: 'select', null: true, default: 'XY', options: { 'XX': 'AA', 'A': 'XX', 'B': 'B', 'XY': 'b', '': 'äöü' } },
        { name: 'checkbox1', display: 'Checkbox1', tag: 'checkbox', null: false, default: 'A', options: { 'XX': 'AA', 'A': 'XX', 'B': 'B', 'XY': 'b', '': 'äöü' } },
        { name: 'radio1', display: 'Radio1', tag: 'radio', null: false, default: 'A', options: { 'XX': 'AA', 'A': 'XX', 'B': 'B', 'XY': 'b', '': 'äöü' } },
      ],
    },
    params: defaults,
    autofocus: true
  });

  params = App.ControllerForm.params(el)
  test_params = {
    select1: 'XY',
    checkbox1: 'A',
    radio1: 'A',
  }
  assert.deepEqual(params, test_params)

  assert.equal('AA', el.find('[name=select1] option')[0].text)
  assert.equal('äöü', el.find('[name=select1] option')[1].text)
  assert.equal('b', el.find('[name=select1] option')[2].text)
  assert.equal('B', el.find('[name=select1] option')[3].text)
  assert.equal('XX', el.find('[name=select1] option')[4].text)

  assert.equal('XX', el.find('[name=checkbox1]')[0].value)
  assert.equal('', el.find('[name=checkbox1]')[1].value)
  assert.equal('XY', el.find('[name=checkbox1]')[2].value)
  assert.equal('B', el.find('[name=checkbox1]')[3].value)
  assert.equal('A', el.find('[name=checkbox1]')[4].value)

  assert.equal('XX', el.find('[name=radio1]')[0].value)
  assert.equal('', el.find('[name=radio1]')[1].value)
  assert.equal('XY', el.find('[name=radio1]')[2].value)
  assert.equal('B', el.find('[name=radio1]')[3].value)
  assert.equal('A', el.find('[name=radio1]')[4].value)

});

QUnit.test("form deep nesting", assert => {
  $('#qunit').append('<hr><h1>form selector</h1><div><form id="form19"></form></div>')
  var el = $('#form19')
  var defaults = {
    a: {
      input1: 'a'
    },
    b: {
      c: {
        input2: 'b'
      }
    }
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'a::input1', display: 'Input1', tag: 'input', type: 'text', limit: 100, null: true, default: 'some not used default33' },
        { name: 'b::c::input2', display: 'Input2', tag: 'input', type: 'text', limit: 100, null: true, default: 'some used default' },
      ],
    },
    params: defaults,
  });

  params = App.ControllerForm.params(el)
  assert.deepEqual(params, defaults, 'nested params')
});

QUnit.test("form with external links", assert => {
  $('#qunit').append('<hr><h1>form with external links</h1><div><form id="form20"></form></div>')
  var el = $('#form20')
  var defaults = {
    a: '133',
    b: 'abc d',
  }
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: 'a', display: 'Input1', tag: 'input', type: 'text', limit: 100, null: true, linktemplate:  "https://example.com/?q=#{ticket.a}" },
        { name: 'b', display: 'Select1', tag: 'select', type: 'text', options: { a: 1, b: 2 }, limit: 100, null: true, linktemplate:  "https://example.com/?q=#{ticket.b}" },
      ],
      className: 'Ticket',
    },
    params: defaults,
  });

  params = App.ControllerForm.params(el)
  assert.deepEqual(params, defaults)
  assert.equal('https://example.com/?q=133', el.find('input[name="a"]').parents('.controls').find('a[href]').attr('href'))
  assert.equal('https://example.com/?q=abc%20d', el.find('select[name="b"]').parents('.controls').find('a[href]').attr('href'))
});

QUnit.test("Fixes #4024 - Tree select value cannot be set to \"-\" (empty) with Trigger/Scheduler/Core workflow.", assert => {
  $('#qunit').append('<hr><h1>Fixes #4024 - Tree select value cannot be set to "-" (empty) with Trigger/Scheduler/Core workflow.</h1><form id="form22"></form>')
  var el = $('#form22')
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: '4024_select', display: '4024_select', tag: 'select_search', null: true, nulloption: true, multiple: true, options: { 'a': 'a', 'b': 'b' } },
        { name: '4024_multiselect', display: '4024_multiselect', tag: 'multiselect_search', null: true, nulloption: true, multiple: true, options: { 'a': 'a', 'b': 'b' } },
        { name: '4024_tree_select', display: '4024_tree_select', tag: 'tree_select_search', null: true, nulloption: true, multiple: true, options: [{ 'value': 'a', 'name': 'a'}, { 'value': 'b', 'name': 'b'}] },
        { name: '4024_multi_tree_select', display: '4024_multi_tree_select', tag: 'multi_tree_select', null: true, nulloption: true, multiple: true, options: [{ 'value': 'a', 'name': 'a'}, { 'value': 'b', 'name': 'b'}] },
      ],
    },
    autofocus: true
  });

  assert.equal(el.find('select[name="4024_select"] option[value=""]').text(), '-', '4024_select has nulloption')
  assert.equal(el.find('select[name="4024_multiselect"] option[value=""]').text(), '-', '4024_multiselect has nulloption')
  assert.equal(el.find("div[data-attribute-name=4024_tree_select] .js-option[title='-'] .searchableSelect-option-text").text().trim(), '-', '4024_tree_select has nulloption')
  assert.equal(el.find("div[data-attribute-name=4024_multi_tree_select] .js-option[title='-'] .searchableSelect-option-text").text().trim(), '-', '4024_multi_tree_select has nulloption')
});

QUnit.test("Fixes #4027 - undefined method `to_hash` on editing select fields in the admin interface after migration to 5.1.", assert => {
  $('#qunit').append('<hr><h1>Fixes #4027 - undefined method `to_hash` on editing select fields in the admin interface after migration to 5.1.</h1><form id="form23"></form>')
  var el = $('#form23')
  new App.ControllerForm({
    el:        el,
    model:     {
      configure_attributes: [
        { name: '4027_selcet_hash', display: '4027_selcet_hash', tag: 'select', null: true, nulloption: true, options: { 'a': 'a', 'b': 'b' }, value: 'c', historical_options: { c: 'C' } },
        { name: '4027_selcet_array', display: '4027_selcet_array', tag: 'select', null: true, nulloption: true, options: [{ value: 'a', name: 'a' }, { value: 'b', name: 'b' } ], value: 'c', historical_options: { c: 'C' } },
        { name: '4027_multiselect_hash', display: '4027_multiselect_hash', tag: 'multiselect', null: true, nulloption: true, options: { 'a': 'a', 'b': 'b' }, value: ['c'], historical_options: { c: 'C' } },
        { name: '4027_multiselect_array', display: '4027_multiselect_array', tag: 'multiselect', null: true, nulloption: true, options: [{ value: 'a', name: 'a' }, { value: 'b', name: 'b' } ], value: ['c', 'd'], historical_options: { c: 'C', d: 'D' } },
        { name: '4027_tree_select_array', display: '4027_tree_select_array', tag: 'tree_select', null: true, nulloption: true, options: [{ value: 'a', name: 'a' }, { value: 'b', name: 'b' } ], value: 'b::c', historical_options: { 'b::c': 'C' } },
      ],
    },
    autofocus: true
  });

  assert.equal(el.find('select[name="4027_selcet_hash"] option[selected]').text(), 'C', '4027_select has historic text')
  assert.equal(el.find('select[name="4027_selcet_array"] option[selected]').text(), 'C', '4027_selcet_array has historic text')
  assert.equal(el.find('select[name="4027_multiselect_hash"] option[selected]').text(), 'C', '4027_multiselect_hash has historic text')
  assert.equal(el.find('select[name="4027_multiselect_array"] option[selected]').text(), 'CD', '4027_multiselect_array has historic text')
  assert.equal(el.find('div[data-attribute-name="4027_tree_select_array"] .js-input').val(), 'C', '4027_tree_select_array has historic text')
});
