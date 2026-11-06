# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe User, '.search', :aggregate_failures do
  let(:agent)   { create(:agent) }
  let!(:person) { create(:customer, firstname: 'Max', lastname: 'Huber', email: 'mh@example.test', login: 'mh', note: 'Reception contact') }

  def search(query, **)
    described_class.search(current_user: agent, query:, full: false, **).map(&:to_i)
  end

  it 'matches full names in either order without changing other text searches' do
    ['Max Huber', 'huber max', 'ax Hub', 'mh@example.test', 'Reception contact'].each do |query|
      expect(search(query)).to include(person.id), query
    end
  end

  it 'pages namesakes and counts the complete result' do
    namesake = create(:customer, firstname: 'Max', lastname: 'Huber')

    result = described_class.search(current_user: agent, query: 'Max Huber', full: false, with_total_count: true,
                                    sort_by: 'id', order_by: 'asc', limit: 1)

    expect(result).to eq(object_ids: [person.id], total_count: 2)
    expect(search('Max Huber', sort_by: 'id', order_by: 'asc', limit: 1, offset: 1)).to eq([namesake.id])
  end

  it 'keeps ID and role restrictions when matching a full name' do
    expect(search('Max Huber', ids: [agent.id])).to be_empty
    expect(search('Max Huber', role_ids: agent.role_ids)).to be_empty
    expect(described_class.search(current_user: person, query: 'Max Huber')).to be_nil
  end

  it 'treats SQL wildcard characters literally' do
    person.update!(firstname: 'Max%', lastname: 'Hu_er')

    expect(search('Max% Hu_er')).to eq([person.id])
    expect(search('Max_ Hu%er')).to be_empty
  end
end
