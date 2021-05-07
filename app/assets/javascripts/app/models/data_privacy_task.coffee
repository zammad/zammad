class App.DataPrivacyTask extends App.Model
  @configure 'DataPrivacyTask', 'state', 'deletable_id', 'deletable_type', 'preferences'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/data_privacy_tasks'
  @configure_attributes = [
    { name: 'deletable_id',   display: 'User',            tag: 'autocompletion_ajax', relation: 'User', do_not_log: true },
    { name: 'state',          display: 'State',           tag: 'input', readonly: 1 },
    { name: 'created_by_id',  display: 'Created by',      relation: 'User', readonly: 1 },
    { name: 'created_at',     display: 'Created',         tag: 'datetime', readonly: 1 },
    { name: 'updated_by_id',  display: 'Updated by',      relation: 'User', readonly: 1 },
    { name: 'updated_at',     display: 'Updated',         tag: 'datetime', readonly: 1 },
  ]
  @configure_overview = []

  @description = '''
** Data Privacy **, helps you to delete and verify the removal of existing data of the system.

It can be used to delete tickets, organizations and users. The owner assignment will be unset in case the deleted user is an agent.

Data Privacy tasks will be executed every 10 minutes. The execution might take some additional time depending of the number of objects that should get deleted.
'''

  activityMessage: (item) ->
    return if !item
    return if !item.created_by

    if item.type is 'create'
      return App.i18n.translateContent('%s created data privacy task to delete user id |%s|', item.created_by.displayName(), item.objectNative.deletable_id)
    else if item.type is 'update'
      return App.i18n.translateContent('%s updated data privacy task to delete user id |%s|', item.created_by.displayName(), item.objectNative.deletable_id)
    else if item.type is 'completed'
      return App.i18n.translateContent('%s completed data privacy task to delete user id |%s|', item.created_by.displayName(), item.objectNative.deletable_id)
    return "Unknow action for (#{@objectDisplayName()}/#{item.type}), extend activityMessage() of model."
