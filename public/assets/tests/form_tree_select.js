test("form elements check", function() {
  $('#forms').append('<hr><h1>form elements check</h1><form id="form1"></form>')
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
  equal(el.find('[name="tree_select"]').val(), '', 'check tree_select value');
  equal(el.find('[name="tree_select"]').closest('.searchableSelect').find('.js-input').val(), '', 'check tree_select .js-input value');
  var params = App.ControllerForm.params(el)
  var test_params = {
    tree_select: ''
  }
  deepEqual(params, test_params, 'form param check')

  $('#forms').append('<hr><h1>form elements check</h1><form id="form2"></form>')
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

  equal(el.find('[name="tree_select"]').val(), 'aa', 'check tree_select value');
  equal(el.find('[name="tree_select"]').closest('.searchableSelect').find('.js-input').val(), 'yes', 'check tree_select .js-input value');
  var params = App.ControllerForm.params(el)
  var test_params = {
    tree_select: 'aa'
  }
  deepEqual(params, test_params, 'form param check')

  $('#forms').append('<hr><h1>form elements check</h1><form id="form3"></form>')
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
  equal(el.find('[name="tree_select"]').val(), 'aa::aab', 'check tree_select value');
  equal(el.find('[name="tree_select"]').closest('.searchableSelect').find('.js-input').val(), 'yes2', 'check tree_select .js-input value');
  var params = App.ControllerForm.params(el)
  var test_params = {
    tree_select: 'aa::aab'
  }
  deepEqual(params, test_params, 'form param check')

  $('#forms').append('<hr><h1>form elements check</h1><form id="form4"></form>')
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
    tree_select_search: ['aa::aab', 'aa::aac::33', 'bb'],
  }
  deepEqual(params, test_params, 'form param check')

});

asyncTest("searchable_select submenu and option list check", function() {
  expect(3);


  $('#forms').append('<hr><h1>form elements check</h1><form id="form5"></form>')
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

  el.find("[name=\"tree_select\"].js-shadow + .js-input").click()
  el.find(".searchableSelect .js-optionsList [data-value=\"a\\\\a\"]").mouseenter().click()
  el.find(".searchableSelect .js-optionsSubmenu [data-value=\"a\\\\a::aab\"]").mouseenter().click()
  el.find("[name=\"tree_select\"].js-shadow + .js-input").click()

  var params = App.ControllerForm.params(el)
  var test_params = {
    tree_select: 'a\\a::aab'
  }

  var optionsSubmenu = el.find(".searchableSelect [data-parent-value=\"a\\\\a\"].js-optionsSubmenu")
  var optionsList = el.find(".searchableSelect .js-optionsList")

  setTimeout( () => {
    deepEqual(params, test_params, 'form param check')
    equal(optionsSubmenu.is('[hidden]'), false, 'options submenu menu not hidden')
    equal(optionsList.is('[hidden]'), true, 'options list is hidden')
    start();
  }, 300)

});
