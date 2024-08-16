class App.ChecklistItem extends App.Model
  @configure 'ChecklistItem', 'text', 'checked', 'ticket_id', 'checklist_id', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/checklist_items'

  @configure_attributes = [
    { name: 'text', display: __('Name'), tag: 'input', type: 'text', limit: 100, null: false, parentClass: 'checklistItemNameCell' },
    { name: 'created_at', display: __('Created at'), tag: 'datetime', readonly: 1 },
    { name: 'updated_at', display: __('Updated at'), tag: 'datetime', readonly: 1 },
  ]
