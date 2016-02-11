class App.TextModule extends App.Model
  @configure 'TextModule', 'name', 'keywords', 'content', 'active', 'group_ids', 'user_id', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/text_modules'
  @configure_attributes = [
    { name: 'name',       display: 'Name',          tag: 'input',     type: 'text', limit: 100, null: false },
    { name: 'keywords',   display: 'Keywords',      tag: 'input',     type: 'text', limit: 100, null: true },
    { name: 'content',    display: 'Content',       tag: 'richtext',                limit: 2000, null: false },
    { name: 'updated_at', display: 'Updated',       tag: 'datetime',  readonly: 1 },
    { name: 'active',     display: 'Active',        tag: 'active',    default: true },
  ]
  @configure_delete = true
  @configure_overview = [
    'name',
    'keywords',
    'content',
  ]

  # coffeelint: disable=no_interpolation_in_single_quotes
  @description = '''
Create Text Modules to **spend less time writing responses**. TextModules can include smart variables like the users name or email address.

Examples of snippets are:

* Hallo Frau #{@ticket.customer.lastname},
* Hallo Herr #{@ticket.customer.lastname},
* Hallo #{@ticket.customer.firstname},

Of course you can also use multi line snippets.

Available objects are:
* @ticket (e. g. @ticket.state, @ticket.group)
* @ticket.customer (e. g. @ticket.customer.firstname, @ticket.customer.lastname)
* @ticket.owner (e. g. @ticket.owner.firstname, @ticket.owner.lastname)
* @ticket.organization (e. g. @ticket.organization.name)

'''
  # coffeelint: enable=no_interpolation_in_single_quotes
