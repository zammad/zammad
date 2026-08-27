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

  # App.UiElement.input (used for the disabled detail form) does not honor `translate: true` the
  # way App.viewPrint does for the overview table, so the label has to be translated here already.
  contentFormParams: =>
    $.extend(true, {}, @item, auditable_type: App.i18n.translatePlain(@item.auditable_type_label or @item.auditable_type))

  onSubmit: =>
    @close()

class AuditLogIndex extends App.ControllerGenericIndex
  editControllerClass: -> AuditLogView

class AuditLog extends App.ControllerSubContent
  @requiredPermission: 'admin.audit_log'
  header: __('Audit Logs')

  # Sorting must stay keyed on the real `auditable_type` column (SqlHelper#get_sort_by rejects
  # anything that is not a DB column), so the label is translated via a table callback instead of
  # a separate `auditable_type_label` attribute.
  translateAuditableType = (value, object) ->
    return value if !value
    App.i18n.translateContent(object.auditable_type_label or value)

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
        tableExtend:
          callbackAttributes:
            auditable_type: [ translateAuditableType ]
      container: @el.closest('.content')
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate(@page || 1, params)

App.Config.set('AuditLog', { prio: 3810, name: __('Audit Logs'), parent: '#system', target: '#system/audit_logs', controller: AuditLog, permission: ['admin.audit_log'] }, 'NavBarAdmin')
