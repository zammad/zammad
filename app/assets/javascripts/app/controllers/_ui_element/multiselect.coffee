# coffeelint: disable=camel_case_classes
class App.UiElement.multiselect extends App.UiElement.ApplicationUiElement
  @render: (attributeConfig, params, form = {}) ->
    attribute = $.extend(true, {}, attributeConfig)

    # set multiple option
    attribute.multiple = 'multiple'

    if attribute.class
      attribute.class = "#{attribute.class} multiselect"
    else
      attribute.class = 'multiselect'

    if form.rejectNonExistentValues
      attribute.rejectNonExistentValues = true

    # add deleted historical options if required
    @addDeletedOptions(attribute, params)

    # build options list based on config
    @getConfigCustomSortOptionList(attribute)

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

    # return item
    $( App.view('generic/select')(attribute: attribute) )

  @_selectedOptionsIsSelected: (value, record) ->
    if _.isArray(value)
      for valueItem in value
        if @_selectedOptionsIsSelectedItem(valueItem, record)
          return true
    false
