# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Whatsapp::Webhook::Message::Reaction, :aggregate_failures, current_user_id: 1 do
  describe '#process' do
    let(:channel) { create(:whatsapp_channel, welcome: 'W' * 120) }

    let(:from) do
      {
        phone: Faker::PhoneNumber.cell_phone_in_e164.delete('+'),
        name:  Faker::Name.unique.name,
      }
    end

    let(:json) do
      {
        object: 'whatsapp_business_account',
        entry:  [{
          id:      '222259550976437',
          changes: [{
            value: {
              messaging_product: 'whatsapp',
              metadata:          {
                display_phone_number: '15551340563',
                phone_number_id:      channel.options[:phone_number_id],
              },
              contacts:          [{
                profile: {
                  name: from[:name],
                },
                wa_id:   from[:phone],
              }],
              messages:          [{
                from:      from[:phone],
                id:        'wamid.HBgNNDkxNTE1NjA4MDY5OBUCABIYFjNFQjBDMUM4M0I5NDRFNThBMUQyMjYA',
                timestamp: '1707921703',
                reaction:  {
                  message_id: 'wamid.HBgNNDkxNTE1NjA4MDY5OBUCABEYEjZEOUYzRTVEMkIzQkExRkE1RQA=',
                  emoji:      '👍'
                },
                type:      'reaction',
              }],
            },
            field: 'messages',
          }],
        }],
      }.to_json
    end

    let(:data) { JSON.parse(json).deep_symbolize_keys }

    before do
      create(:whatsapp_article).tap do |article|
        article.message_id = 'wamid.HBgNNDkxNTE1NjA4MDY5OBUCABEYEjZEOUYzRTVEMkIzQkExRkE1RQA='
        article.save!
      end

      allow(TransactionJob).to receive(:perform_now)
    end

    context 'when a reaction was sent' do
      it 'updates the related article with the reaction' do
        described_class.new(data:, channel:).process

        expect(Ticket::Article.last.preferences[:whatsapp][:reaction]).to eq({
                                                                               'author' => from[:name],
                                                                               'emoji'  => '👍',
                                                                             })

        expect(TransactionJob).to have_received(:perform_now).with hash_including(type: 'update.reaction')
      end

      # Only for PostgreSQL due to emoji storage
      context 'when history is written', db_adapter: :postgresql do
        it 'contains correct type and emoji' do
          described_class.new(data:, channel:).process

          expect(History.last.history_type.name).to eq('created')
          expect(History.last.value_to).to eq('👍')
        end
      end
    end

    context 'when a reaction got removed' do
      before do
        article = Ticket::Article.last
        article.preferences[:whatsapp][:reaction] = '👍'
        article.save!

        data[:entry].first[:changes].first[:value][:messages].first[:reaction].delete(:emoji)
      end

      it 'updates the related article with the reaction' do
        described_class.new(data:, channel:).process

        expect(Ticket::Article.last.preferences[:whatsapp][:reaction]).to eq({
                                                                               'author' => from[:name],
                                                                               'emoji'  => nil,
                                                                             })

        expect(TransactionJob).not_to have_received(:perform_now)
      end

      context 'when history is written' do
        it 'contains correct type and emoji' do
          described_class.new(data:, channel:).process

          expect(History.last.history_type.name).to eq('removed')
          expect(History.last.value_to).to eq('')
        end
      end
    end
  end
end
