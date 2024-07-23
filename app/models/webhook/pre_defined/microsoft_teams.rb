# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Webhook::PreDefined::MicrosoftTeams < Webhook::PreDefined
  def name
    __('Microsoft Teams Notifications')
  end

  # rubocop:disable Lint/InterpolationCheck
  def custom_payload
    {
      type:        'message',
      attachments: [
        {
          contentType: 'application/vnd.microsoft.card.adaptive',
          contentUrl:  nil,
          content:     {
            '$schema': 'http://adaptivecards.io/schemas/adaptive-card.json',
            type:      'AdaptiveCard',
            version:   '1.0',
            body:      [
              {
                type:   'TextBlock',
                text:   '#{ticket.title}',
                color:  '#{ticket.current_state_color}',
                weight: 'bolder',
                size:   'large',
                wrap:   true
              },
              {
                type: 'TextBlock',
                text: '#{notification.changes}',
                wrap: true
              },
              {
                type: 'TextBlock',
                text: '#{notification.body}',
                wrap: true
              },
              {
                type:    'ActionSet',
                actions: [
                  {
                    type:  'Action.OpenUrl',
                    title: '#{config.ticket_hook}#{ticket.number}',
                    url:   '#{notification.link}'
                  }
                ]
              }
            ]
          }
        }
      ]
    }
  end
  # rubocop:enable Lint/InterpolationCheck

  def post_replace(hash, tracks)
    hash['attachments'].first['content']['body'].first['color'] = state_color(tracks[:ticket])

    hash
  end

  private

  def state_color(ticket)
    return 'attention' if ticket.escalation_at && ticket.escalation_at < Time.zone.now

    case ticket.state.state_type.name
    when 'new', 'open'
      return 'warning'
    when 'closed'
      return 'good'
    when 'pending reminder'
      return 'warning' if ticket.pending_time && ticket.pending_time < Time.zone.now
    end

    'default'
  end
end
