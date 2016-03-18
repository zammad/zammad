# coffeelint: disable=camel_case_classes
class App.UiElement.boolean extends App.UiElement.ApplicationUiElement
  @render: (attribute, params) ->

    # build options list
    if _.isEmpty(attribute.options)
      attribute.options = [
        { name: 'yes', value: true }
        { name: 'no', value: false }
      ]

    # set data type
    if attribute.name
      attribute.name = '{boolean}' + attribute.name

    # build options list based on config
    @getConfigOptionList(attribute, params)

    # sort attribute.options
    @sortOptions(attribute, params)

    # finde selected/checked item of list
    @selectedOptions(attribute, params)

    # return item
    $(App.view('generic/select')(attribute: attribute))