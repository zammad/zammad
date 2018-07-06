class App.Twitter extends App.Model
  @configure 'Twitter', 'name', 'channels'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/twitter'
  @configure_attributes = [
    { name: 'name', display: 'Name', tag: 'input', type: 'text', limit: 100, null: false }
  ]
  @configure_delete = true
  @configure_overview = [
    'name',
  ]
