QUnit.test("form elements check", assert => {
  $('#forms').append('<hr><h1>form elements check 1</h1><form id="form1"></form>')
  var el = $('#form1')
  new App.ControllerForm({
    el:        el,
    model:     {
      "configure_attributes": [
        {
          "name": "tree_select",
          "display": "tree_select",
          "tag": "tree_select",
          "null": true,
          "translate": true,
          "options": [
            {
              "value": "aa",
              "name": "yes",
              "children": [
                  {
                    "value": "aa::aaa",
                    "name": "yes1",
                  },
                  {
                    "value": "aa::aab",
                    "name": "yes2",
                  },
                  {
                    "value": "aa::aac",
                    "name": "yes3",
                  },
              ]
            },
            {
              "value": "bb",
              "name": "bb (comment)",
              "children": [
                  {
                    "value": "bb::bba",
                    "name": "yes11",
                  },
                  {
                    "value": "bb::bbb",
                    "name": "yes22",
                  },
                  {
                    "value": "bb::bbc",
                    "name": "yes33",
                  },
              ]
            },
          ],
        }
      ]
    },
    autofocus: true
  });
  assert.equal(el.find('[name="tree_select"]').val(), '', 'check tree_select value');
  assert.equal(el.find('[name="tree_select"]').closest('.searchableSelect').find('.js-input').val(), '', 'check tree_select .js-input value');
  var params = App.ControllerForm.params(el)
  var test_params = {
    tree_select: ''
  }
  assert.deepEqual(params, test_params, 'form param check')

  $('#forms').append('<hr><h1>form elements check 2</h1><form id="form2"></form>')
  var el = $('#form2')
  new App.ControllerForm({
    el:        el,
    model:     {
      "configure_attributes": [
        {
          "name": "tree_select",
          "display": "tree_select",
          "tag": "tree_select",
          "null": true,
          "translate": true,
          "value": "aa",
          "options": [
            {
              "value": "aa",
              "name": "yes",
              "children": [
                  {
                    "value": "aa::aaa",
                    "name": "yes1",
                  },
                  {
                    "value": "aa::aab",
                    "name": "yes2",
                  },
                  {
                    "value": "aa::aac",
                    "name": "yes3",
                  },
              ]
            },
            {
              "value": "bb",
              "name": "bb (comment)",
              "children": [
                  {
                    "value": "bb::bba",
                    "name": "yes11",
                  },
                  {
                    "value": "bb::bbb",
                    "name": "yes22",
                  },
                  {
                    "value": "bb::bbc",
                    "name": "yes33",
                  },
              ]
            },
          ],
        }
      ]
    },
    autofocus: true
  });

  assert.equal(el.find('[name="tree_select"]').val(), 'aa', 'check tree_select value');
  assert.equal(el.find('[name="tree_select"]').closest('.searchableSelect').find('.js-input').val(), 'yes', 'check tree_select .js-input value');
  var params = App.ControllerForm.params(el)
  var test_params = {
    tree_select: 'aa'
  }
  assert.deepEqual(params, test_params, 'form param check')

  $('#forms').append('<hr><h1>form elements check 3</h1><form id="form3"></form>')
  var el = $('#form3')
  new App.ControllerForm({
    el:        el,
    model:     {
      "configure_attributes": [
        {
          "name": "tree_select",
          "display": "tree_select",
          "tag": "tree_select",
          "null": true,
          "translate": true,
          "value": "aa::aab",
          "options": [
            {
              "value": "aa",
              "name": "yes",
              "children": [
                  {
                    "value": "aa::aaa",
                    "name": "yes1",
                  },
                  {
                    "value": "aa::aab",
                    "name": "yes2",
                  },
                  {
                    "value": "aa::aac",
                    "name": "yes3",
                  },
              ]
            },
            {
              "value": "bb",
              "name": "bb (comment)",
              "children": [
                  {
                    "value": "bb::bba",
                    "name": "yes11",
                  },
                  {
                    "value": "bb::bbb",
                    "name": "yes22",
                  },
                  {
                    "value": "bb::bbc",
                    "name": "yes33",
                  },
              ]
            },
          ],
        }
      ]
    },
    autofocus: true
  });
  assert.equal(el.find('[name="tree_select"]').val(), 'aa::aab', 'check tree_select value');
  assert.equal(el.find('[name="tree_select"]').closest('.searchableSelect').find('.js-input').val(), 'yes2', 'check tree_select .js-input value');
  var params = App.ControllerForm.params(el)
  var test_params = {
    tree_select: 'aa::aab'
  }
  assert.deepEqual(params, test_params, 'form param check')

  $('#forms').append('<hr><h1>form elements check 4</h1><form id="form4"></form>')
  var el = $('#form4')
  new App.ControllerForm({
    el:        el,
    model:     {
      "configure_attributes": [
        {
          "name": "tree_select_search",
          "display": "tree_select_search",
          "tag": "tree_select_search",
          "null": true,
          "translate": true,
          "multiple": true,
          "value": ['aa::aab', 'bb', 'aa::aac::33'],
          "options": [
            {
              "value": "aa",
              "name": "yes",
              "children": [
                  {
                    "value": "aa::aaa",
                    "name": "yes1",
                  },
                  {
                    "value": "aa::aab",
                    "name": "yes2",
                  },
                  {
                    "value": "aa::aac",
                    "name": "yes3",
                    "children": [
                        {
                          "value": "aa::aaa::11",
                          "name": "11",
                        },
                        {
                          "value": "aa::aa1::22",
                          "name": "22",
                        },
                        {
                          "value": "aa::aac::33",
                          "name": "33",
                        },
                    ]
                  },
              ]
            },
            {
              "value": "bb",
              "name": "bb (comment)",
              "children": [
                  {
                    "value": "bb::bba",
                    "name": "yes11",
                  },
                  {
                    "value": "bb::bbb",
                    "name": "yes22",
                  },
                  {
                    "value": "bb::bbc",
                    "name": "yes33",
                  },
              ]
            },
          ],
        }
      ]
    },
    autofocus: true
  });
  var params = App.ControllerForm.params(el)
  var test_params = {
    tree_select_search: ['aa::aab', 'bb', 'aa::aac::33'],
    tree_select_search_completion: ""
  }
  assert.deepEqual(params, test_params, 'form param check')

  $('#forms').append('<hr><h1>form elements check / tree_select multiple / 3 selected</h1><form id="form6"></form>')
  var el = $('#form6')
  new App.ControllerForm({
    el:        el,
    model:     {
      "configure_attributes": [
        {
          "name": "tree_select",
          "display": "tree_select",
          "tag": "tree_select",
          "null": true,
          "multiple": true,
          "translate": true,
          "value": ['aa::aab', 'bb', 'aa::aac::33'],
          "options": [
            {
              "value": "aa",
              "name": "yes",
              "children": [
                  {
                    "value": "aa::aaa",
                    "name": "yes1",
                  },
                  {
                    "value": "aa::aab",
                    "name": "yes2",
                  },
                  {
                    "value": "aa::aac",
                    "name": "yes3",
                    "children": [
                        {
                          "value": "aa::aaa::11",
                          "name": "11",
                        },
                        {
                          "value": "aa::aa1::22",
                          "name": "22",
                        },
                        {
                          "value": "aa::aac::33",
                          "name": "33",
                        },
                    ]
                  },
              ]
            },
            {
              "value": "bb",
              "name": "bb (comment)",
              "children": [
                  {
                    "value": "bb::bba",
                    "name": "yes11",
                  },
                  {
                    "value": "bb::bbb",
                    "name": "yes22",
                  },
                  {
                    "value": "bb::bbc",
                    "name": "yes33",
                  },
              ]
            },
          ],
        }
      ]
    },
    autofocus: true
  });
  var params = App.ControllerForm.params(el)
  var test_params = {
    tree_select: ['aa::aab', 'bb', 'aa::aac::33'],
    tree_select_completion: "",
  }
  assert.deepEqual(params, test_params, 'form param check')

  $('#forms').append('<hr><h1>form elements check / tree_select multiple / 1 selected</h1><form id="form7"></form>')
  var el = $('#form7')
  new App.ControllerForm({
    el:        el,
    model:     {
      "configure_attributes": [
        {
          "name": "tree_select",
          "display": "tree_select",
          "tag": "tree_select",
          "null": true,
          "multiple": true,
          "translate": true,
          "value": ['aa::aab'],
          "options": [
            {
              "value": "aa",
              "name": "yes",
              "children": [
                  {
                    "value": "aa::aaa",
                    "name": "yes1",
                  },
                  {
                    "value": "aa::aab",
                    "name": "yes2",
                  },
                  {
                    "value": "aa::aac",
                    "name": "yes3",
                    "children": [
                        {
                          "value": "aa::aaa::11",
                          "name": "11",
                        },
                        {
                          "value": "aa::aa1::22",
                          "name": "22",
                        },
                        {
                          "value": "aa::aac::33",
                          "name": "33",
                        },
                    ]
                  },
              ]
            },
            {
              "value": "bb",
              "name": "bb (comment)",
              "children": [
                  {
                    "value": "bb::bba",
                    "name": "yes11",
                  },
                  {
                    "value": "bb::bbb",
                    "name": "yes22",
                  },
                  {
                    "value": "bb::bbc",
                    "name": "yes33",
                  },
              ]
            },
          ],
        }
      ]
    },
    autofocus: true
  });
  var params = App.ControllerForm.params(el)
  var test_params = {
    tree_select: ['aa::aab'],
    tree_select_completion: "",
  }
  assert.deepEqual(params, test_params, 'form param check')
});

QUnit.test("ui elements check", assert => {

  attribute =  {
    "name": "tree_select_search",
    "display": "tree_select_search",
    "tag": "tree_select_search",
    "null": true,
    "translate": true,
    "value": ['bb::bba', 'bb::bbb'],
    "multiple": true,
    "options": [
      {
        "value": "aa",
        "name": "yes",
        "children": [
            {
              "value": "aa::aaa",
              "name": "yes1",
            },
            {
              "value": "aa::aab",
              "name": "yes2",
            },
        ]
      },
      {
        "value": "bb",
        "name": "bb (comment)",
        "children": [
            {
              "value": "bb::bba",
              "name": "yes11",
            },
            {
              "value": "bb::bbb",
              "name": "yes22",
            },
        ]
      },
    ],
  };

  options = [
    {
      "value": "aa",
      "name": "yes",
      "children": [
          {
            "value": "aa::aaa",
            "name": "yes1",
          },
          {
            "value": "aa::aab",
            "name": "yes2",
          },
      ]
    },
    {
      "value": "bb",
      "name": "bb (comment)",
      "children": [
          {
            "value": "bb::bba",
            "name": "yes11",
          },
          {
            "value": "bb::bbb",
            "name": "yes22",
          },
      ]
    }
  ]

  element = App.UiElement.tree_select_search.render(attribute)
  assert.deepEqual(attribute.options, options, 'options tree_select_search')

  attribute.name = 'tree_select'
  attribute.display = 'tree_select'
  attribute.tag = 'tree_select'

  element = App.UiElement.tree_select.render(attribute)
  assert.deepEqual(attribute.options, options, 'options tree_select')
});

QUnit.test("searchable_select submenu and option list check", assert => {
  var done = assert.async()

  $('#forms').append('<hr><h1>form elements check 5</h1><form id="form5"></form>')
  var el = $('#form5')
  new App.ControllerForm({
    el:        el,
    model:     {
      "configure_attributes": [
        {
          "name": "tree_select",
          "display": "tree_select",
          "tag": "tree_select",
          "null": true,
          "translate": true,
          "value": "bb",
          "options": [
            {
              "value": "a\\a",
              "name": "a\\a",
              "children": [
                  {
                    "value": "a\\a::aaa",
                    "name": "aaa",
                  },
                  {
                    "value": "a\\a::aab",
                    "name": "aab",
                  },
                  {
                    "value": "a\\a::aac",
                    "name": "aac",
                  },
              ]
            },
            {
              "value": "bb",
              "name": "bb",
              "children": [
                  {
                    "value": "bb::bba",
                    "name": "bba",
                  },
                  {
                    "value": "bb::bbb",
                    "name": "bbb",
                  },
                  {
                    "value": "bb::bbc",
                    "name": "bbc",
                  },
              ]
            },
          ],
        }
      ]
    },
    autofocus: true
  });

  el.find("[name=\"tree_select\"].js-shadow + .js-input").trigger('click')
  el.find(".searchableSelect .js-optionsList [data-value=\"a\\\\a\"] .searchableSelect-option-arrow").mouseenter().trigger('click')
  el.find(".searchableSelect .js-optionsSubmenu [data-value=\"a\\\\a::aab\"] .searchableSelect-option-text").mouseenter().trigger('click')
  el.find("[name=\"tree_select\"].js-shadow + .js-input").trigger('click')

  var params = App.ControllerForm.params(el)
  var test_params = {
    tree_select: 'a\\a::aab'
  }

  var optionsSubmenu = el.find(".searchableSelect [data-parent-value=\"a\\\\a\"].js-optionsSubmenu")
  var optionsList = el.find(".searchableSelect .js-optionsList")

  setTimeout( () => {
    assert.deepEqual(params, test_params, 'form param check')
    assert.equal(optionsSubmenu.is('[hidden]'), false, 'options submenu menu not hidden')
    assert.equal(optionsList.is('[hidden]'), true, 'options list is hidden')

    done()
  }, 300)

});
