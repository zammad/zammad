class App.Template extends App.Model
  @configure 'Template', 'name', 'options', 'user_id', 'updated_at', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/templates'
  @configure_attributes = [
    { name: 'name',        display: __('Name'),     tag: 'input', type: 'text', limit: 100, null: false },
    { name: 'options',     display: __('Actions'),  tag: 'ticket_perform_action', user_action: false, article_body_cc_only: true, no_richtext_uploads: true, sender_type: true, skip_unknown_attributes: true, null: true },
    { name: 'updated_at',  display: __('Updated'),  tag: 'datetime', readonly: 1 },
    { name: 'active',      display: __('Active'),   tag: 'active', default: true },
  ]
  @configure_delete = true
  @configure_clone = true
  @configure_overview = [
    'name',
  ]

  # get list of templates to show in UI
  @getList: ->
    App.Template.search(filter: { active: true }, sortBy:'name', order:'ASC')

  @description = __('''
With templates it is possible to fill pre-filled tickets quickly and easily.
''')
