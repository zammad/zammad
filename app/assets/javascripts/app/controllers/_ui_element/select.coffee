# coffeelint: disable=camel_case_classes
class App.UiElement.select extends App.UiElement.ApplicationUiElement
  @render: (attribute, params) ->

    # set multiple option
    if attribute.multiple
      attribute.multiple = 'multiple'
    else
      attribute.multiple = ''

    # add deleted historical options if required
    @addDeletedOptions(attribute, params)

    # build options list based on config
    @getConfigOptionList(attribute, params)

    # build options list based on relation
    @getRelationOptionList(attribute, params)

    # add null selection if needed
    @addNullOption(attribute, params)

    # sort attribute.options
    @sortOptions(attribute, params)

    # finde selected/checked item of list
    @selectedOptions(attribute, params)

    # disable item of list
    @disabledOptions(attribute, params)

    # filter attributes
    @filterOption(attribute, params)

    # return item
    $( App.view('generic/select')(attribute: attribute) )

  # 1. If attribute.value is not among the current options, then search within historical options
  # 2. If attribute.value is not among current and historical options, then add the value itself as an option
  @addDeletedOptions: (attribute) ->
    return if !_.isEmpty(attribute.relation) # do not apply for attributes with relation, relations will fill options automatically
    value = attribute.value
    return if !value
    return if _.isArray(value)
    return if !attribute.options
    return if !_.isObject(attribute.options)
    return if value of attribute.options
    return if value in (temp for own prop, temp of attribute.options)

    if attribute.historical_options && value of attribute.historical_options
      attribute.options[value] = attribute.historical_options[value]
    else
      attribute.options[value] = value
