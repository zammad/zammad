class App.SearchableMultipleSelect extends App.SearchableAjaxSelect

  events:
    'click .selected_item':      'testClick'

  elements:
    '.items':                     'itemList'

  render: ->
    @attribute.valueName = ''
    organizations = {}
    for value in @attribute.value
      organizations[value] = App.Organization.findNative(value).name
    @attribute.organizations = organizations

    @html App.view('generic/searchable_multiple_select')
      attribute: @attribute
      options: @renderAllOptions '', @attribute.options, 0
      submenus: @renderSubmenus @attribute.options

    # initial data
    @currentMenu = @findMenuContainingValue @attribute.value
    @level = @getIndex @currentMenu

  selectItem: (event) ->
    return if !event.currentTarget.textContent
    @input.val event.currentTarget.textContent.trim()
    @input.trigger('change')
    data_value = event.currentTarget.getAttribute('data-value')
    @input.val ''
    js_shadow_ids = $('.js-shadow-ids')
    ids = []
    if js_shadow_ids.length > 0
      js_shadow_ids.each( -> ids.push $(this).val() )
    if !ids.includes(data_value) && $(".js-shadow[name='"+@attribute.name+"']").val() != data_value
      html = App.view('generic/searchable_multiple_select_item')
        title: event.currentTarget.getAttribute('title')
        data_value: parseInt(data_value)
        name: @attribute.name
      @itemList.append html

  testClick: (event) ->
    $(event.currentTarget).closest('div').remove()