class App.TicketZoomChannel

  constructor: (ticket) ->
    @ticket = ticket

  channelAlert: =>
    # TODO: Add a frontend module layer here for other channels, if the need arises.
    @whatsappAlert() if _.has(@ticket.preferences, 'whatsapp')

  whatsappAlert: =>
    lastWhatsappTimestamp = @ticket.preferences.whatsapp.timestamp_incoming

    # In case the customer service window is not open yet, or the ticket is closed, hide the alert.
    return null if not lastWhatsappTimestamp or /^(closed|merged|removed)$/.test(@ticket.state.name)

    # Determine the end of the customer service window and set the appropriate alert text and type.
    timeWindowEnd = new Date(lastWhatsappTimestamp * 1000)
    timeWindowEnd.setHours(timeWindowEnd.getHours() + 24)

    # If time window is already closed, return an error alert.
    if timeWindowEnd <= new Date()
      return {
        text: __('The 24 hour customer service window is now closed, no further WhatsApp messages can be sent.')
        type: 'danger'
      }

    # Otherwise, return a warning alert with a "humanized" end time of the window.
    return {
      text: __('You have a 24 hour window to send WhatsApp messages in this conversation. The customer service window closes %s.')
      textPlaceholder: App.ViewHelpers.humanTime(timeWindowEnd)
      noQuote: true
      type: 'warning'
    }
