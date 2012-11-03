class App.Overview extends Spine.Model
  @configure 'Overview', 'name', 'meta', 'condition', 'order', 'group_by', 'view', 'user_id', 'group_ids'
  @extend Spine.Model.Ajax
  @url: '/api/overviews'
