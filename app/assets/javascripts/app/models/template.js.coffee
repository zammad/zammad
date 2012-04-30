class App.Template extends App.Model
  @configure 'Template', 'name', 'options', 'group_ids', 'user_id'
  @extend Spine.Model.Ajax