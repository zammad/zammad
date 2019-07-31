# coffeelint: disable=camel_case_classes
class App.UiElement.searchable_select extends App.UiElement.ApplicationUiElement
  @render: (attribute, params) ->

    # set multiple option
    if attribute.multiple
      attribute.multiple = 'multiple'
    else
      attribute.multiple = ''

    # build options list based on config
    @getConfigOptionList(attribute, params)

    # build options list based on relation
    @getRelationOptionList(attribute, params)

    # add null selection if needed
    @addNullOption(attribute, params)

    # sort attribute.options
    @sortOptions(attribute, params)

    # find selected/checked item of list
    @selectedOptions(attribute, params)

    # disable item of list
    @disabledOptions(attribute, params)

    # filter attributes
    @filterOption(attribute, params)

    new App.SearchableSelect(attribute: attribute).element()
