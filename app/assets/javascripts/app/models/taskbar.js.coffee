class App.Taskbar extends App.Model
  @configure 'Taskbar', 'type', 'type_id', 'callback', 'state', 'params', 'notify', 'active'
  @extend Spine.Model.Local
#  @url: 'api/taskbar'
