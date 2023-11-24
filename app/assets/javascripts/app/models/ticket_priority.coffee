class App.TicketPriority extends App.Model
  @configure 'TicketPriority', 'name', 'default_create', 'ui_icon', 'ui_color', 'note', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/ticket_priorities'
  @configure_attributes = [
    { name: 'name',       display: __('Name'),     tag: 'input',    type: 'text', limit: 250, null: false, translate: true },
    { name: 'ui_color',   display: __('Highlight color'), tag: 'select',   null: true, nulloption: true, translate: true, options: { 'low-priority': __('Low priority'), 'high-priority': __('High priority') }, note: __('Defines an optional highlight color of this priority in ticket tables. High priority will be rendered in an indian red, while low priority in a baby blue color.') },
    { name: 'ui_icon',    display: __('Highlight icon'),  tag: 'select',   null: true, nulloption: true, translate: true, options: { 'low-priority': __('Low priority'), 'important': __('Important') }, note: __('Defines an optional icon of this priority in ticket tables. Important will be rendered with an exclamation point, while low priority with a downwards arrow.') },
    { name: 'note',       display: __('Note'),     tag: 'textarea', limit: 250, null: true },
    { name: 'active',     display: __('Active'),   tag: 'active',   default: true },
    { name: 'updated_at', display: __('Updated'),  tag: 'datetime', readonly: 1 },
    { name: 'created_at', display: __('Created'),  tag: 'datetime', readonly: 1 },
  ]
  @configure_clone = true
  @configure_translate = true
  @configure_overview = [
    'name',
  ]

  @description = __('''
A ticket's priority is simply a ranking of how urgent or important it is. Different priorities allow you to see the importance of your tickets better.
''')

  @badges = [
    {
      display: __('Default for new tickets'),
      active: (object) ->
        object.default_create
      attribute: 'name'
      class: 'primary'
    }
  ]
