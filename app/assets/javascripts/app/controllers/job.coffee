class Job extends App.ControllerSubContent
  @requiredPermission: 'admin.scheduler'
  header: __('Scheduler')
  constructor: ->
    super

    @fetchTimezones()

    @genericController = new Index(
      el: @el
      id: @id
      genericObject: 'Job'
      defaultSortBy: 'name'
      searchBar: true
      searchQuery: @search_query
      pageData:
        home: 'Jobs'
        object: __('Scheduler')
        objects: __('Schedulers')
        pagerAjax: true
        pagerBaseUrl: '#manage/job/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 50
        navupdate: '#Jobs'
        buttons: [
          { name: __('New Scheduler'), 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
      veryLarge: true
      handlers: [
        App.FormHandlerAdminJobObjectName.run
      ]
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate(@page || 1, params)

  fetchTimezones: =>
    @ajax(
      id:    'calendar_timezones'
      type:  'GET'
      url:   "#{@apiPath}/calendars/timezones"
      success: (data) ->
        App.Config.set('timezones', data.timezones)
    )

class Index extends App.ControllerGenericIndex
  newControllerClass: -> New
  editControllerClass: -> Edit

ModalContentFormModelMixin =
  events:
    'change input[name="execution_localization"]': 'executionLocalizationChanged'

  contentFormModel: ->
    params = @contentFormParams() or {}
    attrs = _.clone(App[ @genericObject ].configure_attributes)

    attrs = @prepareExecutionLocalizationAttributes(params, attrs)

    { configure_attributes: attrs }

class Edit extends App.ControllerGenericEdit
  @include App.ExecutionLocalizationMixin
  @include ModalContentFormModelMixin

class New extends App.ControllerGenericNew
  @include App.ExecutionLocalizationMixin
  @include ModalContentFormModelMixin

App.Config.set('Job', { prio: 3400, name: __('Scheduler'), parent: '#manage', target: '#manage/job', controller: Job, permission: ['admin.scheduler'] }, 'NavBarAdmin')
