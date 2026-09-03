# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Webhook::PreDefined::Ntfy < Webhook::PreDefined
  def name
    __('ntfy Notifications')
  end

  # rubocop:disable Lint/InterpolationCheck
  def custom_payload
    {
      topic:   '#{webhook.ntfy_topic}',
      title:   '#{ticket.title}',
      message: "[Ticket#\#{ticket.number}]: \#{notification.message}\n\#{notification.changes}\n\#{notification.body}",
      click:   '#{notification.link}',
    }
  end
  # rubocop:enable Lint/InterpolationCheck

  def fields
    [
      {
        display:     __('Topic'),
        placeholder: 'my-topic',
        null:        false,
        name:        'ntfy_topic',
        tag:         'input',
      },
    ]
  end
end
