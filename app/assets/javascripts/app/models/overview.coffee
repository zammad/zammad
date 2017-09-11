class App.Overview extends App.Model
  @configure 'Overview', 'name', 'prio', 'condition', 'order', 'group_by', 'view', 'user_ids', 'organization_shared', 'role_ids', 'order', 'group_by', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/overviews'
  @configure_attributes = [
    { name: 'name',       display: 'Name',                tag: 'input',    type: 'text', limit: 100, 'null': false },
    { name: 'link',       display: 'Link',                readonly: 1 },
    { name: 'role_ids',   display: 'Available for Role',  tag: 'column_select', multiple: true, null: false, relation: 'Role', translate: true },
    { name: 'user_ids',   display: 'Available for User',  tag: 'column_select', multiple: true, null: true,  relation: 'User', sortBy: 'firstname' },
    { name: 'organization_shared', display: 'Only available for Users with shared Organization', tag: 'select', options: { true: 'yes', false: 'no' }, default: false, null: true },
    { name: 'out_of_office', display: 'Only available for Users which are replacements for other users.', tag: 'select', options: { true: 'yes', false: 'no' }, default: false, null: true },
    { name: 'condition',  display: 'Conditions for shown Tickets', tag: 'ticket_selector', null: false, out_of_office: true },
    { name: 'prio',       display: 'Prio',                readonly: 1 },
    {
      name:    'view::s'
      display: 'Attributes'
      tag:     'checkboxTicketAttributes'
      default: ['number', 'title', 'state', 'created_at']
      null:    false
      translate: true
    },
    {
      name:    'order::by',
      display: 'Order',
      tag:     'selectTicketAttributes'
      default: 'created_at'
      null:    false
      translate: true
    },
    {
      name:    'order::direction'
      display: 'Direction'
      tag:     'select'
      default: 'down'
      null:    false
      translate: true
      options:
        ASC:   'up'
        DESC:  'down'
    },
    {
      name:    'group_by'
      display: 'Group by'
      tag:     'select'
      default: ''
      null:    true
      nulloption: true
      translate:  true
      options:
        customer:               'Customer'
        state:                  'State'
        priority:               'Priority'
        group:                  'Group'
        owner:                  'Owner'
    },
    { name: 'active',         display: 'Active',      tag: 'active', default: true },
    { name: 'created_by_id',  display: 'Created by',  relation: 'User', readonly: 1 },
    { name: 'created_at',     display: 'Created',     tag: 'datetime', readonly: 1 },
    { name: 'updated_by_id',  display: 'Updated by',  relation: 'User', readonly: 1 },
    { name: 'updated_at',     display: 'Updated',     tag: 'datetime', readonly: 1 },
  ]
  @configure_delete = true
  @configure_overview = [
    'name',
    'link',
    'role_ids',
  ]

  @description = '''
Übersichten können Sie Ihren Agenten und Kunden bereitstellen. Sie dienen als eine Art Arbeitslisten von Aufgaben welche der Agent abarbeiten soll.

Sie können auch individuelle Übersichten für einzelne Agenten oder agenten Gruppen erstellen.
'''

  uiUrl: ->
    "#ticket/view/#{@link}"
