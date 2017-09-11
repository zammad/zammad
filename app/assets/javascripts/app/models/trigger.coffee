class App.Trigger extends App.Model
  @configure 'Trigger', 'name', 'condition', 'perform', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/triggers'
  @configure_attributes = [
    { name: 'name',       display: 'Name',          tag: 'input',     type: 'text', limit: 100, null: false },
    { name: 'condition',  display: 'Conditions for effected objects', tag: 'ticket_selector', null: false, preview: false, action: true, hasChanged: true },
    { name: 'perform',    display: 'Execute changes on objects',      tag: 'ticket_perform_action', null: true, notification: true, trigger: true },
    { name: 'active',     display: 'Active',        tag: 'active',    default: true },
    { name: 'updated_at', display: 'Updated',       tag: 'datetime',  readonly: 1 },
  ]
  @configure_delete = true
  @configure_overview = [
    'name',
  ]
  ###
  @description = '''
Trigger are....

'''
  ###
