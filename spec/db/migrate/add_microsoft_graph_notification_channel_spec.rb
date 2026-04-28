# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AddMicrosoftGraphNotificationChannel, type: :db_migration do
  context 'when microsoft_graph_outbound notification channel does not exist' do
    before do
      # Remove any existing microsoft_graph_outbound notification channel
      Channel.where(area: 'Email::Notification').each do |channel|
        adapter = channel.options.dig(:outbound, :adapter) || channel.options.dig('outbound', 'adapter')
        channel.destroy! if adapter == 'microsoft_graph_outbound'
      end
    end

    it 'creates the channel' do
      migrate

      channel = Channel.where(area: 'Email::Notification').find do |ch|
        adapter = ch.options.dig(:outbound, :adapter) || ch.options.dig('outbound', 'adapter')
        adapter == 'microsoft_graph_outbound'
      end

      expect(channel).to have_attributes(
        active:  false,
        options: include(
          outbound: include(adapter: 'microsoft_graph_outbound'),
        ),
      )
    end
  end

  context 'when microsoft_graph_outbound notification channel already exists' do
    before do
      Channel.create!(
        area:          'Email::Notification',
        options:       { outbound: { adapter: 'microsoft_graph_outbound', options: {} } },
        preferences:   { online_service_disable: true },
        active:        false,
        created_by_id: 1,
        updated_by_id: 1,
      )
    end

    it 'does not create a duplicate' do
      expect { migrate }.not_to change {
        Channel.where(area: 'Email::Notification').count { |ch|
          adapter = ch.options.dig(:outbound, :adapter) || ch.options.dig('outbound', 'adapter')
          adapter == 'microsoft_graph_outbound'
        }
      }
    end
  end
end
