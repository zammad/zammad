# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Whatsapp::Retry::Media, :aggregate_failures do
  subject(:instance) { described_class.new(article:) }

  let(:group)     { create(:group) }
  let(:agent)     { create(:agent, groups: [group]) }
  let(:customer)  { create(:customer) }
  let(:channel)   { create(:whatsapp_channel) }
  let(:ticket)    { create(:ticket, group:, preferences: { channel_id: channel.id }) }
  let(:article) do
    create(:whatsapp_article, :with_attachment_media_document, ticket: ticket, created_by: customer).tap do |article|
      article.preferences[:whatsapp][:media_error] = true
      article.save!
      article.attachments.delete_all
    end
  end

  context "when retrying an article's media download" do

    context 'with a whatsapp article with failed media download' do
      context 'with a successful cloud response' do
        before do
          allow_any_instance_of(Whatsapp::Incoming::Media).to receive(:download).and_return(['example-content', 'text/plain'])
          UserInfo.current_user_id = agent.id
        end

        it 'creates the attachment' do
          expect { instance.process }.to change { article.attachments.count }.by(1)
          expect(article.reload.preferences[:whatsapp]).not_to have_key(:media_error)
          expect(article.attachments.first.preferences).to include('Mime-Type': 'text/plain')
          expect(article.attachments.first.store_file.content).to eq('example-content')
        end
      end

      context 'with a failed cloud response' do
        before do
          allow_any_instance_of(Whatsapp::Incoming::Media).to receive(:download).and_raise(Whatsapp::Client::CloudAPIError.new('example error', 'for rspec'))
        end

        it 'raises an error' do
          expect { instance.process }.to raise_error(Whatsapp::Client::CloudAPIError)
          expect(article.reload.preferences[:whatsapp]).to have_key(:media_error)
          expect(article.attachments.count).to eq(0)
        end
      end
    end

    context 'with a whatsapp article without failed media download' do
      it 'returns a user error' do
        article.preferences.delete(:whatsapp)
        article.save!
        expect { instance.process }.to raise_error(Whatsapp::Retry::Media::ArticleInvalidError, 'Retrying to download the sent media via WhatsApp failed. The given article is not a media article.')
      end
    end
  end
end
