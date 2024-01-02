# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Webhook::PreDefined::Mattermost < Webhook::PreDefined
  def name
    __('Mattermost Notifications')
  end

  # rubocop:disable Lint/InterpolationCheck
  def custom_payload
    {
      channel:     '#{webhook.messaging_channel}',
      username:    '#{webhook.messaging_username}',
      icon_url:    '#{webhook.messaging_icon_url}',
      mrkdwn:      true,
      text:        '# #{ticket.title}',
      attachments: [
        {
          text:      "_[Ticket#\#{ticket.number}](\#{notification.link}): \#{notification.message}_\n\n\#{notification.changes}\n\n\#{notification.body}",
          mrkdwn_in: [
            'text'
          ],
          color:     '#{ticket.current_state_color}'
        }
      ]
    }
  end
  # rubocop:enable Lint/InterpolationCheck

  def fields
    [
      {
        display:     __('Messaging Username'),
        placeholder: '',
        null:        true,
        name:        'messaging_username',
        tag:         'input',
      },
      {
        display:     __('Messaging Channel'),
        placeholder: '#channel',
        null:        true,
        name:        'messaging_channel',
        tag:         'input',
      },
      {
        display:     __('Messaging Icon URL'),
        placeholder: 'https://example.com/logo.png',
        value:       'https://zammad.com/assets/images/logo-200x200.png',
        null:        true,
        name:        'messaging_icon_url',
        tag:         'input',
      },
    ]
  end
end
