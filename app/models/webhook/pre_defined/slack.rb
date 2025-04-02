# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Webhook::PreDefined::Slack < Webhook::PreDefined
  def name
    __('Slack Notifications')
  end

  # rubocop:disable Lint/InterpolationCheck
  def custom_payload
    {
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
end
