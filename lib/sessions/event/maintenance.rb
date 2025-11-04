# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sessions::Event::Maintenance < Sessions::Event::Base
  database_connection_required

=begin

Event module to broadcast maintenance messages to all client connections.

To execute this manually, just paste the following into the browser console

  App.WebSocket.send({event:'maintenance', data: {some: 'key'}})

=end

  def run

    # check if sender is admin
    return if !permission_check('admin.maintenance', 'maintenance')

    # Check if the event contains the maintenance message and sanitize it.
    if message?
      @payload['data']['message'] = sanitize(message)
    end

    Sessions.broadcast(@payload, 'public', @session['id'])

    # Maintenance mode start/stop messages are not needed for GraphQL, as clients
    #   watch on changes of the config settings.
    return if !message?

    data = @payload['data']

    Gql::Subscriptions::PushMessages.trigger({ title: data['head'], text: data['message'] })
    false
  end

  private

  def message
    @payload['data']['message']
  end

  def message?
    @payload.dig('data', 'type') == 'message'
  end

  def sanitize(input)
    HtmlSanitizer::Strict
      .new(no_images: true)
      .sanitize(input)
      .strip
  end
end
