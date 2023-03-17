class App.Macro extends App.Model
  @configure 'Macro', 'name', 'perform', 'ux_flow_next_up', 'note', 'group_ids', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/macros'
  @configure_attributes = [
    { name: 'name',            display: __('Name'),              tag: 'input', type: 'text', limit: 100, null: false },
    { name: 'perform',         display: __('Actions'),           tag: 'ticket_perform_action',           null: true
    },
    { name: 'ux_flow_next_up', display: __('Once completed…'), tag: 'select', default: 'none', translate: true, options: {
        none: __('Stay on tab'), next_task: __('Close tab'), next_task_on_close: __('Close tab on ticket close'), next_from_overview: __('Advance to next ticket from overview')
      }
    },
    { name: 'updated_at',      display: __('Updated'),  tag: 'datetime',      readonly: 1 },
    { name: 'note',            display: __('Note'),     tag: 'textarea',      limit:   250,      null: true },
    { name: 'group_ids',       display: __('Groups'),   tag: 'column_select', relation: 'Group', null: true, unsortable: true },
    { name: 'active',          display: __('Active'),   tag: 'active',        default: true },
  ]
  @configure_delete = true
  @configure_clone = true
  @configure_overview = [
    'name',
    'note',
    'group_ids',
  ]

  # get list of macros to show in UI
  @getList: ->
    App.Macro.search(filter: { active: true }, sortBy:'name', order:'ASC')

  @description = __('''
Macros make it easy to automate common, multi-step tasks within Zammad.

You can use macros in Zammad to automate recurring sequences, saving time (and nerves). This allows a combined sequence of actions on the ticket to be executed with just one click.
''')
