class App.PostmasterFilter extends App.Model
  @configure 'PostmasterFilter', 'name', 'channel', 'match', 'perform', 'note', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/postmaster_filters'

  @configure_attributes = [
    { name: 'name',         display: 'Name',              tag: 'input', type: 'text', limit: 250, 'null': false, 'class': 'span4' },
    { name: 'channel',      display: 'Channel',           type: 'input', readonly: 1 },
    { name: 'match',        display: 'Match all of the following',      tag: 'postmaster_match' },
    { name: 'perform',      display: 'Perform action of the following', tag: 'postmaster_set' },
    { name: 'note',         display: 'Note',              tag: 'textarea', note: 'Notes are visible to agents only, never to customers.', limit: 250, 'null': true, 'class': 'span4' },
    { name: 'updated_at',   display: 'Updated',           type: 'time', readonly: 1 },
    { name: 'active',       display: 'Active',            tag: 'boolean', type: 'boolean', 'default': true, 'null': false, 'class': 'span4' },
  ]
  @configure_delete = true
  @configure_overview = [
    'name',
  ]
