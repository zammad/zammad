class AuditLogView extends App.ControllerGenericEdit
  buttonSubmit: false
  headPrefix: ''

  content: =>
    @item = App[ @genericObject ].find( @id )
    @head = @pageData.head || @pageData.object

    @controller = new App.ControllerForm(
      model:      @contentFormModel()
      params:     @contentFormParams()
      screen:     'edit'
      isDisabled: true
    )
    @controller.form

  onSubmit: =>
    @close()

class AuditLogIndex extends App.ControllerGenericIndex
  editControllerClass: -> AuditLogView

class AuditLog extends App.ControllerSubContent
  @requiredPermission: 'admin.audit_log'
  header: __('Audit Logs')
  constructor: ->
    super

    @genericController = new AuditLogIndex(
      el: @el
      id: @id
      genericObject: 'AuditLog'
      defaultSortBy: 'created_at'
      defaultOrder: 'DESC'
      searchBar: true
      searchQuery: @search_query
      searchShortcuts: [
        { query: 'action_type:destroy', label: __('Deletions only') }
        { query: 'auditable_type:User', label: __('User changes only') }
        { query: 'created_at:>now-24h', label: __('Created within last 24 hours') }
      ]
      pageData:
        home: 'audit_logs'
        object: __('Audit Log')
        objects: __('Audit Logs')
        searchPlaceholder: __('Search for audit logs')
        pagerAjax: true
        pagerBaseUrl: '#system/audit_logs/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 50
        navupdate: '#audit_logs'
      container: @el.closest('.content')
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate(@page || 1, params)

App.Config.set('AuditLog', { prio: 3810, name: __('Audit Logs'), parent: '#system', target: '#system/audit_logs', controller: AuditLog, permission: ['admin.audit_log'] }, 'NavBarAdmin')
