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
    @markIdlePreferences(preferences, currentUserId)

    return if _.isEqual(@lastTasks, preferences.tasks)
    @lastTasks = clone(preferences.tasks)

    @el.empty()

    selfTask      = _.find preferences.tasks, (watcher) -> watcher.user_id == currentUserId
    filteredTasks = _.filter preferences.tasks, (watcher) -> watcher.user_id != currentUserId

    if selfTask && selfTask.apps.mobile?.changed
      @renderSelfWatcher(selfTask, filteredTasks.length)

    for watcher, i in filteredTasks
      @renderOtherWatcher(watcher, i != filteredTasks.length - 1)

  markIdlePreferences: (preferences, userId) ->
    for watcher in preferences.tasks
      if watcher.user_id != userId
        for key in _.keys(watcher.apps)
          if watcher.apps[key].last_contact
            last_contact_date = new Date(watcher.apps[key].last_contact)
            diff              = new Date().getTime() - last_contact_date.getTime()
            watcher.apps[key].idle = diff > 300000

    preferences

  renderSelfWatcher: (task, hasSpacer) =>
    @renderWatcher(task, hasSpacer, 'mobile-edit', 'mobile')

  renderOtherWatcher: (task, hasSpacer) =>
    keys = _.keys(task.apps)

    if keys.length > 1
      if new Date(task.apps.desktop.last_contact) > new Date(task.apps.mobile.last_contact)
        platform = 'desktop'
      else
        platform = 'mobile'
    else
      platform = keys[0]

    if task.apps.desktop?.changed || task.apps.mobile?.changed
      icon = 'pen'
    else if platform == 'mobile'
      icon = 'mobile'

    @renderWatcher(task, hasSpacer, icon, platform)

  renderWatcher: (watcher, needsSpacer, icon, platformKey) =>
    cssClass = []
    if watcher.apps[platformKey].idle
      cssClass.push('avatar--idle')
    if watcher.apps[platformKey].changed
      cssClass.push('avatar--changed')
    else
      cssClass.push('avatar--not-changed')
    @el.append('<div class="js-avatar"></div>')

    if needsSpacer
      @el.append('<div class="half-spacer"></div>')

    avatar = new App.WidgetAvatar(
      el:        @el.find('.js-avatar').last()
      object_id: watcher.user_id
      size:      40
      cssClass:  cssClass.join(' ')
    )

    if icon
      status = $('<div class="avatar-status"></div>')
      status.append App.Utils.icon(icon)

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
