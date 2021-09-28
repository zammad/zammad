class CoreWorkflow extends App.ControllerSubContent
  requiredPermission: 'admin.core_workflow'
  header: 'Core Workflows'
  constructor: ->
    super

    @setAttributes()

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'CoreWorkflow'
      defaultSortBy: 'name'
      pageData:
        home: 'core_workflow'
        object: 'Workflow'
        objects: 'Workflows'
        pagerAjax: true
        pagerBaseUrl: '#manage/core_workflow/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 150
        navupdate: '#core_workflow'
        notes: [
          'Core Workflows are actions or constraints on selections in forms. Depending on an action, it is possible to hide or restrict fields or to change the obligation to fill them in.'
        ]
        buttons: [
          { name: 'New Workflow', 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
      veryLarge: true
      handlers: [
        App.FormHandlerCoreWorkflow.run
        App.FormHandlerAdminCoreWorkflow.run
      ]
    )

  setAttributes: ->
    for field in App.CoreWorkflow.configure_attributes
      if field.name is 'object'
        field.options = {}
        for value in App.FormHandlerCoreWorkflow.getObjects()
          field.options[value] = value
      else if field.name is 'preferences::screen'
        field.options = {}
        for value in App.FormHandlerCoreWorkflow.getScreens()
          field.options[value] = @screen2displayName(value)

  screen2displayName: (screen) ->
    mapping = {
      create: 'Creation mask',
      create_middle: 'Creation mask',
      edit: 'Edit mask',
      overview_bulk: 'Overview bulk mask',
    }
    return mapping[screen] || screen

App.Config.set('CoreWorkflowObject', { prio: 1750, parent: '#system', name: 'Core Workflows', target: '#system/core_workflow', controller: CoreWorkflow, permission: ['admin.core_workflow'] }, 'NavBarAdmin')
