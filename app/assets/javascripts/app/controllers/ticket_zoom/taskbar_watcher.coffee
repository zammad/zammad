class App.TaskbarWatcher extends App.Controller
  constructor: ->
    super
    @subscribeId = App.TaskManager.preferencesSubscribe(@task_key, @render)

  release: =>
    return if !@subscribeId
    App.TaskManager.preferencesUnsubscribe(@subscribeId)

  render: (preferences) =>
    return if !preferences
    return if !preferences.tasks
    return if !@diffrence(@lastTasks, preferences.tasks)
    @lastTasks = preferences.tasks

    watchers = []
    currentUserId = App.Session.get('id')
    @el.empty()
    for watcher in preferences.tasks
      if watcher.user_id != currentUserId
        cssClass = []
        lastContact = new Date(new Date(watcher.last_contact).getTime() + 5 * 60000)
        if new Date() > lastContact
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

  diffrence: (lastTasks, newTasks) ->
    return true if !lastTasks
    return true if lastTasks.length != newTasks.length
    for taskPosition of lastTasks
      return true if !lastTasks[taskPosition] || !newTasks[taskPosition]
      return true if lastTasks[taskPosition].user_id != newTasks[taskPosition].user_id
      return true if lastTasks[taskPosition].changed != newTasks[taskPosition].changed
      if lastTasks[taskPosition].last_contact
        lastContact = new Date(new Date(lastTasks[taskPosition].last_contact).getTime() + 5 * 60000)
        return true if new Date() > lastContact
    false
