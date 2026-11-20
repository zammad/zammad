# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue5567RestoreOutboundSharedMailbox < ActiveRecord::Migration[8.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Channel.where(area: 'MicrosoftGraph::Account').find_each do |channel|
      shared_mailbox = channel.options.dig('inbound', 'options', 'shared_mailbox')
      next if shared_mailbox.blank?
      next if channel.options.dig('outbound', 'options', 'shared_mailbox').present?

      channel.update!(
        options: channel.options.deep_merge(
          outbound: {
            options: { shared_mailbox: },
          },
        ),
      )
    end
  end
end
