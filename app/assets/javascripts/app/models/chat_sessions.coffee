class App.ChatSession extends App.Model
  @configure 'ChatSession', 'name', 'note'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/chat_sessions'

  @configure_attributes = [
    { name: 'name',           display: __('Name'),        tag: 'input',    type: 'text', limit: 100, 'null': false }
    { name: 'state',          display: __('State'),       readonly: 1 }
    { name: 'created_by_id',  display: __('Created by'),  relation: 'User', readonly: 1 }
    { name: 'created_at',     display: __('Created'),     tag: 'datetime', readonly: 1 }
    { name: 'updated_by_id',  display: __('Updated by'),  relation: 'User', readonly: 1 }
    { name: 'updated_at',     display: __('Updated'),     tag: 'datetime', readonly: 1 }
  ]

  @configure_overview = [
    'name',
    'state',
    'created_at',
  ]

  @display_name = __('Chat Session')

  uiUrl: ->
    "#customer_chat/session/#{@id}"

  searchResultAttributes: ->
    displayName = ''
    if !_.isEmpty(@name)
      displayName = @displayName()
    display:    "##{@id} #{displayName}"
    id:         @id
    class:      'chat_session chat_session-popover'
    url:        @uiUrl()
    icon:       'chat'
