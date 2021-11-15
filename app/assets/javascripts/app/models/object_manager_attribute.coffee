class App.ObjectManagerAttribute extends App.Model
  @configure 'ObjectManagerAttribute', 'name', 'object', 'display', 'active', 'editable', 'data_type', 'data_option', 'screens', 'position'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/object_manager_attributes'
  @configure_attributes = [
    { name: 'name',       display: __('Name'),     tag: 'input',     type: 'text', limit: 100, null: false },
    { name: 'display',    display: __('Display'),  tag: 'input',     type: 'text', limit: 100, null: false },
    { name: 'object',     display: __('Object'),   tag: 'input',     readonly: 1 },
    { name: 'active',     display: __('Active'),   tag: 'active',    default: true },
    { name: 'data_type',  display: __('Format'),   tag: 'object_manager_attribute', null: false },
    { name: 'updated_at', display: __('Updated'),  tag: 'datetime',  readonly: 1 },
    { name: 'position',   display: __('Position'), tag: 'integer', type: 'number', limit: 100, null: true },
  ]
