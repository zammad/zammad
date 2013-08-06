class App.Overview extends Spine.Model
  @configure 'Overview', 'name', 'link', 'prio', 'condition', 'order', 'group_by', 'view', 'user_id', 'organization_shared', 'role_id', 'order', 'group_by', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @api_path + '/overviews'
  @configure_attributes = [
    { name: 'name',       display: 'Name',                tag: 'input',    type: 'text', limit: 100, 'null': false, 'class': 'span4' },
    { name: 'link',       display: 'URL',                 tag: 'input',    type: 'text', limit: 100, 'null': false, 'class': 'span4' },
    { name: 'role_id',    display: 'Available for Role',  tag: 'select',   multiple: false, nulloption: true, null: false, relation: 'Role', translate: true, class: 'span4' },
    { name: 'user_id',    display: 'Available for User',  tag: 'select',   multiple: true, nulloption: true, null: true,  relation: 'User', sortBy: 'firstname', class: 'span4' },
    { name: 'organization_shared', display: 'Only available for Users with shared Organization', tag: 'select', options: { true: 'yes', false: 'no' }, default: false, null: true, 'class': 'span4' },
#    { name: 'content',    display: 'Content',             tag: 'textarea',                limit: 250, 'null': false, 'class': 'span4' },
    { name: 'condition',  display: 'Conditions for shown Tickets', tag: 'ticket_attribute_selection', null: true, class: 'span4' },
    { name: 'prio',       display: 'Prio',                tag: 'input',    type: 'text', limit: 10, 'null': false, 'class': 'span4' },
    { 
      name:    'view::s'
      display: 'Attributes'
      tag:     'checkbox'
      default: ['number', 'title', 'ticket_state', 'created_at']
      null:    false
      translate: true
      options:
        number:                 'Number'
        title:                  'Title'
        customer:               'Customer'
        ticket_state:           'State'
        ticket_priority:        'Priority'
        group:                  'Group'
        owner:                  'Owner'
        created_at:             'Age'
        last_contact:           'Last Contact'
        last_contact_agent:     'Last Contact Agent'
        last_contact_customer:  'Last Contact Customer'
        first_response:         'First Response'
        close_time:             'Close Time'
        article_count:          'Article Count'
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
        ticket_state:           'State'
        ticket_priority:        'Priority'
        group:                  'Group'
        owner:                  'Owner'
        created_at:             'Age'
        last_contact:           'Last Contact'
        last_contact_agent:     'Last Contact Agent'
        last_contact_customer:  'Last Contact Customer'
        first_response:         'First Response'
        close_time:             'Close Time'
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
        ticket_state:           'State'
        ticket_priority:        'Priority'
        group:                  'Group'
        owner:                  'Owner'
      class:   'span4'
    },
    { name: 'updated_at', display: 'Updated',             type: 'time', readonly: 1 },
    { name: 'active',     display: 'Active',              tag: 'boolean',  note: 'boolean', 'default': true, 'null': false, 'class': 'span4' },
  ]
  @configure_delete = true
  @configure_overview = [
    'name',
    'link',
    'role',
    'prio',
  ]
