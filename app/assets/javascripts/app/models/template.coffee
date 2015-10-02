class App.Template extends App.Model
  @configure 'Template', 'name', 'options', 'group_ids', 'user_id', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/templates'
