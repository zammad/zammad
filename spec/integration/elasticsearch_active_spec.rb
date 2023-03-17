# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Elasticsearch', aggregate_failures: true, performs_jobs: true, searchindex: true do
  let(:group) { create(:group) }
  let(:agent) { create(:agent, groups: [group]) }

  let(:customers) do
    (1..6).map do |i|
      name = i.even? ? "Active-#{i}" : "Inactive-#{i}"
      customer = create(:customer,
                        firstname: 'ActiveTest',
                        lastname:  name,
                        login:     "#{name}-customer#{i}@example.com",
                        active:    i.even?)
      customer
    end
  end

  let(:organizations) do
    (1..6).map do |i|
      name = i.even? ? "Active-#{i}" : "Inactive-#{i}"
      create(:organization, name: "TestOrg-#{name}", active: i.even?)
    end
  end

  let(:tickets) do
    (1..6).map do |i|
      create(:ticket, title: "Ticket-#{i}", group: group)
    end
  end

  context 'with users' do
    before do
      agent
      customers

      searchindex_model_reload([User])
    end

    it 'active users appear before inactive users in search results' do
      result = User.search(current_user: agent, query: 'ActiveTest')
      expect(result).to be_present
      expected_names = %w[Active-6 Active-4 Active-2 Inactive-5 Inactive-3 Inactive-1]
      actual_names = result.map(&:lastname)
      expect(actual_names).to match(expected_names)
    end
  end

  context 'with organizations' do
    before do
      agent
      organizations

      searchindex_model_reload([Organization])
    end

    it 'active organizations appear before inactive organizations in search results' do
      result = Organization.search(current_user: agent, query: 'TestOrg')
      expect(result).to be_present
      expected_names = %w[TestOrg-Active-6 TestOrg-Active-4 TestOrg-Active-2 TestOrg-Inactive-5 TestOrg-Inactive-3 TestOrg-Inactive-1]
      actual_names = result.map(&:name)
      expect(actual_names).to match(expected_names)
    end
  end

  context 'with tickets' do
    before do
      agent
      tickets

      searchindex_model_reload([Ticket])
    end

    it 'ordering of tickets are not affected by the lack of active flags' do
      result = Ticket.search(current_user: agent, query: 'Ticket')
      expect(result).to be_present
      expected_titles = tickets.map(&:title)
      actual_titles = result.map(&:title).reverse
      expect(actual_titles).to match(expected_titles)
    end
  end
end
