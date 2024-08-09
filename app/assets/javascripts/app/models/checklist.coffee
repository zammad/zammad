class App.Checklist extends App.Model
  @configure 'Checklist', 'name', 'items', 'active', 'updated_at'
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
