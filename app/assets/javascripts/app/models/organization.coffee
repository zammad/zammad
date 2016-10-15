class App.Organization extends App.Model
  @configure 'Organization', 'name', 'shared', 'note', 'member_ids', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/organizations'
  @configure_attributes = [
    { name: 'name',           display: 'Name',                tag: 'input',     type: 'text', limit: 100, null: false, info: true },
    { name: 'shared',         display: 'Shared organization', tag: 'boolean',   note: 'Customers in the organization can view each other items.', type: 'boolean', default: true, null: false, info: false },
    { name: 'note',           display: 'Note',                tag: 'textarea',  note: 'Notes are visible to agents only, never to customers.', limit: 250, null: true, info: true },
    { name: 'active',         display: 'Active',              tag: 'active',    default: true, info: false },
    { name: 'created_by_id',  display: 'Created by',    relation: 'User', readonly: 1, info: false },
    { name: 'created_at',     display: 'Created at',    tag: 'datetime',  readonly: 1, info: false },
    { name: 'updated_by_id',  display: 'Updated by',    relation: 'User', readonly: 1, info: false },
    { name: 'updated_at',     display: 'Updated at',    tag: 'datetime',  readonly: 1, info: false },
  ]
  @configure_overview = [
    'name',
    'shared',
  ]

  @description = '''
Mit **Organisationen** können Sie Kunden **gruppieren**. Dies hat u. a. zwei bedeutende Vorteile.

1. Als **Agent** haben Sie nicht nur die Übersicht über die Tickets eines Kunden sondern zusätzlich die **Übersicht über die gesamte Organisation**. Z. B. über die Suchen nach der Organisation, diese per einfachen klick öffnen.
2. Als **Kunde** können Sie die **Tickets ihrer Kollegen mit einsehen** und bearbeiten (sofern die Organisation eine "teilende" ist, dies können Sie je Organisation als Parameter einstellen).
'''

  uiUrl: ->
    "#organization/profile/#{@id}"

  icon: ->
    'organization'

  @_fillUp: (data) ->

    # addd users of organization
    if data['member_ids']
      data['members'] = []
      for user_id in data['member_ids']
        if App.User.exists(user_id)
          user = App.User.findNative(user_id)
          data['members'].push user
    data

  searchResultAttributes: ->
    display:    "#{@displayName()}"
    id:         @id
    class:      'organization organization-popover'
    url:        @uiUrl()
    icon:       'organization'

  activityMessage: (item) ->
    if item.type is 'create'
      return App.i18n.translateContent('%s created Organization |%s|', item.created_by.displayName(), item.title)
    else if item.type is 'update'
      return App.i18n.translateContent('%s updated Organization |%s|', item.created_by.displayName(), item.title)
    return "Unknow action for (#{@objectDisplayName()}/#{item.type}), extend activityMessage() of model."
