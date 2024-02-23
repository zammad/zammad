# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::Article::AddsMetadataWhatsapp do
  let(:agent)  { create(:agent) }
  let(:ticket) do
    article = create(:whatsapp_article, :inbound)

    article.ticket
  end
  let(:channel) { Channel.lookup(id: ticket.preferences['channel_id']) }
  let(:ticket_whatsapp_from) { ticket.preferences.dig('whatsapp', 'from') }

  context 'when agent creates whatsapp reply article' do
    subject(:article) { create(:ticket_article, sender_name: 'Agent', type_name: 'whatsapp message', ticket: ticket, created_by_id: agent.id, updated_by_id: agent.id) }

    it 'adds agent name and channel name in from' do
      expect(article.from).to eq("#{agent.firstname} #{agent.lastname} via #{channel.options[:name]} (#{channel.options[:phone_number]})")
    end

    it 'adds correct to value' do
      expect(article.to).to eq("#{ticket_whatsapp_from[:display_name]} (+#{ticket_whatsapp_from[:phone_number]})")
    end

    context 'when agent is system user' do
      let(:agent) { User.lookup(id: 1) }

      it 'adds agent name and channel name in from' do
        expect(article.from).to eq("#{channel.options[:name]} (#{channel.options[:phone_number]})")
      end
    end

  end
end
