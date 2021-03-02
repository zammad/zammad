class App.TaskbarWatcher extends App.Controller
  constructor: ->
    super
    @subscribeId = App.TaskManager.preferencesSubscribe(@taskKey, @render)
    App.TaskManager.preferencesTrigger(@taskKey)

  release: =>
    if @subscribeId
      App.TaskManager.preferencesUnsubscribe(@subscribeId)

  render: (preferences) =>
    return if !preferences
    return if !preferences.tasks

    currentUserId = App.Session.get('id')
    for watcher in preferences.tasks
      if watcher.user_id != currentUserId
        if watcher.last_contact
          watcher.idle = false
          diff = new Date().getTime() - new Date(watcher.last_contact).getTime()
          if diff > 300000
            watcher.idle = true

    return if !@diffrence(@lastTasks, preferences.tasks)
    @lastTasks = clone(preferences.tasks)

    watchers = []
    @el.empty()
    for watcher in preferences.tasks
      if watcher.user_id != currentUserId
        cssClass = []
        if watcher.idle
          cssClass.push('avatar--idle')
        if watcher.changed
          cssClass.push('avatar--changed')
        else
          cssClass.push('avatar--not-changed')
        @el.append('<div class="js-avatar"></div>')
        @el.append('<div class="half-spacer"></div>')

        avatar = new App.WidgetAvatar(
          el:        @el.find('.js-avatar').last()
          object_id: watcher.user_id
          size:      40
          cssClass:  cssClass.join(' ')
        )

        if watcher.changed
          status = $('<div class="avatar-status"></div>')
          status.append App.Utils.icon('pen')
          avatar.el.find('.avatar').append status

  start: =>
    @intervalId = @interval(
      =>
        App.TaskManager.preferencesTrigger(@taskKey)
      5 * 60000
      'ticket-watcher-interval'
    )

  stop: =>
    return if !@intervalId
    @clearInterval(@intervalId)

  diffrence: (lastTasks, newTasks) ->
    return true if !lastTasks
    return true if lastTasks.length != newTasks.length
    for taskPosition of lastTasks
      return true if !lastTasks[taskPosition] || !newTasks[taskPosition]
      return true if lastTasks[taskPosition].user_id != newTasks[taskPosition].user_id
      return true if lastTasks[taskPosition].changed != newTasks[taskPosition].changed
      return true if lastTasks[taskPosition].idle != newTasks[taskPosition].idle
    false
