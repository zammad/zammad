# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue5567MicrosoftGraphOutboundSharedMailbox, type: :db_migration do
  describe 'with a shared mailbox account' do
    before do
      create(:microsoft_graph_channel, microsoft_shared_mailbox: 'exshared@domain.tld').tap do |channel|
        channel.options[:outbound][:options].delete(:shared_mailbox) # reproduce the original issue
        channel.save!
      end
    end

    it 'migrates outbound options' do
      expect { migrate }
        .to change { Channel.last.options[:outbound][:options] }
        .from(not_include(:shared_mailbox))
        .to(include(shared_mailbox: 'exshared@domain.tld'))
    end
  end

  describe 'with a user mailbox account' do
    before do
      create(:microsoft_graph_channel)
    end

    it 'does not migrate outbound options' do
      expect { migrate }.not_to change { Channel.last.options[:outbound][:options] }
    end
  end
end
