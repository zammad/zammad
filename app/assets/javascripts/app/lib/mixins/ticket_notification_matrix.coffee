# Common handling for the notification matrix
App.TicketNotificationMatrix =
  renderNotificationMatrix: (values) ->
    App.UiElement.notification_matrix.render(values)[0].outerHTML

  updatedNotificationMatrixValues: (formParams) ->
    matrix = {}

    for key, value of formParams
      area = key.split('.')

      continue if area[0] isnt 'matrix'

      if !matrix[area[1]]
        matrix[area[1]] = {}

      switch area[2]
        when 'criteria'
          if !matrix[area[1]][area[2]]
            matrix[area[1]][area[2]] = {}

          matrix[area[1]][area[2]][area[3]] = value is 'true'
        when 'channel'
          matrix[area[1]][area[2]] = {
            email:  value is 'email'
            online: true
          }

    matrix
