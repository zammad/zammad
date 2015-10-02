class App.NetworkCategory extends App.Model
  @configure 'NetworkCategory', 'name', 'network_id', 'network_category_type_id', 'network_privacy_id', 'note', 'allow_comments', 'active', 'updated_at'
  @extend Spine.Model.Ajax
