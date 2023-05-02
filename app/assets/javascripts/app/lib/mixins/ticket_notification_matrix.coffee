# Common handling for the notification matrix
App.TicketNotificationMatrix =
  renderNotificationMatrix: (values) ->
    App.UiElement.notification_matrix.render(values)[0].outerHTML

  updatedNotificationMatrixValues: (formParams) ->
    matrix = {}

    for key, value of formParams
      area = key.split('.')

      continue if area[0] isnt 'matrix'

      if value is 'true'
        value = true
      else
        value = false

      if area[2] is 'criteria'
        if !matrix[area[1]]
          matrix[area[1]] = {}
        if !matrix[area[1]][area[2]]
          matrix[area[1]][area[2]] = {}

        matrix[area[1]][area[2]][area[3]] = value
      if area[2] is 'channel'
        if !matrix
          matrix = {}
        if !matrix[area[1]]
          matrix[area[1]] = {}
        if value is 'email'
          matrix[area[1]][area[2]] = {
            email:  true
            online: true
          }

    for key, value of matrix
      if !value.channel
        value.channel = {
          email:  false
          online: true
        }

    matrix
