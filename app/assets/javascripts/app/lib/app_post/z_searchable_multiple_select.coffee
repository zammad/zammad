class App.SearchableMultipleSelect extends App.SearchableAjaxSelect

  render: ->
    @attribute.valueName = ''

    @html App.view('generic/searchable_select_multiply')
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
    if @shadowInput.length == 0
      @input.val ''
      js_shadow_ids = $('.js-shadow-ids')
      ids = []
      if js_shadow_ids.length > 0
        js_shadow_ids.each( -> ids.push $(this).val() )
      if !ids.includes(data_value) && $(".js-shadow[name='organization_id']").val() != data_value
        newInput = @input.closest('.searchableSelect').find('div.items')
        input = "<input class='searchableSelect-shadow form-control js-shadow-ids' name='organization_ids'>"
        wrapper = $("<div></div>").appendTo(newInput)
        @span = $("<span class='selected_organization'>#{event.currentTarget.getAttribute('title')}</span>").appendTo( wrapper )
        @input = $(input).appendTo( wrapper )
        @input.val data_value
        @input.trigger('change')
      $('span.selected_organization').click ->
        $(this).closest('div').remove()
    else
      @shadowInput.val data_value
      @shadowInput.trigger('change')
      $(".js-shadow-ids").each( ->
        if $(this).val() == data_value
          $(this).closest('div').remove()
      )