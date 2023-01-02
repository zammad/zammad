# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::Overviews do

  describe '.all' do

    let(:views) { described_class.all(current_user: current_user).map(&:name) }

    shared_examples 'containing' do |overview|
      it "returns #{overview}" do
        expect(views).to include(overview)
      end
    end

    shared_examples 'not containing' do |overview|
      it "doesn't return #{overview}" do
        expect(views).not_to include(overview)
      end
    end

    context 'when Agent' do
      let(:current_user) { create(:agent) }

      it_behaves_like 'containing', 'Open Tickets'
      it_behaves_like 'not containing', 'My Tickets'
      it_behaves_like 'not containing', 'My Organization Tickets'
    end

    context 'when Agent is also Customer' do
      let(:current_user) { create(:agent_and_customer, :with_org) }

      it_behaves_like 'containing', 'Open Tickets'
      it_behaves_like 'containing', 'My Tickets'
      it_behaves_like 'containing', 'My Organization Tickets'
    end

    context 'when Customer' do
      let(:current_user) { create(:customer, :with_org) }

      it_behaves_like 'not containing', 'Open Tickets'
      it_behaves_like 'containing', 'My Tickets'
      it_behaves_like 'containing', 'My Organization Tickets'
    end
  end

  describe '.index' do

    # https://github.com/zammad/zammad/issues/1769
    it 'does not return multiple results for a single ticket' do
      user           = create(:user)
      source_ticket  = create(:ticket, customer: user, created_by_id: user.id)
      source_ticket2 = create(:ticket, customer: user, created_by_id: user.id)

      # create some articles
      create(:ticket_article, ticket_id: source_ticket.id, from: 'asdf1@blubselector.de', created_by_id: user.id)
      create(:ticket_article, ticket_id: source_ticket.id, from: 'asdf2@blubselector.de', created_by_id: user.id)
      create(:ticket_article, ticket_id: source_ticket.id, from: 'asdf3@blubselector.de', created_by_id: user.id)
      create(:ticket_article, ticket_id: source_ticket2.id, from: 'asdf3@blubselector.de', created_by_id: user.id)
      create(:ticket_article, ticket_id: source_ticket2.id, from: 'asdf4@blubselector.de', created_by_id: user.id)
      create(:ticket_article, ticket_id: source_ticket2.id, from: 'asdf5@blubselector.de', created_by_id: user.id)

      condition = {
        'article.from' => {
          operator: 'contains',
          value:    'blubselector.de',
        },
      }
      overview = create(:overview, condition: condition)

      result = described_class.index(user)
      result = result.select { |x| x[:overview][:name] == overview.name }

      expect(result.count).to eq(1)
      expect(result[0][:count]).to eq(2)
      expect(result[0][:tickets].count).to eq(2)
    end

    # https://github.com/zammad/zammad/issues/3853
    context 'with specific group permissions' do
      let(:group_read)      { create(:group) }
      let(:group_overview)  { create(:group) }
      let(:user)            { create(:agent) }
      let(:ticket_read)     { create(:ticket, group: group_read) }
      let(:ticket_overview) { create(:ticket, group: group_overview) }

      before do
        user.group_names_access_map = {
          group_read.name     => %w[read],
          group_overview.name => %w[read overview],
        }

        create(:mention, mentionable: ticket_read, user: user)
        create(:mention, mentionable: ticket_overview, user: user)
      end

      it 'displays the correct amount of tickets in the sidebar' do
        result = described_class.index(user, ['my_subscribed_tickets'])

        expect(result.first[:count]).to eq(2)
      end

      it 'displays the correct amount of tickets in the list' do
        result = described_class.index(user, ['my_subscribed_tickets'])

        expect(result.first[:tickets].pluck(:id)).to eq([ticket_read.id, ticket_overview.id])
      end
    end
  end

  describe 'Mentions:' do
    let(:group_read) { create(:group) }
    let(:user_read)  { create(:agent) }
    let(:ticket)     { create(:ticket, group: group_read) }

    before do
      user_read.group_names_access_map = {
        group_read.name => 'read',
      }
    end

    it 'does show read only tickets in overview because user is mentioned' do
      create(:mention, mentionable: ticket, user: user_read)
      result = described_class.index(user_read, ['my_subscribed_tickets'])
      expect(result.first[:tickets].pluck(:id)).to eq([ticket.id])
    end

    it 'does not show read only tickets in overview' do
      result = described_class.index(user_read, ['my_subscribed_tickets'])
      expect(result.first[:tickets]).to eq([])
    end
  end
end
