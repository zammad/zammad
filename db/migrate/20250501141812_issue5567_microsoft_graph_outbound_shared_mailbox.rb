# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Issue5567MicrosoftGraphOutboundSharedMailbox < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Channel.where(area: 'MicrosoftGraph::Account').find_each do |channel|
      next if !(shared_mailbox = channel.options.dig('inbound', 'options', 'shared_mailbox')).presence

      channel.update!(
        options: channel.options.deep_merge(
          outbound: {
            options: { shared_mailbox: shared_mailbox },
          },
        ),
      )
    end
  end
end
