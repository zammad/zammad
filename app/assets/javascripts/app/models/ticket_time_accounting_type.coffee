class App.TicketTimeAccountingType extends App.Model
  @configure 'TicketTimeAccountingType', 'name', 'note', 'active', 'updated_by', 'created_by'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/time_accounting/types'
  @configure_translate = true

  @configure_clone          = true
  @configure_set_as_default = true
  @configure_unset_default  = true

  @configure_attributes = [
    { name: 'name',   display: __('Name'),   tag: 'input' },
    { name: 'active', display: __('Active'), tag: 'active',   default: true },
    { name: 'note',   display: __('Note'),   tag: 'textarea', limit: 250, null: true },
  ]

  @configure_overview = [
    'name',
  ]

  @description = __('''
**Activity Types** can be used to group the different ticket time accounting entries together. For example, entries that are relevant to a "Billing" type.

When you enable the recording of the activity type, the users will be able to select a type from this list. Additionally, a column with an associated activity type will be rendered for an entry in the **Activity** table under the **Accounted Time** tab.
''')

  @is_default = (object) ->
    App.Setting.get('time_accounting_type_default') is object.id

  @set_as_default = (object) ->
    App.Setting.set('time_accounting_type_default', object.id, notify: true)

  @unset_default = (object) ->
    return if App.Setting.get('time_accounting_type_default') isnt object.id
    App.Setting.set('time_accounting_type_default', '', notify: true)

  @configure_set_as_default_marker_attribute = 'name'
