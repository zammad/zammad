# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'CanSearch', searchindex: true, type: :model do
  let(:roles) { create_list(:role, 100) }

  before do
    roles
    searchindex_model_reload([Role])
  end

  def search(params)
    Role.search({ current_user: User.find(1), full: false, with_total_count: true }.merge(params))
  end

  it 'does search by query', :aggregate_failures do
    expected_result = 10
    params = { query: 'TestRole*', limit: 10, with_total_count: false, full: true }
    expect(search(params).count).to eq(expected_result)

    allow(SearchIndexBackend).to receive(:enabled?).and_return(false)
    expect(search(params).count).to eq(expected_result)
  end

  it 'does search by query not full', :aggregate_failures do
    expected_result = 10
    params = { query: 'TestRole*', limit: 10, with_total_count: false }
    expect(search(params).count).to eq(expected_result)

    allow(SearchIndexBackend).to receive(:enabled?).and_return(false)
    expect(search(params).count).to eq(expected_result)
  end

  it 'does search by query with total count', :aggregate_failures do
    expected_result = 100
    params = { query: 'TestRole*', limit: 10 }
    expect(search(params)[:object_ids].count).to eq(10)
    expect(search(params)[:total_count]).to eq(expected_result)

    allow(SearchIndexBackend).to receive(:enabled?).and_return(false)
    expect(search(params)[:object_ids].count).to eq(10)
    expect(search(params)[:total_count]).to eq(expected_result)
  end

  it 'does search by query only total count', :aggregate_failures do
    expected_result = 100
    params = { query: 'TestRole*', limit: 10, only_total_count: true }
    expect(search(params)[:total_count]).to eq(expected_result)

    allow(SearchIndexBackend).to receive(:enabled?).and_return(false)
    expect(search(params)[:total_count]).to eq(expected_result)
  end

  it 'does search by query and ids', :aggregate_failures do
    expected_result = roles[0..3].map(&:id)
    params = { query: 'TestRole*', limit: 10, ids: expected_result }
    expect(search(params)[:object_ids].sort.map(&:to_i)).to eq(expected_result)
    expect(search(params)[:total_count]).to eq(4)

    allow(SearchIndexBackend).to receive(:enabled?).and_return(false)
    expect(search(params)[:object_ids].sort.map(&:to_i)).to eq(expected_result)
    expect(search(params)[:total_count]).to eq(4)
  end

  it 'does search by query and ids and sorted', :aggregate_failures do
    expected_result = roles[0..3].map(&:id).reverse
    params = { query: 'TestRole*', limit: 10, ids: expected_result, sort_by: 'id', order_by: 'desc' }
    expect(search(params)[:object_ids].map(&:to_i)).to eq(expected_result)
    expect(search(params)[:total_count]).to eq(4)

    allow(SearchIndexBackend).to receive(:enabled?).and_return(false)
    expect(search(params)[:object_ids].map(&:to_i)).to eq(expected_result)
    expect(search(params)[:total_count]).to eq(4)
  end

  it 'does search by query and ids and sorted and offset', :aggregate_failures do
    ids = roles[0..3].map(&:id)
    params = { query: 'TestRole*', limit: 1, ids: ids, sort_by: 'id', order_by: 'asc' }
    expect(search(params)[:object_ids].map(&:to_i)).to eq([ids[0]])
    expect(search(params)[:total_count]).to eq(4)
    expect(search(params.merge(offset: 1))[:object_ids].map(&:to_i)).to eq([ids[1]])
    expect(search(params.merge(offset: 1))[:total_count]).to eq(4)
    expect(search(params.merge(offset: 2))[:object_ids].map(&:to_i)).to eq([ids[2]])
    expect(search(params.merge(offset: 2))[:total_count]).to eq(4)

    allow(SearchIndexBackend).to receive(:enabled?).and_return(false)
    expect(search(params)[:object_ids].map(&:to_i)).to eq([ids[0]])
    expect(search(params)[:total_count]).to eq(4)
    expect(search(params.merge(offset: 1))[:object_ids].map(&:to_i)).to eq([ids[1]])
    expect(search(params.merge(offset: 1))[:total_count]).to eq(4)
    expect(search(params.merge(offset: 2))[:object_ids].map(&:to_i)).to eq([ids[2]])
    expect(search(params.merge(offset: 2))[:total_count]).to eq(4)
  end

  it 'does search by query and condition and sorted and offset', :aggregate_failures do
    ids = roles[0..3].map(&:id)
    params = { query: 'TestRole*', limit: 1, condition: { 'role.id' => { 'operator' => 'is', 'value' => ids.map(&:to_s) } }, sort_by: 'id', order_by: 'asc' }
    expect(search(params)[:object_ids].map(&:to_i)).to eq([ids[0]])
    expect(search(params)[:total_count]).to eq(4)
    expect(search(params.merge(offset: 1))[:object_ids].map(&:to_i)).to eq([ids[1]])
    expect(search(params.merge(offset: 1))[:total_count]).to eq(4)
    expect(search(params.merge(offset: 2))[:object_ids].map(&:to_i)).to eq([ids[2]])
    expect(search(params.merge(offset: 2))[:total_count]).to eq(4)

    allow(SearchIndexBackend).to receive(:enabled?).and_return(false)
    expect(search(params)[:object_ids].map(&:to_i)).to eq([ids[0]])
    expect(search(params)[:total_count]).to eq(4)
    expect(search(params.merge(offset: 1))[:object_ids].map(&:to_i)).to eq([ids[1]])
    expect(search(params.merge(offset: 1))[:total_count]).to eq(4)
    expect(search(params.merge(offset: 2))[:object_ids].map(&:to_i)).to eq([ids[2]])
    expect(search(params.merge(offset: 2))[:total_count]).to eq(4)
  end
end
