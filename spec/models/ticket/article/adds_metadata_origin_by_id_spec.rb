# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::Article::AddsMetadataOriginById do
  subject(:article) do
    create(:ticket_article, ticket:, type_name:, sender_name:, origin_by_id:, created_by_id: agent.id, updated_by_id: agent.id)
  end

  let(:customer)     { create(:customer) }
  let(:ticket)       { create(:ticket, customer:) }
  let(:agent)        { create(:agent, groups: [ticket.group]) }
  let(:type_name)    { 'phone' }
  let(:sender_name)  { 'Customer' }
  let(:origin_by_id) { nil }

  %w[phone note web].each do |type|
    context "with a customer article of type #{type}" do
      let(:type_name) { type }

      it 'sets origin_by to the ticket customer' do
        expect(article.origin_by_id).to eq(customer.id)
      end
    end
  end

  context 'with a customer article of type email' do
    let(:type_name) { 'email' }

    it 'does not set origin_by' do
      expect(article.origin_by_id).to be_nil
    end
  end

  context 'with an agent article' do
    let(:sender_name) { 'Agent' }

    it 'does not set origin_by' do
      expect(article.origin_by_id).to be_nil
    end
  end

  context 'with a given origin_by' do
    let(:other_customer) { create(:customer) }
    let(:origin_by_id)   { other_customer.id }

    it 'keeps the given origin_by' do
      expect(article.origin_by_id).to eq(other_customer.id)
    end
  end

  context 'when import mode is active' do
    before { Setting.set('import_mode', true) }

    it 'does not set origin_by' do
      expect(article.origin_by_id).to be_nil
    end
  end

  context 'when created via postmaster', application_handle: 'scheduler.postmaster' do
    it 'does not set origin_by' do
      expect(article.origin_by_id).to be_nil
    end
  end

  context 'when creator and customer share an organization' do
    let(:organization) { create(:organization, shared:) }
    let(:customer)     { create(:customer, organization:) }
    let(:agent)        { create(:agent_and_customer, organization:, groups: [ticket.group]) }

    context 'with a shared organization' do
      let(:shared) { true }

      it 'does not set origin_by' do
        expect(article.origin_by_id).to be_nil
      end
    end

    context 'with a non-shared organization' do
      let(:shared) { false }

      it 'sets origin_by to the ticket customer' do
        expect(article.origin_by_id).to eq(customer.id)
      end
    end
  end
end
