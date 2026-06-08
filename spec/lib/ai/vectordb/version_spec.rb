# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'elasticsearch'

RSpec.describe 'AI::VectorDB Version Check' do # rubocop:disable RSpec/DescribeClass
  subject(:instance) { AI::VectorDB.new }

  context 'when Elasticsearch version is within the supported range' do
    before do
      indices = instance_double(Elasticsearch::API::Indices::Actions, exists?: true)
      client = instance_double(Elasticsearch::Client, indices:, info: { 'version' => { 'number' => '8.12.0' } })
      allow(instance).to receive_messages(client: client)
    end

    it 'does not raise an error' do
      expect { instance.ping! }.not_to raise_error
    end
  end

  context 'when Elasticsearch version is below the minimum supported version' do
    before do
      indices = instance_double(Elasticsearch::API::Indices::Actions, exists?: true)
      client = instance_double(Elasticsearch::Client, indices: indices, info: { 'version' => { 'number' => '8.10.0' } })
      allow(instance).to receive_messages(client: client)
    end

    it 'raises an error' do
      expect { instance.ping! }.to raise_error(AI::VectorDB::Error, 'Incompatible Elasticsearch version')
    end
  end

  context 'when Elasticsearch version is above the maximum supported version' do
    before do
      indices = instance_double(Elasticsearch::API::Indices::Actions, exists?: true)
      client = instance_double(Elasticsearch::Client, indices:, info: { 'version' => { 'number' => '10.0.1' } })
      allow(instance).to receive_messages(client: client)
    end

    it 'raises an error' do
      expect { instance.ping! }.to raise_error(AI::VectorDB::Error, 'Incompatible Elasticsearch version')
    end
  end
end
