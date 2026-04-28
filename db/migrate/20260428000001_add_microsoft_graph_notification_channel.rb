# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddMicrosoftGraphNotificationChannel < ActiveRecord::Migration[8.0]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # Don't create if it already exists (e.g. from seeds on a fresh install).
    already_exists = Channel.where(area: 'Email::Notification').any? do |channel|
      adapter = channel.options.dig(:outbound, :adapter) || channel.options.dig('outbound', 'adapter')
      adapter == 'microsoft_graph_outbound'
    end
    return if already_exists

    Channel.create!(
      area:          'Email::Notification',
      options:       {
        outbound: {
          adapter: 'microsoft_graph_outbound',
          options: {},
        },
      },
      preferences:   { online_service_disable: true },
      active:        false,
      created_by_id: 1,
      updated_by_id: 1,
    )
  end
end
