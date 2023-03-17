class App.UserOverviewSorting extends App.Model
  @configure 'UserOverviewSorting', 'user_id', 'overview_id', 'prio'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/user_overview_sortings'
  @configure_attributes = [
    { name: 'user_id', display: __('User'), tag: 'select', multiple: false, null: false, relation: 'User', translate: true },
    { name: 'overview_id', display: __('Overview'), tag: 'select', multiple: false, null: false, relation: 'Overview', translate: true },
    { name: 'prio', display: __('Prio'), readonly: 1 },
  ]
