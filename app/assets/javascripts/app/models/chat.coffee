class App.Chat extends App.Model
  @configure 'Chat', 'name', 'active', 'public', 'max_queue', 'note'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/chats'

  @configure_attributes = [
    { name: 'name',           display: 'Name',            tag: 'input',       type: 'text', limit: 100, null: false },
    { name: 'note',           display: 'Note',            tag: 'textarea',    limit: 250, null: true },
    #{ name: 'public',         display: 'Public',          tag: 'boolean',     default: true },
    { name: 'max_queue',      display: 'Max. clients in waitlist', tag: 'input',       default: 2 },
    { name: 'active',         display: 'Active',          tag: 'active',      default: true },
    { name: 'created_by_id',  display: 'Created by',      relation: 'User',   readonly: 1 },
    { name: 'created_at',     display: 'Created',         tag: 'datetime',    readonly: 1 },
    { name: 'updated_by_id',  display: 'Updated by',      relation: 'User',   readonly: 1 },
    { name: 'updated_at',     display: 'Updated',         tag: 'datetime',    readonly: 1 },
  ]
