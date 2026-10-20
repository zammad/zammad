# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ActiveRecord::Type::IndifferentJson do
  subject(:type) { described_class.new }

  describe '#deserialize' do
    it 'returns an indifferent hash for JSON' do
      expect(type.deserialize('{"filter":{"ticket.agent":true}}')[:filter]['ticket.agent']).to be(true)
    end

    it 'returns an indifferent hash for the YAML of the former store columns' do
      expect(type.deserialize({ 'filter' => { 'ticket.agent' => true } }.to_yaml)[:filter]['ticket.agent']).to be(true)
    end

    it 'returns an empty hash for nil' do
      expect(type.deserialize(nil)).to eq({})
    end
  end

  describe '#serialize' do
    it 'writes JSON' do
      expect(type.serialize({ filter: true })).to eq('{"filter":true}')
    end
  end
end
