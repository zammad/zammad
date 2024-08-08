class App.ChecklistTemplate extends App.Model
  @configure 'ChecklistTemplate', 'name', 'items', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/checklist_templates'

  @configure_attributes = [
    { name: 'name', display: __('Name'),    tag: 'input', type: 'text', maxlength: 255, null: false },
    { name: 'sorted_item_ids', display: __('Items'),   tag: 'checklist_item',  type: 'text' },
    { name: 'active', display: __('Active'),  tag: 'active', default: true },
    { name: 'created_at', display: __('Created at'), tag: 'datetime', readonly: 1 },
    { name: 'updated_at', display: __('Updated at'), tag: 'datetime', readonly: 1 },
  ]

  sorted_items: =>
    App.ChecklistTemplateItem.findAll(@sorted_item_ids)

  @configure_delete = true
  @configure_clone = true
  @configure_overview = [
    'name',
  ]

  @description = __('With checklist templates it is possible to pre-fill new checklists with initial items.')
