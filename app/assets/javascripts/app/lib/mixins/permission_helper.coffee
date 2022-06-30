App.PermissionHelper =
  switchGroupPermission: (event) ->
    throttled = _.throttle( (e) ->
      input = $(e.target)

      upcoming_state = input.prop('checked')
      if !$(e.target).is(':checkbox')
        upcoming_state = !upcoming_state

      selector = 'input[value=full]'
      if input.val() is 'full' and upcoming_state is true
        selector = 'input[value!=full]'

      $(e.target).closest('tr').find(selector).prop('checked', false)
    , 300, { trailing: false })

    throttled(event)
