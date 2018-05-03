class App.Taskbar extends App.Model
  @configure 'Taskbar', 'key', 'client_id', 'callback', 'state', 'params', 'prio', 'notify', 'active', 'attachments', 'updated_at'
#  @extend Spine.Model.Local
  @extend Spine.Model.Ajax
  @url: @apiPath + '/taskbar'
