class App.Macro extends App.Model
  @configure 'Macro', 'name', 'perform', 'ux_flow_next_up', 'note', 'group_ids', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/macros'
  @configure_attributes = [
    { name: 'name',            display: 'Name',              tag: 'input', type: 'text', limit: 100, null: false },
    { name: 'perform',         display: 'Actions',           tag: 'ticket_perform_action',           null: true
    },
    { name: 'ux_flow_next_up', display: 'Once completed...', tag: 'select', default: 'none', options: {
        none: 'Stay on tab', next_task: 'Close tab', next_from_overview: 'Advance to next ticket from overview'
      }
    },
    { name: 'updated_at',      display: 'Updated',  tag: 'datetime',      readonly: 1 },
    { name: 'note',            display: 'Note',     tag: 'textarea',      limit:   250,      null: true },
    { name: 'group_ids',       display: 'Groups',   tag: 'column_select', relation: 'Group', null: true, unsortable: true },
    { name: 'active',          display: 'Active',   tag: 'active',        default: true },
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

  @description = '''
Macros make it easy to automate common, multi-step tasks within Zammad.

You can use macros in Zammad to automate recurring sequences, saving time (and nerves). This allows a combined sequence of actions on the ticket to be executed with just one click.
'''
