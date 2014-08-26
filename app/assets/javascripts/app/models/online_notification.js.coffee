class App.OnlineNotification extends App.Model
  @configure 'OnlineNotification', 'name', 'seen'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/online_notifications'

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