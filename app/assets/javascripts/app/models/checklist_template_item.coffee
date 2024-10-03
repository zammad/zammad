class App.ChecklistTemplateItem extends App.Model
  @configure 'ChecklistTemplateItem', 'text', 'checklist_template_id', 'updated_at'

  @configure_attributes = [
    { name: 'text', display: __('Name'), tag: 'input', type: 'text', limit: 100, null: false, parentClass: 'checklistItemNameCell' },
    { name: 'created_at', display: __('Created at'), tag: 'datetime', readonly: 1 },
    { name: 'updated_at', display: __('Updated at'), tag: 'datetime', readonly: 1 },
  ]
