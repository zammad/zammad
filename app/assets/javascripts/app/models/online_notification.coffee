class App.OnlineNotification extends App.Model
  @configure 'OnlineNotification', 'name', 'seen'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/online_notifications'

  ###

  App.OnlineNotification.play()

  App.OnlineNotification.play('bell.mp3')

  ###

  @play: (file) ->
    if file
      sound = new Audio("assets/sounds/#{file}")
      sound.play()
      return
    preferences = App.Session.get('preferences')
    return if !preferences
    return if !App.OnlineNotification.soundEnabled()
    sound = App.Config.get('latest_online_notification_sond')
    return if sound && !sound.ended
    file = App.OnlineNotification.soundFile()
    sound = new Audio("assets/sounds/#{file}")
    App.Config.set('latest_online_notification_sond', sound)
    sound.play()

  ###

  App.OnlineNotification.soundEnabled()

  ###

  @soundEnabled: ->
    preferences = App.Session.get('preferences')
    return false if !preferences
    if !preferences.notification_sound
      preferences.notification_sound = {}
    if preferences.notification_sound.enabled is undefined
      preferences.notification_sound.enabled = true
    return false if preferences.notification_sound.enabled.toString() is 'false'
    true

  ###

  App.OnlineNotification.soundFile()

  ###

  @soundFile: ->
    file = 'Xylo.mp3'
    preferences = App.Session.get('preferences')
    return file if !preferences
    return file if !preferences.notification_sound
    return file if !preferences.notification_sound.file
    preferences.notification_sound.file

  ###

  App.OnlineNotification.seen( 'Ticket', 123 )

  ###

  @seen: (object, o_id) ->
    notifications = App.OnlineNotification.all()
    for notification in notifications
      if notification.object is object && notification.o_id.toString() is o_id.toString()
        if notification.seen isnt true
          notification.seen = true
          notification.save()