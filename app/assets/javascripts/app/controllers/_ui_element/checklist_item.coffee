# coffeelint: disable=camel_case_classes
class App.UiElement.checklist_item extends App.UiElement.ApplicationUiElement
  @render: (attributeConfig, params, form = {}) ->
    attribute = $.extend(true, {}, attributeConfig)

    attribute.items = []
    if params && params.sorted_items
      attribute.items = params.sorted_items() || []

    item = $( App.view('generic/checklist_item')(attribute: attribute) )

    dndOptions =
      tolerance:            'pointer'
      distance:             15
      opacity:              0.6
      forcePlaceholderSize: true
      items:                'div.checklist-item'

    item.find('div.checklist-item-container').sortable(dndOptions)

    item.off('keydown', '.checklist-item-add-item-text').on('keydown', '.checklist-item-add-item-text', (e) =>
      return if e.key isnt 'Enter'
      @handleItemAdd(e)
    )

    item.off('click', '.checklist-item-add-button').on('click', '.checklist-item-add-button', (e) => @handleItemAdd(e))
    item.off('click', '.checklist-item-remove-button').on('click', '.checklist-item-remove-button', (e) => @handleItemRemove(e))

    item

  @handleItemRemove: (e) ->
    e.preventDefault()
    e.stopPropagation()

    $(e.target).closest('.checklist-item').remove()

  @handleItemAdd: (e) ->
    e.preventDefault()
    e.stopPropagation()

    current_item = $(e.target).closest('.checklist-item-add-container').find('.checklist-item-add-item-text')

    if current_item.val().length == 0
      return false

    new_item = $('.checklist-item-template').clone()
    new_item.find('input.checklist-item-text').val(current_item.val()).prop('required', true)

    new_item
      .appendTo('.checklist-item-container')
      .removeClass('checklist-item-template')
      .removeClass('hidden')

    current_item.val('')
    current_item.focus()

    # Clear validation errors.
    current_item.closest('.has-error').removeClass('has-error').find('.help-inline').html('')
