# Common event handlers for ticket number input field
App.TicketNumberInput =
  removeTicketSelectionOnFocus: (content, field_name) ->
    content.on('focus', "[name=\"#{field_name}\"]", (e) ->
      $(e.target).parents().find('[name="radio"]').prop('checked', false)
    )

  stripTicketHookOnPaste: (content, field_name) ->
    content.on('paste', "[name=\"#{field_name}\"]", (e) =>
      execute = ->
        # Remove ticket hook if present.
        if e.target && e.target.value
          $("[name=\"#{field_name}\"]").val( e.target.value.replace(App.Config.get('ticket_hook'), '') )

      @delay(execute, 0)

      return
    )

  updateTicketNumberOnRadioClick: (content, field_name) ->
    content.on('click', '[name="radio"]', (e) ->
      if $(e.target).prop('checked')
        ticket_id = $(e.target).val()
        ticket    = App.Ticket.fullLocal( ticket_id )
        $(e.target).parents().find("[name=\"#{field_name}\"]").val(ticket.number)
    )
