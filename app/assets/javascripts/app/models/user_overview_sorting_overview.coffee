class App.UserOverviewSortingOverview extends App.Model
  @configure 'UserOverviewSortingOverview', 'name'
  @configure_attributes = [
    { name: 'name', display: __('Name'), tag: 'input', type: 'text', translate: true, null: false },
  ]
  @configure_overview = [
    'name',
  ]

  @all: ->
    super.sort(@overviewSort)

  @overviewSort: (a, b) ->
    aIndex = a.prio + 9999
    bIndex = b.prio + 9999
    for sorting, index in App.UserOverviewSorting.all()
      if sorting.overview_id is a.id
        aIndex = sorting.prio
      if sorting.overview_id is b.id
        bIndex = sorting.prio

    return aIndex - bIndex
