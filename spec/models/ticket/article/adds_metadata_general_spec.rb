# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::Article::AddsMetadataGeneral do
  context 'when Agent creates Article' do
    shared_examples 'not including email in from' do |factory|
      subject(:article) { create(:ticket_article, factory, ticket: ticket, created_by_id: agent.id, updated_by_id: agent.id) }

      let(:ticket) { create(:ticket) }
      let!(:agent) { create(:agent, groups: [ticket.group]) }

      it "doesn't include email in from" do
        expect(article.from).not_to include agent.email
      end
    end

    it_behaves_like 'not including email in from', :outbound_phone
    it_behaves_like 'not including email in from', :outbound_web

    context 'when as Customer' do
      subject(:article) { create(:ticket_article, :inbound_phone, ticket: ticket) }

      let(:agent)  { create(:agent) }
      let(:ticket) { create(:ticket, customer_id: agent.id) }

      it 'includes email in from' do
        expect(article.from).not_to include agent.email
      end
    end
  end

  context 'when Agent-Customer in shared organization creates Article' do
    let(:organization) { create(:organization, shared: true) }
    let(:agent_a) { create(:agent_and_customer, organization: organization) }
    let(:agent_b) { create(:agent_and_customer, organization: organization) }
    let(:group)   { create(:group) }
    let(:ticket)  { create(:ticket, group: group, owner: agent_a, customer: agent_b) }

    before do
      [agent_a, agent_b].each do |elem|
        elem.user_groups.create group: group, access: 'create'
      end
    end

    it '#origin_by is set correctly', current_user_id: -> { agent_a.id } do
      article = create(:ticket_article, :inbound_web, ticket: ticket)

      expect(article.origin_by).to be_nil
    end
  end

  context 'when Customer creates Article', current_user_id: -> { customer.id } do
    let(:ticket)  { create(:ticket, customer:) }
    let(:article) { create(:ticket_article, :inbound_web, ticket:) }

    context 'when customer has email address' do
      let(:customer) { create(:customer) }

      it '#from is set correctly to customer full name and email' do
        expect(article.from).to eq("#{customer.fullname} <#{customer.email}>")
      end
    end

    context 'when customer has no email address' do
      let(:customer) { create(:customer, email: nil) }

      it '#from is set correctly to customer full name' do
        expect(article.from).to eq(customer.fullname)
      end
    end
  end
end
