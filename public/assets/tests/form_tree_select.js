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

});
