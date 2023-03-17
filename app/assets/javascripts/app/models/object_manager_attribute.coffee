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

  # This function will return all attributes
  # based on the frontend model attributes combined
  # with object manager attributes which are merged like
  # in app/models/object_manager/element/backend.rb.
  @selectorAttributesByObject: ->
    result = {}
    for row in @all()
      continue if !row.object

      config     = $.extend(true, {}, row)
      config.tag = config.data_type
      config     = Object.assign({}, config, config.data_option) if config.data_option

      result[config.object] ||= []
      result[config.object].push(config)

    for object in Object.keys(result)
      continue if !App[object]
      continue if !App[object].configure_attributes

      names = _.map(result[object], (row) -> row.name)
      for row in App[object].configure_attributes
        continue if _.contains(names, row.name)
        result[object].push(_.clone(row))

    result
