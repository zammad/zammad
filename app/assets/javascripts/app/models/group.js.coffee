class App.Group extends App.Model
  @configure 'Group', 'name', 'assignment_timeout', 'follow_up_possible', 'follow_up_assignment', 'email_address_id', 'signature_id', 'note', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/groups'

  @configure_attributes = [
    { name: 'name',                 display: 'Name',              tag: 'input', type: 'text', limit: 100, 'null': false, 'class': 'span4' },
    { name: 'assignment_timeout',   display: 'Assignment Timeout', tag: 'input', note: 'Assignment timeout in minutes if assigned agent is not working on it. Ticket will be shown as unassigend.', type: 'text', limit: 100, 'null': true, 'class': 'span4' },
    { name: 'follow_up_possible',   display: 'Follow up possible',tag: 'select', default: 'yes', options: { yes: 'yes', reject: 'reject follow up/do not reopen Ticket', 'new_ticket': 'do not reopen Ticket but create new Ticket' }, 'null': false, note: 'Follow up for closed ticket possible or not.', 'class': 'span4' },
    { name: 'follow_up_assignment', display: 'Assign Follow Ups', tag: 'select', default: 'yes', options: { true: 'yes', false: 'no' }, 'null': false, note: 'Assign follow up to latest agent again.', 'class': 'span4' },
    { name: 'email_address_id',     display: 'Email',             tag: 'select', multiple: false, null: true, relation: 'EmailAddress', nulloption: true, class: 'span4' },
    { name: 'signature_id',         display: 'Signature',         tag: 'select', multiple: false, null: true, relation: 'Signature', nulloption: true, class: 'span4' },
    { name: 'note',                 display: 'Note',              tag: 'textarea', note: 'Notes are visible to agents only, never to customers.', limit: 250, 'null': true, 'class': 'span4' },
    { name: 'updated_at',           display: 'Updated',           type: 'time', readonly: 1 },
    { name: 'active',               display: 'Active',            tag: 'boolean', type: 'boolean', 'default': true, 'null': false, 'class': 'span4' },
  ]
  @configure_overview = [
    'name',
  ]

  uiUrl: ->
    '#group/zoom/' + @id
