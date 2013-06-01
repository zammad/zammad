class App.Taskbar extends App.Model
  @configure 'Taskbar', 'key', 'client_id', 'callback', 'state', 'params', 'prio', 'notify', 'active'
#  @extend Spine.Model.Local
  @extend Spine.Model.Ajax
  @url: 'api/taskbar'
