class Overviews extends App.ControllerSubContent
  requiredPermission: 'user_preferences.overview_sorting'
  header: __('Order of Overviews')

  constructor: ->
    super
    @fetch()

  fetch: =>
    @ajax(
      type:  'GET'
      url:   "#{App.Config.get('api_path')}/user_overview_sortings"
      processData: true,
      success: (data, status, xhr) =>
        App.UserOverviewSortingOverview.refresh(data.overviews)
        App.UserOverviewSorting.refresh(data.overview_sortings)
        @render(data)
    )

  render: (data) ->
    @index ||= new Index(
      disableInitFetch: true
      el: @el
      id: @id
      genericObject: 'UserOverviewSortingOverview'
      defaultSortBy: 'prio'
      pageData:
        home: 'overviews'
        object: __('Order of Overviews')
        objects: __('Order of Overviews')
        navupdate: '#profile/overviews'
        subHead: false
        buttons: [
          { name: __('Reset overview order'), 'data-type': 'reset', class: 'btn--danger' }
        ]
      container: @el.closest('.content')
      veryLarge: true
      dndCallback: (e, item) =>
        items = @el.find('table > tbody > tr')
        prios = []
        prio = 0
        for item in items
          prio += 1
          id = $(item).data('id')
          prios.push [id, prio]

        @ajax(
          id:          'user_overview_sortings_prio'
          type:        'POST'
          url:         "#{@apiPath}/user_overview_sortings_prio"
          processData: true
          data:        JSON.stringify(prios: prios)
          success:     @fetch
        )
    )
    @index.render()

class Index extends App.ControllerGenericIndex
  events:
    'click [data-type=reset]': 'reset'

  render: ->
    objects = App[@genericObject].all()
    @renderObjects(objects)

  edit: (id, e) ->
    return

  reset: (e) =>
    e.preventDefault()

    App.UserOverviewSorting.destroyAll()

    @notify
      type: 'success'
      msg:  __('Personal overview order was reset.')
    @render()

App.Config.set('Overviews', { prio: 2900, name: __('Overviews'), parent: '#profile', target: '#profile/overviews', controller: Overviews, permission: ['user_preferences.overview_sorting'] }, 'NavBarProfile')
