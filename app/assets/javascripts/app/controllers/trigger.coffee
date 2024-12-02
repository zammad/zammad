class Trigger extends App.ControllerSubContent
  @requiredPermission: 'admin.trigger'
  header: __('Triggers')

  constructor: ->
    super

    @fetchTimezones()

    @genericController = new Index(
      el: @el
      id: @id
      genericObject: 'Trigger'
      defaultSortBy: 'name'
      searchBar: true
      searchQuery: @search_query
      pageData:
        home: 'triggers'
        object: __('Trigger')
        objects: __('Triggers')
        pagerAjax: true
        pagerBaseUrl: '#manage/trigger/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 50
        navupdate: '#trigger'
        buttons: [
          { name: __('New Trigger'), 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
      veryLarge: true
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
    'change select[name="activator"]': 'activatorChanged'
    'change input[name="execution_localization"]': 'executionLocalizationChanged'

  contentFormModel: ->
    params = @contentFormParams()
    attrs = _.clone(App[ @genericObject ].configure_attributes)

    attrs = @prepareActivatorAttributes(params, attrs)
    attrs = @prepareExecutionLocalizationAttributes(params, attrs)

    { configure_attributes: attrs }

  prepareActivatorAttributes: (params, attrs) ->
    _.findWhere(attrs, { name: 'execution_condition_mode'}).hide = params.activator isnt 'action'
    _.findWhere(attrs, { name: 'condition'}).hasReached = params.activator is 'time'
    _.findWhere(attrs, { name: 'condition'}).action = params.activator is 'action'

    attrs

  activatorChanged: (e) ->
    e.preventDefault()
    @intermediaryParams = App.ControllerForm.params(@el)
    @update()

  contentFormParams: ->
    @intermediaryParams || @item || { activator: 'action', execution_condition_mode: 'selective' }

class Edit extends App.ControllerGenericEdit
  @include App.ExecutionLocalizationMixin
  @include ModalContentFormModelMixin

class New extends App.ControllerGenericNew
  @include App.ExecutionLocalizationMixin
  @include ModalContentFormModelMixin

App.Config.set('Trigger', { prio: 3300, name: __('Trigger'), parent: '#manage', target: '#manage/trigger', controller: Trigger, permission: ['admin.trigger'] }, 'NavBarAdmin')
