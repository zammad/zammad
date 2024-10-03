class ChecklistTemplate extends App.ControllerSubContent
  @requiredPermission: 'admin.checklist'
  header: __('Checklists')
  events:
    'change .js-checklistSetting input':  'toggleChecklistSetting'

  elements:
    '.js-checklistSetting input': 'checklistSetting'

  constructor: ->
    super
    @subscribeId = App.Setting.subscribe(@render, initFetch: true, clear: false)

  release: =>
    super
    App.Setting.unsubscribe(@subscribeId)

  render: =>
    elLocal = $(App.view('checklist_template/index')())

    @genericController?.releaseController()
    @genericController = new App.ControllerGenericIndex(
      el: elLocal.find('.js-checklistTemplatesTable')
      id: @id
      genericObject: 'ChecklistTemplate'
      defaultSortBy: 'name'
      pageData:
        home:      'checklists'
        head:      __('Checklist Template')
        object:    __('Manage Checklist Template')
        objects:   __('Manage Checklist Templates')
        subHead: false
        navupdate: '#checklists'
        notes: [
          __('With checklist templates it is possible to pre-fill new checklists with initial items.')
        ]
        buttons: [
          { name: __('New Checklist Template'), 'data-type': 'new', class: 'btn--success' }
        ]
      validateOnSubmit: @validateOnSubmit
    )

    @html elLocal

    value = @checklistSetting.prop('checked')
    checklistTemplatesTable = elLocal.find('.js-checklistTemplatesTable')
    if value is true
      checklistTemplatesTable.show()
    else
      checklistTemplatesTable.hide()

  validateOnSubmit: (params) ->
    errors = {}
    if !params.items || params.items.length is 0
      errors['items'] = __('Please add at least one item to the checklist.')

    errors

  toggleChecklistSetting: (e) =>
    value = @checklistSetting.prop('checked')
    App.Setting.set('checklist', value)

App.Config.set('Checklists', { prio: 2340, name: __('Checklists'), parent: '#manage', target: '#manage/checklists', controller: ChecklistTemplate, permission: ['admin.checklist'] }, 'NavBarAdmin')
