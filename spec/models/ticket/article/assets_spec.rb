# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::Article::Assets do
  describe '#authorized_asset?' do
    subject(:article) { create(:ticket_article, ticket: ticket, internal: internal) }

    let(:ticket)   { create(:ticket) }
    let(:internal) { false }

    before do
      article
      UserInfo.current_user_id = current_user_id
    end

    context 'without a user context' do
      let(:current_user_id) { nil }

      it { is_expected.not_to be_authorized_asset }

      it 'is authorized in a system context' do
        UserInfo.with_system_context do
          expect(article).to be_authorized_asset
        end
      end
    end

    context 'with an agent without access to the group of the ticket' do
      let(:current_user_id) { create(:agent).id }

      it { is_expected.not_to be_authorized_asset }

      context 'when the article is internal' do
        let(:internal) { true }

        it { is_expected.not_to be_authorized_asset }
      end
    end

    context 'with an agent with access to the group of the ticket' do
      let(:current_user_id) { create(:agent, groups: [ticket.group]).id }

      it { is_expected.to be_authorized_asset }

      context 'when the article is internal' do
        let(:internal) { true }

        it { is_expected.to be_authorized_asset }
      end
    end

    context 'with the customer of the ticket' do
      let(:current_user_id) { ticket.customer_id }

      it { is_expected.to be_authorized_asset }

      context 'when the article is internal' do
        let(:internal) { true }

        it { is_expected.not_to be_authorized_asset }
      end
    end
  end
end
