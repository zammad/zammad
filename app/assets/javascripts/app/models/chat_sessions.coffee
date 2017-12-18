class App.ChatSession extends App.Model
  @configure 'ChatSession', 'name', 'note'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/chat_sessions'

  @configure_attributes = [
    { name: 'name',           display: 'Name',        tag: 'input',    type: 'text', limit: 100, 'null': false }
    { name: 'state',          display: 'State',       readonly: 1 }
    { name: 'created_by_id',  display: 'Created by',  relation: 'User', readonly: 1 }
    { name: 'created_at',     display: 'Created',     tag: 'datetime', readonly: 1 }
    { name: 'updated_by_id',  display: 'Updated by',  relation: 'User', readonly: 1 }
    { name: 'updated_at',     display: 'Updated',     tag: 'datetime', readonly: 1 }
  ]

  @configure_overview = [
    'name',
    'state',
    'created_at',
  ]

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
