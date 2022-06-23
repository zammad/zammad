class App.TextModule extends App.Model
  @configure 'TextModule', 'name', 'keywords', 'content', 'active', 'group_ids', 'user_id', 'updated_at', 'note'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/text_modules'
  @configure_attributes = [
    { name: 'name',       display: __('Name'),     tag: 'input',     type: 'text', limit: 100,  null: false },
    { name: 'keywords',   display: __('Keywords'), tag: 'input',     type: 'text', limit: 100,  null: true },
    { name: 'content',    display: __('Content'),  tag: 'richtext',                limit: 2000, null: false, plugins: [
      {
        controller: 'WidgetPlaceholder'
        params:
          objects: [
            {
              prefix: 'ticket'
              object: 'Ticket'
              display: __('Ticket')
            },
            {
              prefix: 'user'
              object: 'User'
              display: __('Current User')
            },
          ]
      }
    ], note: __('To select placeholders from a list, just enter "::".')},
    { name: 'updated_at', display: __('Updated'), tag: 'datetime', readonly: 1 },
    { name: 'note',       display: __('Note'),    tag: 'textarea',      limit:   250,      null: true },
    { name: 'group_ids',  display: __('Groups'),  tag: 'column_select', relation: 'Group', null: true, unsortable: true },
    { name: 'active',     display: __('Active'),  tag: 'active',   default: true },
  ]
  @configure_delete = true
  @configure_clone = true
  @configure_overview = [
    'name',
    'keywords',
    'content',
    'group_ids',
  ]

  # coffeelint: disable=no_interpolation_in_single_quotes
  @description = __('''
Create Text Modules to **spend less time writing responses**. Text Modules can include smart variables like the user's name or email address.

Examples of snippets are:

* Hello Mrs. #{ticket.customer.lastname},
* Hello Mr. #{ticket.customer.lastname},
* Hello #{ticket.customer.firstname},
* My name is #{user.firstname},

Of course, you can also use multi-line snippets.

Available objects are:
* ticket (e.g. ticket.state, ticket.group)
* ticket.customer (e.g. ticket.customer.firstname, ticket.customer.lastname)
* ticket.owner (e.g. ticket.owner.firstname, ticket.owner.lastname)
* ticket.organization (e.g. ticket.organization.name)
* user (e.g. user.firstname, user.email)

To select placeholders from a list, just enter "::".
''')
  # coffeelint: enable=no_interpolation_in_single_quotes
