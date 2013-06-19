class App.NetworkCategoryType extends App.Model
  @configure 'NetworkCategoryType', 'name', 'note', 'active', 'updated_at'
  @extend Spine.Model.Ajax
