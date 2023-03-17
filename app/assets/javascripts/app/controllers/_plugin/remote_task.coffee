class RemoteTask extends App.Controller
  serverRestarted: false
  constructor: ->
    super

    App.Event.bind(
      'remote_task'
      (data) =>
        console.log('remote_task', data)
        App.TaskManager.execute(data)
        @navigate(data.url)
      'remote_task'
    )

App.Config.set('remote_task', RemoteTask, 'Plugins')
