class App.Checklist extends App.Model
  @configure 'Checklist', 'name', 'sorted_item_ids', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/checklists'

  @configure_attributes = [
    { name: 'name', display: __('Name'),    tag: 'input', type: 'text', maxlength: 255 },
    { name: 'sorted_item_ids', display: __('Items'),   tag: 'checklist_item',  type: 'text' },
    { name: 'created_at', display: __('Created at'), tag: 'datetime', readonly: 1 },
    { name: 'updated_at', display: __('Updated at'), tag: 'datetime', readonly: 1 },
  ]

  sorted_items: =>
    App.ChecklistItem.findAll(@sorted_item_ids)

  open_items: =>
    @sorted_items().filter (item) -> !item.checked

  @calculateState: (ticket) ->
    checklist = App.Checklist.find ticket.checklist_id

    return if !checklist

    {
      all: checklist.sorted_item_ids.length
      open: checklist.open_items().length
    }

  @calculateReferences: (ticket) ->
    return [] if !ticket.referencing_checklist_ids

    App.Checklist
      .findAll(ticket.referencing_checklist_ids)
      .filter (elem) -> !elem.ticket_inaccessible
      .map (elem) -> App.Ticket.findByAttribute 'checklist_id', elem.id
      .filter (elem) -> !!elem
