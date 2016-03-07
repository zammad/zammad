class App.Overview extends App.Model
  @configure 'Overview', 'name', 'prio', 'condition', 'order', 'group_by', 'view', 'user_id', 'organization_shared', 'role_id', 'order', 'group_by', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/overviews'
  @configure_attributes = [
    { name: 'name',       display: 'Name',                tag: 'input',    type: 'text', limit: 100, 'null': false },
    { name: 'role_id',    display: 'Available for Role',  tag: 'select',   multiple: false, nulloption: true, null: false, relation: 'Role', translate: true },
    { name: 'user_id',    display: 'Available for User',  tag: 'select',   multiple: true, nulloption: true, null: true,  relation: 'User', sortBy: 'firstname' },
    { name: 'organization_shared', display: 'Only available for Users with shared Organization', tag: 'select', options: { true: 'yes', false: 'no' }, default: false, null: true },
#    { name: 'content',    display: 'Content',             tag: 'textarea',                limit: 250, 'null': false },
    { name: 'condition',  display: 'Conditions for shown Tickets', tag: 'ticket_selector', null: false },
    { name: 'prio',       display: 'Prio',                tag: 'input',    type: 'text', limit: 10, 'null': false },
    {
      name:    'view::s'
      display: 'Attributes'
      tag:     'checkbox'
      default: ['number', 'title', 'state', 'created_at']
      null:    false
      translate: true
      options: [
        {
          value:  'number'
          name:   'Number'
        },
        {
          value:  'title'
          name:   'Title'
        },
        {
          value:  'customer'
          name:   'Customer'
        },
        {
          value:  'state'
          name:   'State'
        },
        {
          value:  'priority'
          name:   'Priority'
        },
        {
          value:  'group'
          name:   'Group'
        },
        {
          value:  'owner'
          name:   'Owner'
        },
        {
          value:  'created_at'
          name:   'Age'
        },
        {
          value:  'last_contact'
          name:   'Last contact'
        },
        {
          value:  'last_contact_agent'
          name:   'Last contact (agent)'
        },
        {
          value:  'last_contact_customer'
          name:   'Last contact (customer)'
        },
        {
          value:  'first_response'
          name:   'First Response'
        },
        {
          value:  'close_time'
          name:   'Close time'
        },
        {
          value:  'article_count'
          name:   'Article Count'
        },
      ]
      class:      'medium'
    },

    {
      name: 'order::by',
      display: 'Order',
      tag:     'select'
      default: 'created_at'
      null:    false
      translate: true
      options:
        number:                 'Number'
        title:                  'Title'
        customer:               'Customer'
        state:                  'State'
        priority:               'Priority'
        group:                  'Group'
        owner:                  'Owner'
        created_at:             'Age'
        last_contact:           'Last contact'
        last_contact_agent:     'Last contact (agent)'
        last_contact_customer:  'Last contact (customer)'
        first_response:         'First Response'
        close_time:             'Close time'
        article_count:          'Article Count'
      class:   'span4'
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
      class:   'span4'
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
      class:   'span4'
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
    'role',
    'prio',
  ]

  @description = '''
Übersichten können Sie Ihren Agenten und Kunden bereitstellen. Sie dienen als eine Art Arbeitslisten von Aufgaben welche der Agent abarbeiten soll.

Sie können auch individuelle Übersichten für einzelne Agenten oder agenten Gruppen erstellen.
'''

  uiUrl: ->
    '#ticket/view/' + @link
