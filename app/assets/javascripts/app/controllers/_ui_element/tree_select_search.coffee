# coffeelint: disable=camel_case_classes
class App.UiElement.tree_select_search extends App.UiElement.ApplicationUiElement
  @render: (localAttribute, params) ->

    # clone original attribute
    attribute = clone(localAttribute)

    # set multiple option
    attribute.multiple = 'multiple'

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

  @sortOptions: (attribute, params) ->

    options = []

    @getSub(options, attribute.options, params)

    attribute.options = options

  @getSub: (options, localRow, params) ->
    for row in localRow
      length = row.value.split('::').length
      prefix = ''
      if length > 1
        for count in [2..length]
          prefix += '> '
      row.name = "#{prefix}#{row.name}"

      options.push row

      if row.children
        @getSub(options, row.children, params)
