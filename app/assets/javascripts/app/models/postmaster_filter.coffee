class App.PostmasterFilter extends App.Model
  @configure 'PostmasterFilter', 'name', 'channel', 'match', 'perform', 'note', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/postmaster_filters'

  @configure_attributes = [
    { name: 'name',           display: __('Name'),              tag: 'input', type: 'text', limit: 250, 'null': false },
    { name: 'channel',        display: __('Channel'),           type: 'input', readonly: 1 },
    { name: 'match',          display: __('Match all of the following'),      tag: 'postmaster_match', note: __('You can use regular expression by using "regex:your_reg_exp".') },
    { name: 'perform',        display: __('Perform action of the following'), tag: 'postmaster_set', user_action: false },
    { name: 'note',           display: __('Note'),              tag: 'textarea', limit: 250, null: true },
    { name: 'updated_at',     display: __('Updated'),           tag: 'datetime', readonly: 1 },
    { name: 'active',         display: __('Active'),            tag: 'active', default: true },
    { name: 'created_by_id',  display: __('Created by'),        relation: 'User', readonly: 1 },
    { name: 'created_at',     display: __('Created'),           tag: 'datetime', readonly: 1 },
    { name: 'updated_by_id',  display: __('Updated by'),        relation: 'User', readonly: 1 },
    { name: 'updated_at',     display: __('Updated'),           tag: 'datetime', readonly: 1 },
  ]
  @configure_delete = true
  @configure_overview = [
    'name',
  ]
  @configure_clone = true

  @on 'create', (newRecord) ->
    newRecord.channel = 'email'
