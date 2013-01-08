class App.PostmasterFilter extends App.Model
  @configure 'PostmasterFilter', 'name', 'channel', 'match', 'perform', 'note', 'active'
  @extend Spine.Model.Ajax
  @url: 'api/postmaster_filters'

  @configure_attributes = [
    { name: 'name',         display: 'Name',              tag: 'input', type: 'text', limit: 250, 'null': false, 'class': 'span4' },
    { name: 'channel',      display: 'Channel',           type: 'input', readonly: 1 },
    { name: 'match',        display: 'Match all of the following', tag: 'input_select', count_min: 2, count_max: 88, multiple: true, 'null': false, 'class': 'span4', select: { 'class': 'span2', multiple: false, options: { from: 'From', to: 'To', cc: 'Cc', subject: 'Subject', body: 'Body' } }, input: { limit: 250, type: 'text', 'class': 'span3' }, },
    { name: 'perform',      display: 'Perform action of the following', tag: 'input_select', count_min: 2, count_max: 88, multiple: true, 'null': false, 'class': 'span4', select: { 'class': 'span2', multiple: false, options: { from: 'From', to: 'To', cc: 'Cc', subject: 'Subject', body: 'Body', 'x-zammad-priority': 'Ticket Priority', 'x-zammad-state': 'Ticket State', 'x-zammad-customer': 'Ticket Customer', 'x-zammad-ignore': 'Ignore Message', 'x-zammad-group': 'Ticket Group', 'x-zammad-owner': 'Ticket Owner', 'x-zammad-article-visability': 'Article Visability', 'x-zammad-article-type': 'Article Type', 'x-zammad-article-sender': 'Article Sender' } }, input: { limit: 250, type: 'text', 'class': 'span3' }, },
    { name: 'note',         display: 'Note',              tag: 'textarea', note: 'Notes are visible to agents only, never to customers.', limit: 250, 'null': true, 'class': 'span4' },
    { name: 'updated_at',   display: 'Updated',           type: 'time', readonly: 1 },
    { name: 'active',       display: 'Active',            tag: 'boolean', type: 'boolean', 'default': true, 'null': false, 'class': 'span4' },
  ]
  @configure_overview = [
    'name',
  ]
