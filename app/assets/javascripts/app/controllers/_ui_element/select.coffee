# coffeelint: disable=camel_case_classes
class App.UiElement.select extends App.UiElement.ApplicationUiElement
  @render: (attributeConfig, params, form = {}) ->
    attribute = $.extend(true, {}, attributeConfig)

    # set multiple option
    if attribute.multiple
      attribute.multiple = 'multiple'
    else
      attribute.multiple = ''

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

    item = $( App.view('generic/select')(attribute: attribute) )

    # bind event listeners
    @bindEventListeners(item, attribute, params)

    # return item
    item

  @bindEventListeners: (item, attribute, params) ->
    if attribute.display_warn
      item.on('change', (e) =>
        @bindWarnDisplayListener(e.target.value, attribute, params, item)
      )

      # initialization for default selection
      @bindWarnDisplayListener(attribute.value, attribute, params, item)

  @bindWarnDisplayListener: (selectedVal, attribute, params, item) ->
    warn_visible = @shouldDisplayWarn(selectedVal, attribute, params)
    @toggleDisplayWarn(warn_visible, attribute, item)

  @shouldDisplayWarn: (selectedVal, attribute, params) ->
    return if !selectedVal
    return if !params

    params[attribute.name + '_is_display_warning']?(selectedVal)

  @toggleDisplayWarn: (warn_visible, attribute, item) ->
    if !warn_visible
      item.removeClass('display-warn')
      item.find('.alert--warning').remove()
      return

    item.addClass('display-warn')
    warn_elem = $('<div class="alert alert--warning" role="alert"></div>')
    warn_elem.html(attribute.warn)
    item.append(warn_elem)

