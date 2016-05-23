
# coffeelint: disable=camel_case_classes
class App.UiElement.object_manager_attribute extends App.UiElement.ApplicationUiElement
  @render: (attribute, params = {}) ->
    item = $(App.view('object_manager/attribute')(attribute: attribute))

    updateDataMap = (localParams, localAttribute, localAttributes, localClassname, localForm, localA) =>
      localItem = localForm.closest('.js-data')
      values = []
      values = {a: 123, b: 'aaa'}
      element = $(App.view("object_manager/attribute/#{localParams.data_type}")(
        attribute: attribute
        values: values
      ))
      @[localParams.data_type](element, localParams, params)
      localItem.find('.js-dataMap').html(element)
      localItem.find('.js-dataScreens').html(@dataScreens(attribute, localParams, params))

    options =
      datetime: 'Datetime'
      date: 'Date'
      input: 'Text'
    #  select: 'Select'
    #  boolean: 'Boolean'
    #  integer: 'Integer'
    #  autocompletion: 'Autocompletion (AJAX remote URL)'

    configureAttributes = [
      { name: attribute.name, display: '', tag: 'select', null: false, options: options, translate: true, default: 'input', disabled: attribute.disabled },
    ]
    dataType = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      handlers: [
        updateDataMap,
      ]
      params: params
    )
    item.find('.js-dataType').html(dataType.form)

    item

  @dataScreens: (attribute, localParams, params) ->
    object = params.object
    objects =
      Ticket:
        Customer:
          create:
            shown: true
            required: false
          edit:
            shown: true
            required: false
        Agent:
          create_bottom:
            shown: true
            required: false
          edit:
            shown: true
            required: false
      User:
        Customer:
          create:
            shown: true
            required: false
          view:
            shown: true
          signup:
            shown: false
            required: false
        Agent:
          create:
            shown: true
            required: false
          edit:
            shown: true
            required: false
          view:
            shown: true
          invite_customer:
            show: false
            required: false
        Admin:
          create:
            shown: true
            required: false
          edit:
            shown: true
            required: false
          view:
            shown: true
          invite_agent:
            show: false
            required: false
          invite_customer:
            show: false
            required: false
      Organization:
        Customer:
          view:
            shown: true
        Agent:
          create:
            shown: true
            required: false
          edit:
            shown: true
            required: false
          view:
            shown: true
        Admin:
          create:
            shown: true
            required: false
          edit:
            shown: true
            required: false
          view:
            shown: true
      Group:
        Admin:
          create:
            shown: true
            required: false
          edit:
            shown: true
            required: false
          view:
            shown: true
    init = false
    if params && !params.id
      init = true
    $(App.view('object_manager/screens')(
      attribute: attribute
      data: objects[object]
      params: params
      init: init
    ))

  @input: (item, localParams, params) ->
    configureAttributes = [
      { name: 'data_option::default', display: 'Default', tag: 'input', type: 'text', null: true, default: '' },
    ]
    inputDefault = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::type', display: 'Type', tag: 'select', null: false, default: 'text', options: {text: 'Text', phone: 'Phone', fax: 'Fax', email: 'Email', url: 'Url'}, translate: true },
    ]
    inputType = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::maxlength', display: 'Maxlength', tag: 'integer', null: false, default: 120 },
    ]
    inputMaxlength = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    item.find('.js-inputDefault').html(inputDefault.form)
    item.find('.js-inputType').html(inputType.form)
    item.find('.js-inputMaxlength').html(inputMaxlength.form)

  @datetime: (item, localParams, params) ->
    configureAttributes = [
      { name: 'data_option::future', display: 'Allow future', tag: 'boolean', null: false, default: true },
    ]
    datetimeFuture = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::past', display: 'Allow past', tag: 'boolean', null: false, default: true },
    ]
    datetimePast = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::diff', display: 'Default time Diff (minutes)', tag: 'integer', null: false, default: 24 },
    ]
    datetimeDiff = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    item.find('.js-datetimeFuture').html(datetimeFuture.form)
    item.find('.js-datetimePast').html(datetimePast.form)
    item.find('.js-datetimeDiff').html(datetimeDiff.form)

  @date: (item, localParams, params) ->
    configureAttributes = [
      { name: 'data_option::future', display: 'Allow future', tag: 'boolean', null: false, default: true },
    ]
    dateFuture = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::past', display: 'Allow past', tag: 'boolean', null: false, default: true },
    ]
    datePast = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::diff', display: 'Default time Diff (hours)', tag: 'integer', null: false, default: 24 },
    ]
    dateDiff = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    item.find('.js-dateFuture').html(dateFuture.form)
    item.find('.js-datePast').html(datePast.form)
    item.find('.js-dateDiff').html(dateDiff.form)

  @integer: (item, localParams, params) ->
    configureAttributes = [
      { name: 'data_option::default', display: 'Default', tag: 'integer', null: true, default: '', min: 1 },
    ]
    integerDefault = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::min', display: 'Minimal', tag: 'integer', null: false, default: 0, min: 1 },
    ]
    integerMin = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::max', display: 'Maximal', tag: 'integer', null: false, default: 999999999, min: 2 },
    ]
    integerMax = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    item.find('.js-integerDefault').html(integerDefault.form)
    item.find('.js-integerMin').html(integerMin.form)
    item.find('.js-integerMax').html(integerMax.form)

  @select: (item, localParams, params) ->

  @boolean: (item, localParams, params) ->

  @autocompletion: (item, localParams, params) ->
    configureAttributes = [
      { name: 'data_option::default', display: 'Default', tag: 'input', type: 'text', null: true, default: '' },
    ]
    autocompletionDefault = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::url', display: 'Url (AJAX Endpoint)', tag: 'input', type: 'url', null: false, default: '', placeholder: 'https://example.com/serials' },
    ]
    autocompletionUrl = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )
    configureAttributes = [
      { name: 'data_option::method', display: 'Method (AJAX Endpoint)', tag: 'input', type: 'url', null: false, default: '', placeholder: 'GET' },
    ]
    autocompletionMethod = new App.ControllerForm(
      model:
        configure_attributes: configureAttributes
      noFieldset: true
      params: params
    )

    item.find('.js-autocompletionDefault').html(autocompletionDefault.form)
    item.find('.js-autocompletionUrl').html(autocompletionUrl.form)
    item.find('.js-autocompletionMethod').html(autocompletionMethod.form)
