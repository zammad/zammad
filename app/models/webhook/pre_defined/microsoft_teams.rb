# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Webhook::PreDefined::MicrosoftTeams < Webhook::PreDefined
  def name
    __('Microsoft Teams Notifications')
  end

  # rubocop:disable Lint/InterpolationCheck
  def custom_payload
    {
      '@type':         'MessageCard',
      '@context':      'http://schema.org/extensions',
      themeColor:      '#{ticket.current_state_color}',
      title:           '#{ticket.title}',
      text:            '#{notification.message}',
      sections:        [
        {
          text: '#{notification.changes}'
        },
        {
          text: '#{notification.body}'
        }
      ],
      potentialAction: [
        {
          targets: [
            {
              os:  'default',
              uri: '#{notification.link}'
            }
          ],
          '@type': 'OpenUri',
          name:    'Ticket##{ticket.number}'
        }
      ]
    }
  end
  # rubocop:enable Lint/InterpolationCheck
end
